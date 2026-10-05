"""Tests for the tier-1 motion gate (pure Pillow + numpy, no camera needed)."""
import io

import numpy as np
from PIL import Image

from motion import decode_small, detect_motion, mean_brightness, point_in_polygon


def _jpeg(arr: np.ndarray) -> bytes:
    buf = io.BytesIO()
    Image.fromarray(arr, mode="L").save(buf, format="JPEG", quality=90)
    return buf.getvalue()


def _static_frame(value: int = 100, rows: int = 120, cols: int = 160) -> np.ndarray:
    return np.full((rows, cols), value, dtype=np.uint8)


# --- decode_small ------------------------------------------------------------

def test_decode_small_resizes_to_target_width():
    arr = np.zeros((240, 320), dtype=np.uint8)
    arr[100:140, 200:260] = 255
    small = decode_small(_jpeg(arr), target_width=160)
    assert small is not None
    assert small.shape[1] == 160
    assert small.shape[0] == 120
    assert small.dtype == np.uint8


def test_decode_small_rejects_garbage():
    assert decode_small(b"not an image") is None


# --- detect_motion -----------------------------------------------------------

def test_first_frame_has_no_motion():
    assert not detect_motion(None, _static_frame()).motion


def test_mismatched_shapes_have_no_motion():
    assert not detect_motion(_static_frame(rows=100), _static_frame(rows=120)).motion


def test_static_frames_have_no_motion():
    a = _static_frame()
    assert not detect_motion(a, a.copy()).motion


def test_moving_blob_is_detected_and_localized():
    a = _static_frame(40)
    b = a.copy()
    b[30:50, 100:130] = 200  # bright square in the lower-right quadrant
    r = detect_motion(a, b, min_pixels=10, threshold=25)
    assert r.motion
    assert r.center is not None
    cx, cy = r.center
    assert 100 <= cx <= 130
    assert 30 <= cy <= 50
    assert r.changed_pixels == 30 * 20


def test_global_illumination_change_is_not_motion():
    a = _static_frame(80)
    b = _static_frame(130)  # whole frame shifted +50
    r = detect_motion(a, b, max_coverage=0.45)
    assert not r.motion
    assert r.coverage > 0.45


def test_tiny_noise_is_ignored():
    a = _static_frame(80)
    b = a.copy()
    b[5, 5] = 255
    assert not detect_motion(a, b, min_pixels=12).motion


def test_mean_brightness():
    assert mean_brightness(_static_frame(40)) == 40.0
    assert mean_brightness(_static_frame(10)) < 25


# --- point_in_polygon --------------------------------------------------------

SQUARE = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]
TRIANGLE = [(0.0, 0.0), (1.0, 0.0), (0.5, 1.0)]


def test_point_in_polygon_inside_and_outside():
    assert point_in_polygon(0.5, 0.5, SQUARE)
    assert not point_in_polygon(1.5, 0.5, SQUARE)
    assert point_in_polygon(0.5, 0.3, TRIANGLE)
    assert not point_in_polygon(0.9, 0.9, TRIANGLE)


def test_point_in_polygon_degenerate_shapes():
    assert not point_in_polygon(0.5, 0.5, [])
    assert not point_in_polygon(0.5, 0.5, [(0.0, 0.0), (1.0, 1.0)])
