"""Activity insights: zone stays, daily activity buckets."""
import asyncio
import os
import time
from datetime import datetime

import api_routes
from api_routes import MAX_ZONE_STAY_SECONDS, zone_stays
from database import log_event


def _insights(client, token, days=14):
    resp = client.get(
        f"/api/insights?days={days}", headers={"x-api-token": token}
    )
    assert resp.status_code == 200
    return {d["date"]: d for d in resp.json()["days"]}, resp.json()


def _today():
    return datetime.now().strftime("%Y-%m-%d")


# --- zone_stays (pure logic) ----------------------------------------------

def test_zone_stays_pairs_enter_with_exit():
    t0 = 1_700_000_000.0
    events = [
        {"event_type": "zone_enter", "zone_name": "kitchen", "timestamp": t0},
        {"event_type": "zone_exit", "zone_name": "kitchen", "timestamp": t0 + 120},
    ]
    totals, per_day = zone_stays(events)
    assert totals == {"kitchen": 120}
    assert len(per_day) == 1
    assert list(per_day.values()) == [{"kitchen": 120}]


def test_zone_stays_drops_an_enter_with_no_exit():
    t0 = 1_700_000_000.0
    events = [
        {"event_type": "zone_enter", "zone_name": "garden", "timestamp": t0},
    ]
    totals, _ = zone_stays(events)
    assert totals == {}


def test_zone_stays_caps_a_lost_exit():
    t0 = 1_700_000_000.0
    events = [
        {"event_type": "zone_enter", "zone_name": "sofa", "timestamp": t0},
        {
            "event_type": "zone_exit",
            "zone_name": "sofa",
            "timestamp": t0 + MAX_ZONE_STAY_SECONDS * 3,
        },
    ]
    totals, _ = zone_stays(events)
    assert totals == {"sofa": MAX_ZONE_STAY_SECONDS}


def test_zone_stays_keeps_zones_apart():
    t0 = 1_700_000_000.0
    events = [
        {"event_type": "zone_enter", "zone_name": "a", "timestamp": t0},
        {"event_type": "zone_enter", "zone_name": "b", "timestamp": t0 + 10},
        {"event_type": "zone_exit", "zone_name": "a", "timestamp": t0 + 60},
        {"event_type": "zone_exit", "zone_name": "b", "timestamp": t0 + 100},
    ]
    totals, _ = zone_stays(events)
    assert totals == {"a": 60, "b": 90}


# --- /api/insights ----------------------------------------------------------

def test_insights_turns_clips_into_active_time(client):
    tok = client.post("/api/auth/login", json={"secret": api_routes.SECRET_TOKEN}).json()["token"]
    before, _ = _insights(client, tok, days=2)

    epoch = int(time.time())
    os.makedirs("replays", exist_ok=True)
    clip = f"replays/replay_{epoch}.mp4"
    with open(clip, "wb") as f:
        f.write(b"clip")
    try:
        after, body = _insights(client, tok, days=2)
        today = _today()
        assert after[today]["clips"] == before.get(today, {}).get("clips", 0) + 1
        assert (
            after[today]["active_seconds"]
            == before.get(today, {}).get("active_seconds", 0)
            + api_routes.MOTION_CLIP_SECONDS
        )
        assert body["totals"]["clips"] >= 1
    finally:
        os.remove(clip)


def test_insights_counts_sounds_on_the_right_day(client):
    tok = client.post("/api/auth/login", json={"secret": api_routes.SECRET_TOKEN}).json()["token"]
    before, _ = _insights(client, tok, days=2)

    asyncio.run(log_event("sound_detected", details="insights-test"))

    after, _ = _insights(client, tok, days=2)
    today = _today()
    assert after[today]["sounds"] == before.get(today, {}).get("sounds", 0) + 1
    assert after[today]["events"] >= after[today]["sounds"]
