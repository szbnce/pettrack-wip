"""Multi-camera registry: per-monitor frames, status list, viewer routing."""
import time

import pytest

import api_routes


JPEG = b"\xff\xd8\xff\xe0" + b"fake-jpeg"


@pytest.fixture(autouse=True)
def _isolated_registry():
    """These tests own the module-level registry; leave it as they found it."""
    saved_reg = dict(api_routes.monitor_registry)
    saved_frames = dict(api_routes.monitor_frames)
    saved_frame = dict(api_routes.latest_frame_info)
    saved_state = dict(api_routes.monitor_state)
    yield
    api_routes.monitor_registry.clear()
    api_routes.monitor_registry.update(saved_reg)
    api_routes.monitor_frames.clear()
    api_routes.monitor_frames.update(saved_frames)
    api_routes.latest_frame_info.clear()
    api_routes.latest_frame_info.update(saved_frame)
    api_routes.monitor_state.clear()
    api_routes.monitor_state.update(saved_state)


def _reset(monitors=()):
    api_routes.monitor_registry.clear()
    api_routes.monitor_frames.clear()
    api_routes.latest_frame_info["data"] = None
    api_routes.latest_frame_info["timestamp"] = 0.0
    for mid in monitors:
        api_routes.touch_monitor(mid)


def _monitors(client, token):
    resp = client.get("/api/monitors", headers={"x-api-token": token})
    assert resp.status_code == 200
    return {m["id"]: m for m in resp.json()}


def test_monitors_endpoint_lists_each_camera(client):
    _reset()
    tok = api_routes.mint_token()
    client.post(
        "/api/frame/web?token=" + tok + "&monitor_id=cam_a", content=JPEG
    )
    client.post(
        "/api/frame/web?token=" + tok + "&monitor_id=cam_b", content=JPEG
    )

    monitors = _monitors(client, tok)
    assert set(monitors) == {"cam_a", "cam_b"}
    assert all(m["online"] for m in monitors.values())
    assert all(m["frame_count"] == 1 for m in monitors.values())


def test_each_camera_keeps_its_own_frame(client):
    _reset()
    tok = api_routes.mint_token()
    frame_a = b"\xff\xd8" + b"A" * 16
    frame_b = b"\xff\xd8" + b"B" * 16
    client.post("/api/frame/web?token=" + tok + "&monitor_id=cam_a", content=frame_a)
    client.post("/api/frame/web?token=" + tok + "&monitor_id=cam_b", content=frame_b)

    got_a = client.get("/api/monitors/cam_a/frame", headers={"x-api-token": tok})
    got_b = client.get("/api/monitors/cam_b/frame", headers={"x-api-token": tok})
    assert got_a.content == frame_a
    assert got_b.content == frame_b


def test_unknown_camera_frame_is_404(client):
    _reset()
    tok = api_routes.mint_token()
    resp = client.get("/api/monitors/nobody/frame", headers={"x-api-token": tok})
    assert resp.status_code == 404


def test_status_mirrors_the_freshest_camera(client):
    _reset()
    tok = api_routes.mint_token()
    client.post(
        "/api/monitor/update",
        json={"battery_level": 80, "is_charging": False, "monitor_id": "cam_a"},
        headers={"x-api-token": tok},
    )
    # cam_b reports later -> it becomes the "active" camera of /api/status.
    client.post(
        "/api/monitor/update",
        json={"battery_level": 40, "is_charging": True, "monitor_id": "cam_b"},
        headers={"x-api-token": tok},
    )

    status = client.get("/api/status", headers={"x-api-token": tok}).json()
    assert status["monitor_id"] == "cam_b"
    assert status["battery_level"] == 40
    assert status["is_charging"] is True

    monitors = _monitors(client, tok)
    assert monitors["cam_a"]["battery_level"] == 80
    assert monitors["cam_b"]["battery_level"] == 40


def test_battery_reports_land_on_the_right_camera(client):
    _reset()
    tok = api_routes.mint_token()
    client.post(
        "/api/monitor/update",
        json={"battery_level": 12, "is_charging": True, "monitor_id": "cam_a"},
        headers={"x-api-token": tok},
    )
    monitors = _monitors(client, tok)
    assert monitors["cam_a"]["battery_level"] == 12
    assert monitors["cam_a"]["is_charging"] is True


def test_offline_camera_is_flagged_after_timeout(client):
    _reset()
    tok = api_routes.mint_token()
    api_routes.touch_monitor("cam_a")
    api_routes.monitor_registry["cam_a"]["last_seen"] = time.time() - 60

    monitors = _monitors(client, tok)
    assert monitors["cam_a"]["online"] is False
