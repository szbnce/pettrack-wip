"""Tier-1 motion detection: cheap, Pillow + numpy only, no OpenCV.

Most frames are static. Instead of running a full computer-vision pipeline
on every frame, we diff a tiny grayscale thumbnail of consecutive frames.
Only when that gate fires does the caller spend real work (localization,
zone checks, decoding full frames for recording).
"""
import io
from dataclasses import dataclass

import numpy as np
from PIL import Image


@dataclass(frozen=True)
class MotionResult:
    motion: bool
    center: tuple | None  # (x, y) in pixels of the small frame
    changed_pixels: int
    coverage: float  # fraction of the frame that changed


def decode_small(data: bytes, target_width: int = 160) -> np.ndarray | None:
    """Decode image bytes into a small grayscale uint8 array, or None."""
    try:
        img = Image.open(io.BytesIO(data))
        img.draft("L", (target_width * 2, target_width * 2))
        img = img.convert("L")
        if img.width > target_width:
            ratio = target_width / img.width
            img = img.resize(
                (target_width, max(1, round(img.height * ratio))),
                Image.Resampling.BILINEAR,
            )
        return np.asarray(img, dtype=np.uint8)
    except Exception:
        return None


def mean_brightness(small: np.ndarray) -> float:
    return float(small.mean())


def detect_motion(
    prev: np.ndarray | None,
    cur: np.ndarray,
    threshold: int = 25,
    min_pixels: int = 12,
    max_coverage: float = 0.45,
) -> MotionResult:
    """Compare two small grayscale frames and report localized motion.

    - ``threshold``: per-pixel brightness delta that counts as "changed".
    - ``min_pixels``: ignore specks (noise, compression shimmer).
    - ``max_coverage``: a change covering most of the frame is a lighting
      change or a camera bump, not a pet walking around.
    """
    if prev is None or prev.shape != cur.shape:
        return MotionResult(False, None, 0, 0.0)

    diff = np.abs(prev.astype(np.int16) - cur.astype(np.int16))
    mask = diff > threshold
    changed = int(mask.sum())
    coverage = changed / mask.size

    if changed < min_pixels or coverage > max_coverage:
        return MotionResult(False, None, changed, coverage)

    ys, xs = np.nonzero(mask)
    center = (float(xs.mean()), float(ys.mean()))
    return MotionResult(True, center, changed, coverage)


def point_in_polygon(px: float, py: float, points) -> bool:
    """Even-odd rule. Points are (x, y) pairs in the same space as (px, py)."""
    n = len(points)
    if n < 3:
        return False
    inside = False
    j = n - 1
    for i in range(n):
        xi, yi = points[i]
        xj, yj = points[j]
        if (yi > py) != (yj > py):
            x_cross = (xj - xi) * (py - yi) / (yj - yi) + xi
            if px < x_cross:
                inside = not inside
        j = i
    return inside
