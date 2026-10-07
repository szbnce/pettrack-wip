"""Replay timeline: the day strip's per-day event and clip counts."""
import asyncio
import os
import time
from datetime import datetime

import api_routes
from database import log_event


def _timeline(client, token, days=14):
    resp = client.get(
        f"/api/timeline?days={days}", headers={"x-api-token": token}
    )
    assert resp.status_code == 200
    return {d["date"]: d for d in resp.json()["days"]}


def _today():
    return datetime.now().strftime("%Y-%m-%d")


def test_timeline_buckets_events_by_day(client):
    tok = api_routes.mint_token()
    before = _timeline(client, tok, days=2).get(_today(), {}).get("events", {})

    asyncio.run(log_event("sound_detected", details="timeline-test"))

    after = _timeline(client, tok, days=2).get(_today(), {}).get("events", {})
    assert after.get("sound_detected", 0) == before.get("sound_detected", 0) + 1


def test_timeline_counts_motion_clips_per_day(client):
    tok = api_routes.mint_token()
    before = _timeline(client, tok, days=2).get(_today(), {}).get("clips", 0)

    epoch = int(time.time())
    os.makedirs("replays", exist_ok=True)
    clip = f"replays/replay_{epoch}.mp4"
    raw = f"replays/replay_{epoch}_raw.mp4"
    with open(clip, "wb") as f:
        f.write(b"clip")
    with open(raw, "wb") as f:
        f.write(b"raw")  # the in-progress twin must not be counted
    try:
        after = _timeline(client, tok, days=2).get(_today(), {}).get("clips", 0)
        assert after == before + 1
    finally:
        os.remove(clip)
        os.remove(raw)


def test_timeline_leaves_out_days_outside_the_window(client):
    tok = api_routes.mint_token()
    old_ts = int(time.time()) - 40 * 86400
    old_day = datetime.fromtimestamp(old_ts).strftime("%Y-%m-%d")
    os.makedirs("replays", exist_ok=True)
    clip = f"replays/replay_{old_ts}.mp4"
    with open(clip, "wb") as f:
        f.write(b"old")
    os.utime(clip, (old_ts, old_ts))
    try:
        days = _timeline(client, tok, days=14)
        assert old_day not in days
    finally:
        os.remove(clip)


def test_timeline_reports_event_types_separately(client):
    tok = api_routes.mint_token()
    asyncio.run(log_event("zone_enter", zone_name="timeline-zone"))

    today = _timeline(client, tok, days=2).get(_today(), {})
    assert today.get("events", {}).get("zone_enter", 0) >= 1
    assert today.get("total", 0) >= today.get("events", {}).get("zone_enter", 0)
