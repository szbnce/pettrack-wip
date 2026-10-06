"""Daily recap: stitch the day's motion clips into one shareable highlight.

vision.py records each motion event as replays/replay_<epoch>.mp4 (about 30
seconds). A highlight takes the first few seconds of every clip from one day
and concatenates them into replays/highlight_<date>.mp4, so the app can offer
"today's recap" as a single video.

Shells out to ffmpeg — the same tool the recording pipeline already uses for
the h264 pass. If ffmpeg is missing the feature quietly disables itself
(build_daily_highlight returns None) and the server keeps working.
"""
import os
import shutil
import subprocess
import tempfile
from datetime import date, datetime

HIGHLIGHT_PREFIX = "highlight_"

# Seconds taken from each clip — a montage, not a marathon.
CLIP_SECONDS = float(os.getenv("PETTRACK_HIGHLIGHT_CLIP_SECONDS", "8"))

# Safety valve: never stitch an unbounded number of clips in one request.
MAX_CLIPS = int(os.getenv("PETTRACK_HIGHLIGHT_MAX_CLIPS", "40"))

# Common canvas so clips from different sessions (or cameras) concat cleanly.
_CANVAS = (1280, 720)


def _clips_for_day(day: date, folder: str) -> list[str]:
    """Replay files recorded on `day`, oldest first (mtime, like /api/replays)."""
    if not os.path.isdir(folder):
        return []
    clips = []
    for filename in os.listdir(folder):
        if not filename.endswith(".mp4"):
            continue
        if filename.startswith(HIGHLIGHT_PREFIX) or filename.endswith("_raw.mp4"):
            continue
        path = os.path.join(folder, filename)
        mtime = os.path.getmtime(path)
        if datetime.fromtimestamp(mtime).date() == day:
            clips.append((mtime, path))
    clips.sort()
    return [path for _, path in clips]


def _is_fresh(output: str, clips: list[str]) -> bool:
    if not os.path.exists(output) or not clips:
        return False
    newest_source = max(os.path.getmtime(c) for c in clips)
    return os.path.getmtime(output) >= newest_source


def _ffmpeg_concat(clips: list[str], output: str, ffmpeg: str) -> int:
    """Trim each clip to CLIP_SECONDS, letterbox to a canvas, concat, h264.

    Clips are encoded one at a time so a single corrupt/partial recording is
    skipped instead of killing the whole recap. Returns how many clips made
    it into the recap (0 on total failure).
    """
    if shutil.which(ffmpeg) is None:
        print("highlight: ffmpeg not found, recap disabled", flush=True)
        return 0

    canvas = f"{_CANVAS[0]}:{_CANVAS[1]}"
    vf = (
        f"scale={canvas}:force_original_aspect_ratio=decrease,"
        f"pad={canvas}:(ow-iw)/2:(oh-ih)/2,setsar=1"
    )

    workdir = tempfile.mkdtemp(prefix="pettrack_highlight_")
    parts: list[str] = []
    try:
        for i, clip in enumerate(clips):
            part = os.path.join(workdir, f"part_{i:03d}.mp4")
            cmd = [
                ffmpeg, "-y", "-loglevel", "error",
                "-t", str(CLIP_SECONDS), "-i", clip,
                "-vf", vf,
                "-c:v", "libx264", "-pix_fmt", "yuv420p",
                part,
            ]
            try:
                subprocess.run(cmd, check=True, timeout=60)
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
                print(f"highlight: skipping unreadable clip {clip}: {e}", flush=True)
                continue
            if os.path.exists(part) and os.path.getsize(part) > 0:
                parts.append(part)

        if not parts:
            print("highlight: no usable clips for the recap", flush=True)
            return 0

        concat_list = os.path.join(workdir, "list.txt")
        with open(concat_list, "w") as f:
            for part in parts:
                f.write(f"file '{part}'\n")

        tmp_output = output + ".part.mp4"
        cmd = [
            ffmpeg, "-y", "-loglevel", "error",
            "-f", "concat", "-safe", "0", "-i", concat_list,
            "-c", "copy", "-movflags", "+faststart",
            tmp_output,
        ]
        try:
            subprocess.run(cmd, check=True, timeout=120)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            print(f"highlight: ffmpeg concat failed: {e}", flush=True)
            if os.path.exists(tmp_output):
                os.remove(tmp_output)
            return 0

        os.replace(tmp_output, output)
        return len(parts)
    finally:
        shutil.rmtree(workdir, ignore_errors=True)


def build_daily_highlight(day: date | None = None, folder: str = "replays") -> dict | None:
    """Build (or reuse) the recap for `day`. Returns info dict, or None.

    dict: {"date": "YYYY-MM-DD", "filename": ..., "path": ..., "clip_count": int}
    """
    day = day or date.today()
    clips = _clips_for_day(day, folder)
    if not clips:
        return None

    clips = clips[:MAX_CLIPS]
    os.makedirs(folder, exist_ok=True)
    filename = f"{HIGHLIGHT_PREFIX}{day.isoformat()}.mp4"
    output = os.path.join(folder, filename)

    if _is_fresh(output, clips):
        used = len(clips)
    else:
        used = _ffmpeg_concat(clips, output, os.getenv("PETTRACK_FFMPEG", "ffmpeg"))
        if used == 0:
            return None

    return {
        "date": day.isoformat(),
        "filename": filename,
        "path": output,
        "clip_count": used,
    }
