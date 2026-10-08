"""Arming: the camera only watches when it should.

Mode flags and the weekly schedule are pure maths (arming.py); the API
persists them and the pipeline gates on them. These tests pin down the
wrap-midnight day bookkeeping — "Monday night" runs into Tuesday morning.
"""
import asyncio
import os
from datetime import datetime, timedelta

import pytest

import api_routes
import arming
import settings as app_settings

ENV_KEYS = ("PETTRACK_ARMING_MODE", "PETTRACK_ARMING_SCHEDULE")

# A concrete Monday…-ish anchor; tests derive weekdays from it so they
# never depend on the calendar.
_DAY_ONE = datetime(2026, 10, 5)


def _day(offset: int, hour: int = 12, minute: int = 0) -> datetime:
    return (_DAY_ONE + timedelta(days=offset)).replace(
        hour=hour, minute=minute, second=0, microsecond=0
    )


@pytest.fixture(autouse=True)
def clean_env(client):
    """These tests read and write live env; keep them hermetic.

    Requesting `client` also gives conftest's lockout fixture a database
    before this file's pure tests run — it sorts first in the directory.
    """
    saved = {key: os.environ.pop(key, None) for key in ENV_KEYS}
    yield
    for key in ENV_KEYS:
        os.environ.pop(key, None)
    for key, value in saved.items():
        if value is not None:
            os.environ[key] = value


def _auth():
    from api_routes import SECRET_TOKEN
    return {"x-api-token": SECRET_TOKEN}


def _sound_events(client):
    events = client.get("/api/activity?limit=200", headers=_auth()).json()["events"]
    return [e for e in events if e["event_type"] == "sound_detected"]


# --- the schedule maths -----------------------------------------------------


def test_mode_flags_beat_the_schedule():
    now = _day(0)
    assert arming.is_armed(arming.ARMING_MODE_ON, [], now) is True
    assert arming.is_armed(arming.ARMING_MODE_OFF, [], now) is False
    assert arming.is_armed(arming.ARMING_MODE_SCHEDULE, [], now) is False


def test_a_weekly_window_arms_only_on_its_days():
    workday = _DAY_ONE.isoweekday()
    window = {"days": [workday], "from_min": 9 * 60, "to_min": 17 * 60}
    assert arming.is_armed(arming.ARMING_MODE_SCHEDULE, [window], _day(0, 12)) is True
    assert arming.is_armed(arming.ARMING_MODE_SCHEDULE, [window], _day(1, 12)) is False
    assert arming.is_armed(arming.ARMING_MODE_SCHEDULE, [window], _day(0, 8, 59)) is False


def test_window_edges_are_half_open():
    window = {"days": [_DAY_ONE.isoweekday()], "from_min": 9 * 60, "to_min": 17 * 60}
    assert arming.window_covers(window, _day(0, 9, 0)) is True
    assert arming.window_covers(window, _day(0, 16, 59)) is True
    assert arming.window_covers(window, _day(0, 17, 0)) is False


def test_an_empty_window_never_covers():
    window = {"days": [_DAY_ONE.isoweekday()], "from_min": 10 * 60, "to_min": 10 * 60}
    assert arming.window_covers(window, _day(0, 10, 0)) is False
    assert arming.window_covers(window, _day(0, 23, 0)) is False


def test_a_wrapping_window_belongs_to_its_start_day():
    # "That day's night": listed on day X, runs 22:00–06:00 into X+1.
    window = {"days": [_DAY_ONE.isoweekday()], "from_min": 22 * 60, "to_min": 6 * 60}
    assert arming.window_covers(window, _day(0, 23)) is True   # that evening
    assert arming.window_covers(window, _day(1, 2)) is True    # tail after midnight
    assert arming.window_covers(window, _day(0, 12)) is False  # that midday
    assert arming.window_covers(window, _day(1, 12)) is False  # next midday
    # Monday 02:00 is Sunday night, not Monday night.
    assert arming.window_covers(window, _day(0, 2)) is False


def test_consecutive_nights_share_their_tails():
    days = [_DAY_ONE.isoweekday(), (_DAY_ONE + timedelta(days=1)).isoweekday()]
    window = {"days": days, "from_min": 22 * 60, "to_min": 6 * 60}
    assert arming.window_covers(window, _day(1, 2)) is True    # first night's tail
    assert arming.window_covers(window, _day(2, 2)) is True    # second night's tail
    assert arming.window_covers(window, _day(2, 12)) is False


def test_any_window_can_arm():
    miss = {"days": [1], "from_min": 9 * 60, "to_min": 10 * 60}
    hit = {"days": [_DAY_ONE.isoweekday()], "from_min": 0, "to_min": 1439}
    now = _day(0, 23)
    assert arming.is_armed(arming.ARMING_MODE_SCHEDULE, [miss], now) is False
    assert arming.is_armed(arming.ARMING_MODE_SCHEDULE, [miss, hit], now) is True


# --- schedule normalization --------------------------------------------------


def test_normalize_drops_junk_and_cleans_days():
    windows = arming.normalize_schedule(
        [
            "junk",
            {"days": [], "from_min": 0, "to_min": 60},
            {"days": [0, 1, 1, 3.0, 9, True, "x"], "from_min": 60, "to_min": 120},
            {"days": [2], "from_min": -5, "to_min": 120},
            {"days": [2], "from_min": 60, "to_min": 1440},
            {"days": [2], "from_min": "noon", "to_min": 120},
            None,
        ]
    )
    assert windows == [{"days": [1, 3], "from_min": 60, "to_min": 120}]


def test_normalize_caps_the_schedule():
    windows = arming.normalize_schedule(
        [{"days": [1], "from_min": i, "to_min": i + 30} for i in range(20)]
    )
    assert len(windows) == arming.MAX_WINDOWS


def test_settings_layer_round_trip(client):
    assert app_settings.get_arming_mode() == "on"
    assert app_settings.get_arming_schedule() == []
    assert app_settings.is_armed_now() is True

    assert app_settings.set_arming_mode("off") == "off"
    assert app_settings.is_armed_now() is False

    clean = app_settings.set_arming_schedule(
        [{"days": [2, 1], "from_min": 540, "to_min": 1020}, "junk"]
    )
    assert clean == [{"days": [1, 2], "from_min": 540, "to_min": 1020}]
    assert app_settings.get_arming_schedule() == clean

    with pytest.raises(ValueError):
        app_settings.set_arming_mode("banana")

    # A garbage schedule on disk degrades to empty, not to a crash.
    os.environ["PETTRACK_ARMING_SCHEDULE"] = "{not json"
    assert app_settings.get_arming_schedule() == []
    # An unknown mode on disk degrades to the safe default.
    os.environ["PETTRACK_ARMING_MODE"] = "banana"
    assert app_settings.get_arming_mode() == "on"


# --- the API -----------------------------------------------------------------


def test_arming_round_trip(client):
    r = client.get("/api/arming", headers=_auth())
    assert r.status_code == 200
    assert r.json() == {"mode": "on", "schedule": [], "armed": True}

    window = {"days": [1, 2, 3, 4, 5], "from_min": 540, "to_min": 1020}
    r = client.post(
        "/api/arming",
        json={"mode": "schedule", "schedule": [window]},
        headers=_auth(),
    )
    assert r.status_code == 200
    body = r.json()
    assert body["mode"] == "schedule"
    assert body["schedule"] == [window]
    # Whether that window covers the wall clock is the maths tests' job.
    assert body["armed"] in (True, False)

    # Partial update: mode only, the schedule stays put.
    r = client.post("/api/arming", json={"mode": "off"}, headers=_auth())
    body = r.json()
    assert body["mode"] == "off"
    assert body["schedule"] == [window]
    assert body["armed"] is False

    # The status poll carries the summary the dashboard chip rides on.
    status = client.get("/api/status", headers=_auth()).json()["arming"]
    assert status == {"mode": "off", "armed": False}


def test_arming_rejects_a_bad_mode(client):
    r = client.post("/api/arming", json={"mode": "banana"}, headers=_auth())
    assert r.status_code == 400
    assert client.get("/api/arming", headers=_auth()).json()["mode"] == "on"


def test_arming_drops_junk_windows_without_failing(client):
    # Structurally wrong entries are a 422 (the model's job); windows with
    # no usable day are dropped by normalization instead of failing.
    good = {"days": [6], "from_min": 600, "to_min": 1200}
    r = client.post(
        "/api/arming",
        json={
            "schedule": [
                {"days": [], "from_min": 0, "to_min": 60},
                {"days": [0, 9], "from_min": 60, "to_min": 120},
                good,
            ]
        },
        headers=_auth(),
    )
    assert r.status_code == 200
    assert r.json()["schedule"] == [good]


def test_arming_needs_a_full_token(client):
    from auth import mint_access_token

    assert client.post("/api/arming", json={"mode": "off"}).status_code == 401

    # A monitor token must never be able to disarm the camera.
    monitor = {"x-api-token": mint_access_token("", scope="monitor")}
    r = client.post("/api/arming", json={"mode": "off"}, headers=monitor)
    assert r.status_code == 403
    assert client.get("/api/arming", headers=_auth()).json()["mode"] == "on"


# --- the gates ---------------------------------------------------------------


def test_disarmed_swallows_sound_events(client):
    api_routes._last_sound_event = 0.0
    client.post("/api/arming", json={"mode": "off"}, headers=_auth())
    try:
        before = len(_sound_events(client))
        r = client.post("/api/monitor/sound", json={"level": -6}, headers=_auth())
        assert r.status_code == 200
        assert r.json() == {"status": "ok", "logged": False}
        assert len(_sound_events(client)) == before
    finally:
        client.post("/api/arming", json={"mode": "on"}, headers=_auth())

    # The drop did not consume the burst cooldown: re-armed, the very
    # next sound logs immediately.
    r = client.post("/api/monitor/sound", json={"level": -6}, headers=_auth())
    assert r.json() == {"status": "ok", "logged": True}


def test_disarmed_frames_reset_the_motion_baseline(monkeypatch):
    import vision

    vision._prev_small = "sentinel"
    vision._last_zones = {"Kitchen"}
    vision._last_pet_center = (0.5, 0.5)
    monkeypatch.setenv("PETTRACK_ARMING_MODE", "off")
    asyncio.run(vision.process_and_save_frame(b"not a jpeg"))
    # Re-arming must start clean — no phantom zone events from stale state.
    assert vision._prev_small is None
    assert vision._last_zones == set()
    assert vision._last_pet_center is None


def test_armed_frames_reach_detection(monkeypatch):
    import vision

    vision._prev_small = "sentinel"
    monkeypatch.setenv("PETTRACK_ARMING_MODE", "on")
    asyncio.run(vision.process_and_save_frame(b"not a jpeg"))
    # Junk bytes fail to decode and return early — proof the disarmed test
    # above was the gate touching the baseline, not a decode accident.
    assert vision._prev_small == "sentinel"
