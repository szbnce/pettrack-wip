"""Day timelapse: sample the live stream into stills and stitch them.

While a monitor streams, the server saves one still every
PETTRACK_TIMELAPSE_INTERVAL seconds; `build_timelapse` stitches a day's
stills into one mp4 — a whole day of pet life in a few seconds.

Environment:
  PETTRACK_TIMELAPSE_INTERVAL        seconds between stills (default 60, 0 = off)
  PETTRACK_TIMELAPSE_RETENTION_DAYS  days to keep stills (default 7)
  PETTRACK_TIMELAPSE_FPS             playback fps of the built clip (default 30)
  PETTRACK_TIMELAPSE_MIN_FRAMES      minimum stills worth stitching (default 2)
"""
import os
import shutil
import subprocess
import tempfile
import time
from datetime import date

FRAME_PREFIX = "frame_"
OUTPUT_PREFIX = "timelapse_"
DEFAULT_FOLDER = "timelapse"
CANVAS = (1280, 720)

INTERVAL = float(os.getenv("PETTRACK_TIMELAPSE_INTERVAL", "60"))
RETENTION_DAYS = int(os.getenv("PETTRACK_TIMELAPSE_RETENTION_DAYS", "7"))
FPS = float(os.getenv("PETTRACK_TIMELAPSE_FPS", "30"))
MIN_FRAMES = int(os.getenv("PETTRACK_TIMELAPSE_MIN_FRAMES", "2"))

_last_sample = 0.0


def maybe_sample(data: bytes, folder: str = DEFAULT_FOLDER) -> bool:
    """Save one still per interval while frames arrive. Returns True when saved.

    Only JPEG frames are kept — that is what the monitor sends, and the
    image-sequence encoder wants one consistent format.
    """
    global _last_sample
    if INTERVAL <= 0 or not data or data[:2] != b"\xff\xd8":
        return False
    now = time.time()
    if now - _last_sample < INTERVAL:
        return False
    _last_sample = now
    os.makedirs(folder, exist_ok=True)
    # Nanoseconds: two saves inside one millisecond must not collide.
    path = os.path.join(folder, f"{FRAME_PREFIX}{time.time_ns()}.jpg")
    try:
        with open(path, "wb") as f:
            f.write(data)
    except OSError as e:
        print(f"Timelapse: failed to save still: {e}", flush=True)
        return False
    return True


def frames_for_day(day: date, folder: str = DEFAULT_FOLDER) -> list:
    """Still frames whose mtime falls on `day`, oldest first."""
    if not os.path.isdir(folder):
        return []
    out = []
    for name in os.listdir(folder):
        if not name.startswith(FRAME_PREFIX) or not name.endswith(".jpg"):
            continue
        path = os.path.join(folder, name)
        mtime = os.path.getmtime(path)
        if date.fromtimestamp(mtime) == day:
            out.append((mtime, path))
    out.sort()
    return [path for _, path in out]


def _is_fresh(output: str, frames: list) -> bool:
    """True when the built clip is newer than every source still."""
    if not os.path.exists(output) or not frames:
        return False
    out_m = os.path.getmtime(output)
    return all(os.path.getmtime(f) <= out_m for f in frames)


def _ffmpeg_stills(frames: list, output: str, ffmpeg: str) -> int:
    """Encode numbered stills into `output` via ffmpeg; returns frames used.

    Stills are linked into a scratch dir under sequential names because the
    image2 demuxer wants a numbered pattern. Unreadable input just shortens
    the clip — one bad frame must not kill the timelapse.
    """
    tmpdir = tempfile.mkdtemp(prefix="pettrack_timelapse_")
    try:
        used = 0
        for src in frames:
            dst = os.path.join(tmpdir, f"frame_{used:05d}.jpg")
            try:
                os.symlink(os.path.abspath(src), dst)
            except OSError:
                try:
                    shutil.copyfile(src, dst)
                except OSError:
                    continue
            used += 1
        if used == 0:
            return 0

        output_dir = os.path.dirname(output) or "."
        os.makedirs(output_dir, exist_ok=True)
        vf = (
            f"scale={CANVAS[0]}:{CANVAS[1]}:force_original_aspect_ratio=decrease,"
            f"pad={CANVAS[0]}:{CANVAS[1]}:(ow-iw)/2:(oh-ih)/2,setsar=1"
        )
        cmd = [
            ffmpeg, "-y",
            "-framerate", str(FPS),
            "-i", os.path.join(tmpdir, "frame_%05d.jpg"),
            "-vf", vf,
            "-pix_fmt", "yuv420p",
            "-c:v", "libx264",
            "-movflags", "+faststart",
            output,
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0 or not os.path.exists(output):
            print(f"Timelapse: ffmpeg failed: {proc.stderr[-400:]}", flush=True)
            return 0
        return used
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)


def build_timelapse(day: date = None, folder: str = DEFAULT_FOLDER) -> dict:
    """Build (or reuse) the day's timelapse. Returns None when not enough stills.

    Result: {"date", "path", "filename", "frame_count"} — the clip lands in
    replays/timelapse_<date>.mp4 so the media endpoint can serve it.
    """
    if day is None:
        day = date.today()
    frames = frames_for_day(day, folder)
    if len(frames) < MIN_FRAMES:
        return None

    filename = f"{OUTPUT_PREFIX}{day.isoformat()}.mp4"
    output = os.path.join("replays", filename)
    if _is_fresh(output, frames):
        used = len(frames)
    else:
        used = _ffmpeg_stills(frames, output, os.getenv("PETTRACK_FFMPEG", "ffmpeg"))
        if used == 0:
            return None
    return {
        "date": day.isoformat(),
        "path": output,
        "filename": filename,
        "frame_count": used,
    }
