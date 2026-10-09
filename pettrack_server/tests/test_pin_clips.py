"""Pinned clips: the ones retention must never eat."""
import os
import time

import pytest
from fastapi import HTTPException

import api_routes
import health
import pins
import settings as app_settings


def _login(client):
    return client.post(
        "/api/auth/login", json={"secret": api_routes.SECRET_TOKEN}
    ).json()["token"]


def _age(path, days):
    old = time.time() - days * 86400
    os.utime(path, (old, old))


# --- the pin list (pure) ----------------------------------------------------


def test_pin_and_unpin_round_trip(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    os.makedirs("replays")

    pins.pin("clip.mp4")
    assert pins.is_pinned("clip.mp4")
    assert "clip.mp4" in pins.load_pins()

    pins.unpin("clip.mp4")
    assert not pins.is_pinned("clip.mp4")


def test_a_missing_or_corrupt_pin_list_is_simply_empty(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    os.makedirs("replays")
    assert pins.load_pins() == set()

    with open(pins._path(), "w") as f:
        f.write("{not json")
    assert pins.load_pins() == set()

    with open(pins._path(), "w") as f:
        f.write('{"nope": true}')
    assert pins.load_pins() == set()


def test_the_pin_list_travels_with_the_footage_folder(tmp_path, monkeypatch):
    """The list is `<folder>/.pinned.json` — move the folder, keep the pins."""
    monkeypatch.chdir(tmp_path)
    os.makedirs("clips_a")
    pins.pin("keep.mp4", folder="clips_a")

    os.rename("clips_a", "clips_b")
    assert pins.load_pins(folder="clips_b") == {"keep.mp4"}
    assert pins.load_pins(folder="clips_a") == set()


# --- the sweep honours them -------------------------------------------------


def test_a_pinned_clip_outlives_the_retention_window(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(app_settings, "get_replay_retention_days", lambda: 1)
    os.makedirs("replays")
    old = "replays/old.mp4"
    kept = "replays/kept.mp4"
    for p in (old, kept):
        with open(p, "wb") as f:
            f.write(b"x" * 8)
        _age(p, 10)
    pins.pin("kept.mp4")

    result = health.prune_replays()

    assert not os.path.exists(old)
    assert os.path.exists(kept)
    assert result["deleted"] == 1


def test_disk_pressure_skips_pinned_clips(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(app_settings, "get_replay_retention_days", lambda: 365)
    os.makedirs("replays")
    pinned_old = "replays/pinned_old.mp4"
    free_old = "replays/free_old.mp4"
    for p, age in ((pinned_old, 30), (free_old, 20)):
        with open(p, "wb") as f:
            f.write(b"x" * 8)
        _age(p, age)
    pins.pin("pinned_old.mp4")

    # Pretend the disk is empty so pressure would drop the oldest first.
    monkeypatch.setattr(
        health.shutil, "disk_usage", lambda _p: type("U", (), {"free": 0})()
    )

    result = health.prune_replays(min_free_bytes=1)

    assert os.path.exists(pinned_old)  # the pin wins over pressure
    assert not os.path.exists(free_old)
    assert result["deleted"] == 1


def test_pin_count_lands_in_replay_stats(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    os.makedirs("replays")
    with open("replays/a.mp4", "wb") as f:
        f.write(b"x")
    pins.pin("a.mp4")
    stats = health.replay_stats()
    assert stats["count"] == 1
    assert stats["pinned"] == 1


# --- the endpoints ----------------------------------------------------------


def test_pin_needs_a_session(client):
    assert client.post("/api/replays/a.mp4/pin").status_code == 401


def test_pin_of_a_missing_clip_is_404(client):
    token = _login(client)
    resp = client.post(
        "/api/replays/nope.mp4/pin", headers={"x-api-token": token}
    )
    assert resp.status_code == 404


def test_pin_shows_up_in_the_list_and_unpin_clears_it(client):
    token = _login(client)
    os.makedirs("replays", exist_ok=True)
    with open("replays/replay_pin.mp4", "wb") as f:
        f.write(b"bytes")

    resp = client.post(
        "/api/replays/replay_pin.mp4/pin", headers={"x-api-token": token}
    )
    assert resp.status_code == 200
    assert resp.json() == {"filename": "replay_pin.mp4", "pinned": True}

    listing = client.get("/api/replays", headers={"x-api-token": token}).json()[
        "replays"
    ]
    mine = [r for r in listing if r["filename"] == "replay_pin.mp4"]
    assert mine and mine[0]["pinned"] is True

    resp = client.post(
        "/api/replays/replay_pin.mp4/unpin", headers={"x-api-token": token}
    )
    assert resp.json()["pinned"] is False
    listing = client.get("/api/replays", headers={"x-api-token": token}).json()[
        "replays"
    ]
    mine = [r for r in listing if r["filename"] == "replay_pin.mp4"]
    assert mine and mine[0]["pinned"] is False


def test_cannot_pin_your_way_out_of_the_folder(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    os.makedirs("replays")
    outside = tmp_path / "outside.mp4"
    outside.write_bytes(b"x")

    # basename() flattens the climb — only something inside replays/ pins.
    with pytest.raises(HTTPException) as exc:
        api_routes._existing_replay("../outside.mp4")
    assert exc.value.status_code == 404
    assert outside.exists()
