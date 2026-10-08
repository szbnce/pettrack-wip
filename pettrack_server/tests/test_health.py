"""Health & watchdog: offline alerts, disk pressure, pruning, retention."""
import os
import time

import api_routes
import health
import settings as app_settings


# --- camera watchdog (pure logic) -------------------------------------------

def test_a_fresh_camera_is_not_an_alert():
    now = time.time()
    entry = {"frame_count": 10, "last_seen": now - 60}
    assert not health.camera_is_alertable(entry, now)


def test_ten_minutes_of_silence_is_an_alert():
    now = time.time()
    entry = {
        "frame_count": 10,
        "last_seen": now - health.CAMERA_OFFLINE_ALERT_SECONDS,
    }
    assert health.camera_is_alertable(entry, now)


def test_a_camera_that_never_streamed_cannot_alert():
    entry = {"frame_count": 0, "last_seen": 0.0}
    assert not health.camera_is_alertable(entry, time.time() + 9999)


def test_offline_cameras_lists_the_quiet_ones_sorted():
    now = time.time()
    registry = {
        "b": {"frame_count": 3, "last_seen": now - 3600},
        "a": {"frame_count": 3, "last_seen": now},
        "c": {"frame_count": 0, "last_seen": now - 3600},
    }
    assert health.offline_cameras(registry, now) == ["b"]


# --- replay pruning ---------------------------------------------------------

def test_prune_replays_drops_clips_past_the_retention(client):
    folder = "replays_retention"
    os.makedirs(folder, exist_ok=True)
    old = f"{folder}/replay_1000.mp4"
    fresh = f"{folder}/replay_2000.mp4"
    with open(old, "wb") as f:
        f.write(b"x" * 10)
    with open(fresh, "wb") as f:
        f.write(b"y" * 10)
    month_ago = time.time() - 30 * 86400
    os.utime(old, (month_ago, month_ago))
    try:
        result = health.prune_replays(folder=folder, retention_days=7)
        assert result["deleted"] == 1
        assert not os.path.exists(old)
        assert os.path.exists(fresh)
    finally:
        for path in (old, fresh):
            if os.path.exists(path):
                os.remove(path)


def test_prune_replays_keeps_the_raw_twin_that_is_still_warm(client):
    folder = "replays_warm_raw"
    os.makedirs(folder, exist_ok=True)
    raw = f"{folder}/replay_3000_raw.mp4"
    with open(raw, "wb") as f:
        f.write(b"z")
    try:
        result = health.prune_replays(folder=folder, retention_days=7)
        assert result["deleted"] == 0
        assert os.path.exists(raw)
    finally:
        os.remove(raw)


def test_prune_replays_drops_a_stale_raw_left_by_a_crash(client):
    folder = "replays_stale_raw"
    os.makedirs(folder, exist_ok=True)
    raw = f"{folder}/replay_4000_raw.mp4"
    with open(raw, "wb") as f:
        f.write(b"z")
    stale = time.time() - 2 * health.STALE_RAW_SECONDS
    os.utime(raw, (stale, stale))
    try:
        result = health.prune_replays(folder=folder, retention_days=30)
        assert result["deleted"] == 1
        assert not os.path.exists(raw)
    finally:
        if os.path.exists(raw):
            os.remove(raw)


def test_prune_replays_clears_room_under_disk_pressure(client):
    folder = "replays_pressure"
    os.makedirs(folder, exist_ok=True)
    older = f"{folder}/replay_100.mp4"
    newer = f"{folder}/replay_200.mp4"
    for path, content in ((older, b"a" * 10), (newer, b"b" * 10)):
        with open(path, "wb") as f:
            f.write(content)
    past = time.time() - 3600
    os.utime(older, (past - 60, past - 60))
    os.utime(newer, (past, past))
    try:
        # A min_free_bytes larger than the disk forces the emergency path.
        result = health.prune_replays(
            folder=folder, retention_days=30, min_free_bytes=10**18
        )
        assert result["deleted"] == 2
        assert not os.path.exists(older)
        assert not os.path.exists(newer)
    finally:
        for path in (older, newer):
            if os.path.exists(path):
                os.remove(path)


# --- /api/system-health and /api/settings ------------------------------------------

def test_health_reports_camera_disk_and_replays(client):
    tok = client.post("/api/auth/login", json={"secret": api_routes.SECRET_TOKEN}).json()["token"]
    api_routes.touch_monitor("cam-health", frame_count=5)
    try:
        resp = client.get("/api/system-health", headers={"x-api-token": tok})
        assert resp.status_code == 200
        body = resp.json()
        assert body["camera_online"] is True
        assert "camera_offline" not in body["alerts"]
        assert body["disk"]["total_bytes"] > 0
        assert body["replays"]["retention_days"] == (
            app_settings.get_replay_retention_days()
        )
        assert any(m["id"] == "cam-health" for m in body["monitors"])
    finally:
        api_routes.monitor_registry.pop("cam-health", None)
        api_routes._mirror_active_monitor()


def test_health_flags_a_camera_that_went_quiet(client):
    tok = client.post("/api/auth/login", json={"secret": api_routes.SECRET_TOKEN}).json()["token"]
    entry = api_routes._ensure_monitor("cam-quiet")
    entry["frame_count"] = 3
    entry["last_seen"] = time.time() - health.CAMERA_OFFLINE_ALERT_SECONDS
    entry["online"] = True
    try:
        resp = client.get("/api/system-health", headers={"x-api-token": tok})
        assert resp.status_code == 200
        assert "camera_offline" in resp.json()["alerts"]
    finally:
        api_routes.monitor_registry.pop("cam-quiet", None)
        api_routes._mirror_active_monitor()


def test_settings_round_trip(client):
    tok = client.post("/api/auth/login", json={"secret": api_routes.SECRET_TOKEN}).json()["token"]
    headers = {"x-api-token": tok}
    before = client.get("/api/settings", headers=headers).json()
    try:
        resp = client.post(
            "/api/settings",
            json={"replay_retention_days": 30},
            headers=headers,
        )
        assert resp.status_code == 200
        assert resp.json()["replay_retention_days"] == 30
        after = client.get("/api/settings", headers=headers).json()
        assert after["replay_retention_days"] == 30
        # The remote-alert knobs ride along in the same document.
        assert after["ntfy_url"] == app_settings.get_ntfy_url()
        assert after["quiet_hours_from"] == app_settings.get_quiet_hours()[1]
    finally:
        client.post(
            "/api/settings",
            json={"replay_retention_days": before["replay_retention_days"]},
            headers=headers,
        )


def test_settings_rejects_impossible_retention(client):
    tok = client.post("/api/auth/login", json={"secret": api_routes.SECRET_TOKEN}).json()["token"]
    resp = client.post(
        "/api/settings",
        json={"replay_retention_days": 0},
        headers={"x-api-token": tok},
    )
    assert resp.status_code == 422
