import os
import shutil
import time
from datetime import date, timedelta

import pytest

cv2 = pytest.importorskip("cv2")
np = pytest.importorskip("numpy")

from highlight import build_daily_highlight, _clips_for_day

needs_ffmpeg = pytest.mark.skipif(
    shutil.which("ffmpeg") is None, reason="ffmpeg not installed"
)


def _write_clip(path, frames=6, size=(64, 48), fps=5):
    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    writer = cv2.VideoWriter(str(path), fourcc, fps, size)
    assert writer.isOpened(), "cv2.VideoWriter failed to open"
    for i in range(frames):
        frame = np.full((size[1], size[0], 3), i * 20 % 255, dtype=np.uint8)
        writer.write(frame)
    writer.release()


def _touch(path, when: date):
    """Give a file an mtime inside `when` (noon local time)."""
    ts = time.mktime(
        (when.year, when.month, when.day, 12, 0, 0, 0, 0, -1)
    )
    os.utime(path, (ts, ts))


def test_clips_for_day_filters_by_day_and_kind(tmp_path):
    day = date.today()
    other = day - timedelta(days=2)

    keep = tmp_path / "replay_1.mp4"
    stale = tmp_path / "replay_2.mp4"
    raw = tmp_path / "replay_3_raw.mp4"
    recap = tmp_path / f"highlight_{day.isoformat()}.mp4"
    not_video = tmp_path / "notes.txt"
    for p in (keep, stale, raw, recap, not_video):
        p.write_bytes(b"x")

    _touch(keep, day)
    _touch(stale, other)
    _touch(raw, day)
    _touch(recap, day)

    clips = _clips_for_day(day, str(tmp_path))
    assert clips == [str(keep)]


@needs_ffmpeg
def test_builds_recap_from_the_days_clips(tmp_path):
    day = date.today()
    for i in range(2):
        clip = tmp_path / f"replay_{i}.mp4"
        _write_clip(clip)
        _touch(clip, day)

    result = build_daily_highlight(day, folder=str(tmp_path))
    assert result is not None
    assert result["clip_count"] == 2
    assert result["date"] == day.isoformat()
    assert os.path.exists(result["path"])
    assert os.path.getsize(result["path"]) > 0


@needs_ffmpeg
def test_recap_is_cached_until_a_new_clip_arrives(tmp_path):
    day = date.today()
    clip = tmp_path / "replay_1.mp4"
    _write_clip(clip)
    _touch(clip, day)

    first = build_daily_highlight(day, folder=str(tmp_path))
    assert first is not None
    mtime = os.path.getmtime(first["path"])

    # Same day, same clips: served from the cache, no rebuild.
    time.sleep(0.05)
    second = build_daily_highlight(day, folder=str(tmp_path))
    assert second is not None
    assert os.path.getmtime(second["path"]) == mtime

    # A new clip for the same day (recorded now, i.e. after the recap)
    # forces a rebuild.
    new_clip = tmp_path / "replay_2.mp4"
    _write_clip(new_clip)
    third = build_daily_highlight(day, folder=str(tmp_path))
    assert third is not None
    assert third["clip_count"] == 2
    assert os.path.getmtime(third["path"]) > mtime


@needs_ffmpeg
def test_corrupt_clips_are_skipped_not_fatal(tmp_path):
    day = date.today()
    good = tmp_path / "replay_1.mp4"
    _write_clip(good)
    _touch(good, day)
    bad = tmp_path / "replay_2.mp4"
    bad.write_bytes(b"not really a video")
    _touch(bad, day)

    result = build_daily_highlight(day, folder=str(tmp_path))
    assert result is not None
    assert result["clip_count"] == 1
    assert os.path.getsize(result["path"]) > 0


def test_returns_none_for_an_empty_day(tmp_path):
    assert build_daily_highlight(date.today(), folder=str(tmp_path)) is None
    assert build_daily_highlight(date.today(), folder=str(tmp_path / "nope")) is None


@needs_ffmpeg
def test_highlight_endpoint_and_listing(client, tmp_path_factory):
    # The client fixture chdirs into its own temp dir; work there so the
    # routes' relative "replays" folder is ours.
    day = date.today()
    os.makedirs("replays", exist_ok=True)
    clip = "replays/replay_99.mp4"
    _write_clip(clip)
    _touch(clip, day)

    res = client.get(
        "/api/highlight",
        headers={"x-api-token": os.environ["PETTRACK_SECRET"]},
    )
    assert res.status_code == 200
    body = res.json()
    assert body["clip_count"] == 1
    assert body["filename"] == f"highlight_{day.isoformat()}.mp4"
    assert body["url"].startswith("/api/replays/highlight_")

    # The recap must not show up in the event replay list.
    res = client.get(
        "/api/replays",
        headers={"x-api-token": os.environ["PETTRACK_SECRET"]},
    )
    names = [r["filename"] for r in res.json()["replays"]]
    assert clip.split("/")[-1] in names
    assert not any(n.startswith("highlight_") for n in names)

    # The signed URL serves the recap itself.
    res = client.get(body["url"], headers={"x-api-token": os.environ["PETTRACK_SECRET"]})
    assert res.status_code == 200


@needs_ffmpeg
def test_highlight_endpoint_rejects_bad_date(client):
    res = client.get(
        "/api/highlight?date=not-a-date",
        headers={"x-api-token": os.environ["PETTRACK_SECRET"]},
    )
    assert res.status_code == 400


def test_highlight_endpoint_404_when_no_events(client):
    res = client.get(
        "/api/highlight?date=2000-01-01",
        headers={"x-api-token": os.environ["PETTRACK_SECRET"]},
    )
    assert res.status_code == 404
