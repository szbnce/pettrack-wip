"""One-shot storage maintenance — the retention sweep, callable right now.

The background loop (`tasks.cleanup_old_images`) runs this every ten
minutes; the app's "free up space now" button calls it directly. Each
step is independent: one unreadable folder never stops the rest.
"""

import os
import time
from datetime import date, timedelta

import health
import timelapse


def _sweep_captured_images(stats: dict) -> None:
    """Snapshots older than 12 hours go; past 500, the oldest follow."""
    folder = "captured_images"
    if not os.path.isdir(folder):
        return
    try:
        files = []
        for filename in os.listdir(folder):
            path = os.path.join(folder, filename)
            if os.path.isfile(path):
                files.append((path, os.path.getmtime(path), os.path.getsize(path)))
        files.sort(key=lambda x: x[1])

        cutoff = time.time() - (12 * 60 * 60)
        kept = []
        for path, mtime, size in files:
            if mtime < cutoff:
                _drop(path, size, stats, "images")
            else:
                kept.append((path, mtime, size))

        max_files = 500
        for path, _mtime, size in kept[: max(0, len(kept) - max_files)]:
            _drop(path, size, stats, "images")
    except Exception as e:
        print(f"Error in image cleanup: {e}")


def _sweep_timelapse_stills(stats: dict) -> None:
    """Stills past the timelapse retention window are safe to forget."""
    folder = timelapse.DEFAULT_FOLDER
    if not os.path.isdir(folder):
        return
    try:
        cutoff_day = date.today() - timedelta(days=timelapse.RETENTION_DAYS)
        for filename in os.listdir(folder):
            if not filename.startswith(timelapse.FRAME_PREFIX):
                continue
            path = os.path.join(folder, filename)
            if not os.path.isfile(path):
                continue
            if date.fromtimestamp(os.path.getmtime(path)) < cutoff_day:
                _drop(path, os.path.getsize(path), stats, "timelapse")
    except Exception as e:
        print(f"Error in timelapse cleanup: {e}")


def _sweep_replays(stats: dict) -> None:
    """Replays past the retention window, and the oldest under pressure."""
    try:
        result = health.prune_replays()
        stats["replays_deleted"] += result["deleted"]
        stats["replays_freed_bytes"] += result["freed_bytes"]
    except Exception as e:
        print(f"Error in replay cleanup: {e}")


def _drop(path: str, size: int, stats: dict, bucket: str) -> None:
    try:
        os.remove(path)
        stats[f"{bucket}_deleted"] += 1
        stats[f"{bucket}_freed_bytes"] += size
    except OSError as e:
        print(f"Error removing {path}: {e}")


def run_cleanup_once() -> dict:
    """One full pass of the storage sweep, right now.

    Returns what each step deleted and how much disk that freed."""
    stats = {
        "images_deleted": 0,
        "images_freed_bytes": 0,
        "timelapse_deleted": 0,
        "timelapse_freed_bytes": 0,
        "replays_deleted": 0,
        "replays_freed_bytes": 0,
    }
    _sweep_captured_images(stats)
    _sweep_timelapse_stills(stats)
    _sweep_replays(stats)
    return stats
