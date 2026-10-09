"""Watchdog: is the camera alive, is the disk fine, and is anything pruning.

Self-hosters trust a tool that tells them when *it* is broken — so the
server says so instead of quietly going dark or filling the disk.
"""
import os
import shutil
import time

import pins
import settings as app_settings

# Quiet this long with no frames at all and the camera is worth an alert —
# a few seconds between frames is normal, ten minutes is not.
CAMERA_OFFLINE_ALERT_SECONDS = 10 * 60

# Below this much free space the disk counts as low: /api/system-health warns, and
# pruning drops the oldest replays to make room.
DISK_LOW_FREE_BYTES = 500 * 1024 * 1024

# A *_raw.mp4 is the in-progress twin of a replay; the ffmpeg conversion
# deletes it seconds later. Anything older than this is a leftover from a
# crash and goes regardless of the retention setting.
STALE_RAW_SECONDS = 3600


def camera_is_alertable(entry: dict, now: float | None = None) -> bool:
    """True when this camera has been quiet long enough to say something.

    Only cameras that actually streamed can alert: a registered-but-silent
    entry is a phone that opened the monitor screen and left again, not a
    camera that dropped out on a pet."""
    now = now or time.time()
    if entry.get("frame_count", 0) <= 0:
        return False
    last_seen = entry.get("last_seen", 0.0)
    return last_seen > 0 and now - last_seen >= CAMERA_OFFLINE_ALERT_SECONDS


def offline_cameras(registry: dict, now: float | None = None) -> list:
    """Monitor ids that deserve an offline alert, sorted for stable output."""
    now = now or time.time()
    return sorted(
        mid for mid, entry in registry.items() if camera_is_alertable(entry, now)
    )


def disk_snapshot(path: str = ".") -> dict:
    usage = shutil.disk_usage(path)
    return {
        "free_bytes": usage.free,
        "total_bytes": usage.total,
        "low": usage.free < DISK_LOW_FREE_BYTES,
    }


def replay_stats(folder: str = "replays") -> dict:
    count = 0
    total_bytes = 0
    if os.path.isdir(folder):
        for filename in os.listdir(folder):
            if not filename.endswith(".mp4"):
                continue
            try:
                total_bytes += os.path.getsize(os.path.join(folder, filename))
                count += 1
            except OSError:
                pass
    return {
        "count": count,
        "bytes": total_bytes,
        "pinned": len(pins.load_pins(folder)),
    }


def prune_replays(
    folder: str = "replays",
    retention_days: int | None = None,
    now: float | None = None,
    min_free_bytes: int | None = DISK_LOW_FREE_BYTES,
) -> dict:
    """Delete replays past the retention window; under disk pressure, the
    oldest go too until there is room.

    Retention is the normal policy (see settings.get_replay_retention_days);
    min_free_bytes is the safety valve so a full disk never stops a recording
    mid-day. In-progress *_raw.mp4 twins are kept for an hour, then dropped.
    Pinned clips (pins.py) survive both — a pin is absolute.
    Returns {"deleted": n, "freed_bytes": n}."""
    deleted = 0
    freed_bytes = 0
    if not os.path.isdir(folder):
        return {"deleted": deleted, "freed_bytes": freed_bytes}

    now = now or time.time()
    if retention_days is None:
        retention_days = app_settings.get_replay_retention_days()
    cutoff = now - retention_days * 86400
    pinned = pins.load_pins(folder)

    # keep = (mtime, path, pinned) oldest first — the order disk pressure drops them
    keep = []
    for filename in os.listdir(folder):
        if not filename.endswith(".mp4"):
            continue
        path = os.path.join(folder, filename)
        if not os.path.isfile(path):
            continue
        is_pinned = filename in pinned
        mtime = os.path.getmtime(path)
        stale_raw = filename.endswith("_raw.mp4") and now - mtime > STALE_RAW_SECONDS
        if is_pinned:
            keep.append((mtime, path, True))
        elif mtime < cutoff or stale_raw:
            try:
                freed_bytes += os.path.getsize(path)
                os.remove(path)
                deleted += 1
            except OSError:
                keep.append((mtime, path, False))
        else:
            keep.append((mtime, path, False))

    if min_free_bytes:
        keep.sort()
        try:
            free = shutil.disk_usage(folder).free
        except OSError:
            free = None
        while free is not None and free < min_free_bytes and keep:
            # Oldest unpinned first; if everything left is pinned, pins win.
            victim = next((i for i, item in enumerate(keep) if not item[2]), None)
            if victim is None:
                break
            _, path, _ = keep.pop(victim)
            try:
                size = os.path.getsize(path)
                os.remove(path)
                freed_bytes += size
                deleted += 1
                free += size
            except OSError:
                pass

    return {"deleted": deleted, "freed_bytes": freed_bytes}
