import os
import time
import asyncio

import health
import api_routes
import maintenance
from database import log_event

async def cleanup_old_images():
    """The retention sweep every ten minutes — the same pass the app's
    "free up space now" button runs on demand (maintenance.run_cleanup_once)."""
    while True:
        try:
            maintenance.run_cleanup_once()
        except Exception as e:
            print(f"Error in cleanup task: {e}")

        await asyncio.sleep(600)


async def watchdog_loop():
    """Say something when the camera goes quiet or the disk fills up.

    Alerts are edge-triggered — one event per outage, not one per minute —
    so the activity feed stays readable. The state to act on lives in
    /api/system-health; the events are just the paper trail."""
    alerted = set()
    disk_was_low = False
    while True:
        now = time.time()
        for mid in health.offline_cameras(api_routes.monitor_registry, now):
            if mid not in alerted:
                alerted.add(mid)
                await log_event("camera_offline", details=mid)
        for mid in list(alerted):
            entry = api_routes.monitor_registry.get(mid, {})
            if not health.camera_is_alertable(entry, now):
                alerted.discard(mid)

        try:
            disk_low = health.disk_snapshot(
                "replays" if os.path.exists("replays") else "."
            )["low"]
        except OSError:
            disk_low = False
        if disk_low and not disk_was_low:
            await log_event("disk_low")
        disk_was_low = disk_low

        await asyncio.sleep(60)

        