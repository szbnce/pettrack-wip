"""Integration tests for vision.process_and_save_frame with synthetic frames."""
import asyncio
import importlib
import io
import os

import numpy as np
from PIL import Image


def _jpeg(arr: np.ndarray) -> bytes:
    buf = io.BytesIO()
    Image.fromarray(arr, mode="L").save(buf, format="JPEG", quality=90)
    return buf.getvalue()


def _frame(value: int = 100, rows: int = 240, cols: int = 320) -> np.ndarray:
    return np.full((rows, cols), value, dtype=np.uint8)


def _with_square(base: np.ndarray, x0: int, y0: int, x1: int, y1: int) -> np.ndarray:
    f = base.copy()
    f[y0:y1, x0:x1] = 220
    return f


def _load_vision(tmp_path, monkeypatch):
    """Import vision with cwd in tmp so its mkdir calls stay out of the repo."""
    monkeypatch.chdir(tmp_path)
    import api_routes
    import vision

    importlib.reload(vision)
    api_routes.active_zones.clear()
    return api_routes, vision


def test_moving_blob_enters_zone_records_and_snapshots(tmp_path, monkeypatch):
    api_routes, vision = _load_vision(tmp_path, monkeypatch)

    # Right half of the frame is "zone_a" (polygons are normalized 0..1).
    api_routes.active_zones["zone_a"] = [
        {"x": 0.5, "y": 0.0},
        {"x": 1.0, "y": 0.0},
        {"x": 1.0, "y": 1.0},
        {"x": 0.5, "y": 1.0},
    ]

    events = []

    async def fake_log_event(kind, zone_name=None):
        events.append((kind, zone_name))

    monkeypatch.setattr(vision, "log_event", fake_log_event)

    base = _frame(100)
    # Static frame: nothing happens.
    asyncio.run(vision.process_and_save_frame(_jpeg(base)))
    assert events == []

    # Bright square appears inside zone_a -> enter event + snapshot.
    asyncio.run(vision.process_and_save_frame(_jpeg(_with_square(base, 220, 100, 280, 160))))
    assert events == [("zone_enter", "zone_a")]
    assert any(p.startswith("frame_") for p in os.listdir("captured_images"))


def test_moving_blob_leaves_zone_logs_exit(tmp_path, monkeypatch):
    api_routes, vision = _load_vision(tmp_path, monkeypatch)

    api_routes.active_zones["zone_a"] = [
        {"x": 0.5, "y": 0.0},
        {"x": 1.0, "y": 0.0},
        {"x": 1.0, "y": 1.0},
        {"x": 0.5, "y": 1.0},
    ]

    events = []

    async def fake_log_event(kind, zone_name=None):
        events.append((kind, zone_name))

    monkeypatch.setattr(vision, "log_event", fake_log_event)

    base = _frame(100)
    asyncio.run(vision.process_and_save_frame(_jpeg(base)))
    asyncio.run(vision.process_and_save_frame(_jpeg(_with_square(base, 220, 100, 280, 160))))
    # Blob walks over to the left half (outside zone_a) -> exit event.
    asyncio.run(vision.process_and_save_frame(_jpeg(_with_square(base, 40, 100, 100, 160))))

    assert events == [("zone_enter", "zone_a"), ("zone_exit", "zone_a")]


def test_static_scene_produces_no_events(tmp_path, monkeypatch):
    api_routes, vision = _load_vision(tmp_path, monkeypatch)

    api_routes.active_zones["zone_a"] = [
        {"x": 0.0, "y": 0.0},
        {"x": 1.0, "y": 0.0},
        {"x": 1.0, "y": 1.0},
        {"x": 0.0, "y": 1.0},
    ]

    events = []

    async def fake_log_event(kind, zone_name=None):
        events.append((kind, zone_name))

    monkeypatch.setattr(vision, "log_event", fake_log_event)

    base = _frame(100)
    for _ in range(5):
        asyncio.run(vision.process_and_save_frame(_jpeg(base)))
    assert events == []


def test_lighting_change_is_not_motion(tmp_path, monkeypatch):
    api_routes, vision = _load_vision(tmp_path, monkeypatch)

    api_routes.active_zones["zone_a"] = [
        {"x": 0.0, "y": 0.0},
        {"x": 1.0, "y": 0.0},
        {"x": 1.0, "y": 1.0},
        {"x": 0.0, "y": 1.0},
    ]

    events = []

    async def fake_log_event(kind, zone_name=None):
        events.append((kind, zone_name))

    monkeypatch.setattr(vision, "log_event", fake_log_event)

    asyncio.run(vision.process_and_save_frame(_jpeg(_frame(80))))
    asyncio.run(vision.process_and_save_frame(_jpeg(_frame(140))))  # lights on
    assert events == []
