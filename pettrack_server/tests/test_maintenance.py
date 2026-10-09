"""One-shot storage maintenance: the sweep behind "free up space now"."""
import os
import time

import api_routes
import maintenance
import settings as app_settings
import timelapse


def _login(client):
    return client.post(
        "/api/auth/login", json={"secret": api_routes.SECRET_TOKEN}
    ).json()["token"]


def _age(path, days):
    """Make a file look [days] old — mtime is what every cutoff reads."""
    old = time.time() - days * 86400
    os.utime(path, (old, old))


# --- the sweep (pure) -------------------------------------------------------


def test_old_snapshots_go_and_fresh_ones_stay(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    os.makedirs("captured_images")
    old = "captured_images/old.jpg"
    fresh = "captured_images/fresh.jpg"
    for p in (old, fresh):
        with open(p, "wb") as f:
            f.write(b"x" * 8)
    _age(old, 1)  # past the 12-hour window

    stats = maintenance.run_cleanup_once()

    assert not os.path.exists(old)
    assert os.path.exists(fresh)
    assert stats["images_deleted"] == 1
    assert stats["images_freed_bytes"] == 8


def test_the_snapshot_cap_keeps_only_the_newest(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    os.makedirs("captured_images")
    now = time.time()
    for i in range(502):
        p = f"captured_images/s{i:03d}.jpg"
        with open(p, "wb") as f:
            f.write(b"x")
        # The first two are fresh but the oldest — the cap drops them.
        mtime = now - 300 + i if i < 2 else now
        os.utime(p, (mtime, mtime))

    stats = maintenance.run_cleanup_once()

    assert stats["images_deleted"] == 2
    assert not os.path.exists("captured_images/s000.jpg")
    assert not os.path.exists("captured_images/s001.jpg")
    assert os.path.exists("captured_images/s002.jpg")


def test_timelapse_stills_past_retention_go(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    os.makedirs(timelapse.DEFAULT_FOLDER)
    old = f"{timelapse.DEFAULT_FOLDER}/{timelapse.FRAME_PREFIX}1.jpg"
    fresh = f"{timelapse.DEFAULT_FOLDER}/{timelapse.FRAME_PREFIX}2.jpg"
    not_a_still = f"{timelapse.DEFAULT_FOLDER}/other.jpg"
    for p in (old, fresh, not_a_still):
        with open(p, "wb") as f:
            f.write(b"x" * 4)
    _age(old, timelapse.RETENTION_DAYS + 1)

    stats = maintenance.run_cleanup_once()

    assert not os.path.exists(old)
    assert os.path.exists(fresh)
    assert os.path.exists(not_a_still)  # not a frame still — never touched
    assert stats["timelapse_deleted"] == 1
    assert stats["timelapse_freed_bytes"] == 4


def test_replays_follow_the_retention_window(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(app_settings, "get_replay_retention_days", lambda: 1)
    os.makedirs("replays")
    old = "replays/replay_1.mp4"
    fresh = "replays/replay_2.mp4"
    for p in (old, fresh):
        with open(p, "wb") as f:
            f.write(b"x" * 16)
    _age(old, 3)

    stats = maintenance.run_cleanup_once()

    assert not os.path.exists(old)
    assert os.path.exists(fresh)
    assert stats["replays_deleted"] == 1
    assert stats["replays_freed_bytes"] == 16


def test_a_broken_sweep_never_stops_the_rest(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    os.makedirs("captured_images")
    os.makedirs(timelapse.DEFAULT_FOLDER)
    old = "captured_images/old.jpg"
    with open(old, "wb") as f:
        f.write(b"x" * 8)
    _age(old, 1)
    # An unreadable timelapse folder: that sweep must fail without taking
    # the images and replays sweeps down with it.
    real_listdir = os.listdir

    def listdir(path):
        if path == timelapse.DEFAULT_FOLDER:
            raise OSError("unreadable")
        return real_listdir(path)

    monkeypatch.setattr(maintenance.os, "listdir", listdir)

    stats = maintenance.run_cleanup_once()

    assert stats["images_deleted"] == 1
    assert not os.path.exists(old)


# --- the endpoint -----------------------------------------------------------


def test_cleanup_endpoint_needs_a_token(client):
    assert client.post("/api/maintenance/cleanup").status_code == 401


def test_cleanup_endpoint_frees_space_and_reports_it(client):
    token = _login(client)
    os.makedirs("captured_images", exist_ok=True)
    p = "captured_images/old.jpg"
    with open(p, "wb") as f:
        f.write(b"x" * 8)
    _age(p, 1)

    resp = client.post(
        "/api/maintenance/cleanup", headers={"x-api-token": token}
    )

    assert resp.status_code == 200
    body = resp.json()
    assert body["images_deleted"] == 1
    assert body["images_freed_bytes"] == 8
    # Enough for the health card to refresh from the answer alone.
    assert "free_bytes" in body["disk"]
    assert "retention_days" in body["replays"]
