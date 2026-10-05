import cv2
import numpy as np
import time
import os
import asyncio
import subprocess
from api_routes import active_zones
from database import log_event
from motion import decode_small, detect_motion, mean_brightness, point_in_polygon

os.makedirs("captured_images", exist_ok=True)
os.makedirs("replays", exist_ok=True)

# --- configuration (env-overridable, homelab-friendly defaults) ---
# PETTRACK_VISION_MODE: "motion" (default) or "off" to disable detection entirely.
VISION_MODE = os.getenv("PETTRACK_VISION_MODE", "motion").strip().lower()
SMALL_WIDTH = int(os.getenv("PETTRACK_MOTION_WIDTH", "160"))
MOTION_THRESHOLD = int(os.getenv("PETTRACK_MOTION_THRESHOLD", "25"))
MOTION_MIN_PIXELS = int(os.getenv("PETTRACK_MOTION_MIN_PIXELS", "12"))
MOTION_MAX_COVERAGE = float(os.getenv("PETTRACK_MOTION_MAX_COVERAGE", "0.45"))
MOTION_TIMEOUT = float(os.getenv("PETTRACK_MOTION_TIMEOUT", "5"))
DARK_BRIGHTNESS = float(os.getenv("PETTRACK_DARK_BRIGHTNESS", "25"))

_last_zones: set = set()
_last_pet_center = None  # normalized (0..1) coordinates of the moving blob
_last_motion_time = 0.0
_prev_small = None

_video_writer = None
_recording_end_time = 0.0
_current_video_path = ""
_fps = 5


def _full_decode(image_bytes: bytes):
    nparr = np.frombuffer(image_bytes, np.uint8)
    return cv2.imdecode(nparr, cv2.IMREAD_COLOR)


async def process_and_save_frame(image_bytes: bytes):
    """Tiered pipeline: cheap thumbnail diff first, expensive work only if needed.

    Tier 1 (every frame): decode a ~160px grayscale thumbnail and diff it
    against the previous one — Pillow + numpy, no OpenCV.
    Tier 2 (only on motion): localize the moving blob, run zone checks.
    Full-resolution decode happens only while a replay is recording.
    """
    global _last_zones, _last_pet_center, _last_motion_time, _prev_small
    global _video_writer, _recording_end_time, _current_video_path

    timestamp = int(time.time())
    now = time.time()

    # Recording needs full frames; nothing else does.
    frame = None
    if _video_writer is not None:
        frame = _full_decode(image_bytes)
        if frame is not None:
            _video_writer.write(frame)
        if now > _recording_end_time:
            _video_writer.release()
            _video_writer = None
            print(f"Finished recording raw video: {_current_video_path}", flush=True)

            raw_path = _current_video_path.replace(".mp4", "_raw.mp4")
            subprocess.Popen(
                f"ffmpeg -y -i {raw_path} -vcodec libx264 -pix_fmt yuv420p {_current_video_path} && rm {raw_path}",
                shell=True,
            )
            print(f"Started FFmpeg conversion for {_current_video_path}", flush=True)

    if VISION_MODE == "off":
        return

    small = decode_small(image_bytes, SMALL_WIDTH)
    if small is None:
        print("Failed to decode image", flush=True)
        return

    if mean_brightness(small) < DARK_BRIGHTNESS:
        # Too dark to trust detection; drop the tracked pet after a timeout.
        if _last_pet_center is not None and now - _last_motion_time > MOTION_TIMEOUT:
            _last_pet_center = None
        _prev_small = small
        return

    result = detect_motion(
        _prev_small,
        small,
        threshold=MOTION_THRESHOLD,
        min_pixels=MOTION_MIN_PIXELS,
        max_coverage=MOTION_MAX_COVERAGE,
    )
    _prev_small = small

    if result.motion and result.center is not None:
        _last_motion_time = now
        # Normalized coordinates (0..1) so zone polygons (also normalized)
        # can be tested without knowing the full frame size.
        _last_pet_center = (
            result.center[0] / small.shape[1],
            result.center[1] / small.shape[0],
        )
    elif now - _last_motion_time > MOTION_TIMEOUT:
        # No motion for a while, stop claiming to know where the pet is.
        _last_pet_center = None

    current_zones = set()
    if _last_pet_center is not None:
        px, py = _last_pet_center
        for zone_name, polygon_points in active_zones.items():
            pts = [(p["x"], p["y"]) for p in polygon_points]
            if point_in_polygon(px, py, pts):
                current_zones.add(zone_name)

    entered = current_zones - _last_zones
    if entered:
        # Start or extend a 30 second replay recording.
        _recording_end_time = now + 30
        if _video_writer is None:
            if frame is None:
                frame = _full_decode(image_bytes)
            if frame is not None:
                height, width = frame.shape[:2]
                _current_video_path = f"replays/replay_{timestamp}.mp4"
                raw_path = _current_video_path.replace(".mp4", "_raw.mp4")
                # Write raw mp4v first, then convert with ffmpeg for web compatibility
                fourcc = cv2.VideoWriter_fourcc(*'mp4v')
                _video_writer = cv2.VideoWriter(raw_path, fourcc, _fps, (width, height))
                _video_writer.write(frame)
                print(f"Started recording: {_current_video_path}", flush=True)

        # Save snapshot (the original bytes — no decode needed)
        ext = "jpg" if image_bytes[:2] == b"\xff\xd8" else "png"
        file_path = f"captured_images/frame_{timestamp}.{ext}"
        with open(file_path, "wb") as f:
            f.write(image_bytes)

    for zone in entered:
        print(f"Event: MOVEMENT DETECTED IN ZONE {zone}", flush=True)
        await log_event("zone_enter", zone_name=zone)

    exited = _last_zones - current_zones
    for zone in exited:
        print(f"Event: LEFT ZONE {zone}", flush=True)
        await log_event("zone_exit", zone_name=zone)

    _last_zones = current_zones
