"""Day timelapse: sampling the stream and stitching stills."""
import os
import shutil
import time
from datetime import date, timedelta

import pytest

cv2 = pytest.importorskip("cv2")
np = pytest.importorskip("numpy")

import timelapse
from timelapse import build_timelapse, frames_for_day, maybe_sample

needs_ffmpeg = pytest.mark.skipif(
    shutil.which("ffmpeg") is None, reason="ffmpeg not installed"
)

JPEG = b"\xff\xd8\xff\xe0fakejpegdata"


def _write_jpeg(path, value=128, size=(64, 48)):
    frame = np.full((size[1], size[0], 3), value, dtype=np.uint8)
    assert cv2.imwrite(str(path), frame)


def _touch(path, when: date):
    """Give a file an mtime inside `when` (noon local time)."""
    ts = time.mktime((when.year, when.month, when.day, 12, 0, 0, 0, 0, -1))
    os.utime(path, (ts, ts))


@pytest.fixture(autouse=True)
def _reset_sampler():
    timelapse._last_sample = 0.0
    yield
    timelapse._last_sample = 0.0


def test_sampler_writes_one_still_per_interval(tmp_path, monkeypatch):
    monkeypatch.setattr(timelapse, "INTERVAL", 60.0)
    folder = str(tmp_path)
    assert maybe_sample(JPEG, folder=folder) is True
    assert maybe_sample(JPEG, folder=folder) is False  # too soon
    # Backdate: the next frame is accepted again.
    timelapse._last_sample -= 61
    assert maybe_sample(JPEG, folder=folder) is True
    names = os.listdir(folder)
    assert len(names) == 2
    assert all(n.startswith("frame_") and n.endswith(".jpg") for n in names)


def test_sampler_ignores_non_jpeg_and_disabled_mode(tmp_path, monkeypatch):
    folder = str(tmp_path)
    monkeypatch.setattr(timelapse, "INTERVAL", 60.0)
    assert maybe_sample(b"\x89PNGnotajpeg", folder=folder) is False
    assert maybe_sample(b"", folder=folder) is False
    monkeypatch.setattr(timelapse, "INTERVAL", 0.0)  # off
    assert maybe_sample(JPEG, folder=folder) is False
    assert os.listdir(folder) == []


def test_frames_for_day_filters_by_day_and_kind(tmp_path):
    day = date.today()
    other = day - timedelta(days=2)
    keep = tmp_path / "frame_200.jpg"
    late = tmp_path / "frame_100.jpg"
    stale = tmp_path / "frame_300.jpg"
    note = tmp_path / "notes.txt"
    for p in (keep, late, stale, note):
        p.write_bytes(b"x")
    _touch(keep, day)
    _touch(late, day)
    _touch(stale, other)

    frames = frames_for_day(day, str(tmp_path))
    # Sorted oldest first by mtime; the two same-day stills tie at noon, so
    # just require both and neither of the others.
    assert sorted(frames) == sorted([str(late), str(keep)])
    assert str(stale) not in frames


@needs_ffmpeg
def test_builds_timelapse_from_the_days_stills(tmp_path):
    day = date.today() - timedelta(days=5)
    for i in range(3):
        p = tmp_path / f"frame_{i:04d}.jpg"
        _write_jpeg(p, value=40 + i * 20)
        _touch(p, day)

    result = build_timelapse(day, folder=str(tmp_path))
    assert result is not None
    assert result["date"] == day.isoformat()
    assert result["frame_count"] == 3
    assert result["filename"] == f"timelapse_{day.isoformat()}.mp4"
    assert os.path.exists(result["path"])
    assert os.path.getsize(result["path"]) > 0


def test_build_returns_none_for_thin_days(tmp_path):
    day = date.today() - timedelta(days=4)
    p = tmp_path / "frame_1.jpg"
    _write_jpeg(p)
    _touch(p, day)
    assert build_timelapse(day, folder=str(tmp_path)) is None
    # ...and for days with nothing at all.
    assert build_timelapse(day - timedelta(days=10), folder=str(tmp_path)) is None


@needs_ffmpeg
def test_timelapse_endpoint_cache_and_listing(client):
    # The client fixture chdirs into its own temp dir; work there so the
    # routes' relative "timelapse" folder is ours.
    day = date.today() - timedelta(days=2)
    os.makedirs("timelapse", exist_ok=True)
    for i in range(2):
        p = f"timelapse/frame_{i}.jpg"
        _write_jpeg(p, value=60 + i * 40)
        _touch(p, day)

    res = client.get(
        f"/api/timelapse?date={day.isoformat()}",
        headers={"x-api-token": os.environ["PETTRACK_SECRET"]},
    )
    assert res.status_code == 200
    body = res.json()
    assert body["frame_count"] == 2
    assert body["filename"] == f"timelapse_{day.isoformat()}.mp4"
    assert body["url"].startswith("/api/replays/timelapse_")

    # Cached: the second call reuses the clip instead of rebuilding.
    again = client.get(
        f"/api/timelapse?date={day.isoformat()}",
        headers={"x-api-token": os.environ["PETTRACK_SECRET"]},
    ).json()
    assert again["filename"] == body["filename"]

    # The timelapse must not show up in the event replay list.
    res = client.get(
        "/api/replays",
        headers={"x-api-token": os.environ["PETTRACK_SECRET"]},
    )
    names = [r["filename"] for r in res.json()["replays"]]
    assert not any(n.startswith("timelapse_") for n in names)

    # The signed URL serves the clip itself.
    res = client.get(body["url"], headers={"x-api-token": os.environ["PETTRACK_SECRET"]})
    assert res.status_code == 200


def test_timelapse_endpoint_rejects_bad_dates_and_empty_days(client):
    res = client.get(
        "/api/timelapse?date=not-a-date",
        headers={"x-api-token": os.environ["PETTRACK_SECRET"]},
    )
    assert res.status_code == 400

    res = client.get(
        "/api/timelapse?date=2000-01-01",
        headers={"x-api-token": os.environ["PETTRACK_SECRET"]},
    )
    assert res.status_code == 404
