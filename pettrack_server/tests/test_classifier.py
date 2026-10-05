"""Tests for the optional tier-3 classifier (hermetic: no ONNX model, no download)."""
import numpy as np
import pytest

import classifier
from classifier import Classification, PetClassifier, label_is_pet, load_classifier


# --- label heuristics --------------------------------------------------------

def test_pet_labels_are_recognized():
    assert label_is_pet("n02123045 tabby, tabby cat")
    assert label_is_pet("wood rabbit, cottontail, cottontail rabbit")
    assert label_is_pet("guinea pig, Cavia cobaya")
    assert label_is_pet("parrot")
    assert label_is_pet("hamster")
    assert label_is_pet("golden retriever")


def test_non_pet_labels_are_rejected():
    assert not label_is_pet("sports car, sport car")
    assert not label_is_pet("computer keyboard, keypad")
    assert not label_is_pet("ocean")


def test_wild_animals_win_over_pet_keywords():
    # "leopard cat" is a wild small cat even though it contains "cat".
    assert not label_is_pet("leopard cat")
    assert not label_is_pet("tiger, Panthera tigris")
    assert not label_is_pet("African elephant")
    # "catbird" / "caterpillar" must not match the word "cat".
    assert not label_is_pet("catbird")
    assert not label_is_pet("caterpillar")


def test_default_paths_are_env_overridable():
    # Constants exist and are strings (env read at import time).
    assert isinstance(classifier.DEFAULT_MODEL_PATH, str)
    assert isinstance(classifier.DEFAULT_LABELS_PATH, str)


def test_load_classifier_returns_none_without_model(tmp_path, monkeypatch):
    monkeypatch.setenv("PETTRACK_CLASSIFIER_MODEL", str(tmp_path / "missing.onnx"))
    monkeypatch.setenv("PETTRACK_CLASSIFIER_LABELS", str(tmp_path / "missing.txt"))
    assert load_classifier(
        str(tmp_path / "missing.onnx"), str(tmp_path / "missing.txt")
    ) is None


# --- classify_rgb (session mocked) -------------------------------------------

def _fake_classifier(logits):
    """PetClassifier with a mocked ONNX session returning `logits`."""
    clf = PetClassifier.__new__(PetClassifier)

    class _IO:
        name = "input"
        shape = [1, 3, 224, 224]

    class _Session:
        def __init__(self, out):
            self._out = out
            self.last_input = None

        def get_inputs(self):
            return [_IO()]

        def run(self, _outputs, feeds):
            self.last_input = feeds["input"]
            return [np.array([self._out], dtype=np.float32)]

    clf._session = _Session(logits)
    clf._input_name = "input"
    clf._input_h = 224
    clf._input_w = 224
    clf._labels = [
        "background",
        "sports car, sport car",
        "tabby, tabby cat",
        "African elephant",
        "guinea pig, Cavia cobaya",
    ]
    return clf


def _crop(h=100, w=100):
    return np.full((h, w, 3), 128, dtype=np.uint8)


def test_classify_rgb_returns_top_non_pet():
    # index 1 ("sports car") is the clear winner
    logits = np.array([0.01, 0.90, 0.05, 0.02, 0.02], dtype=np.float32)
    v = _fake_classifier(logits).classify_rgb(_crop())
    assert not v.is_pet
    assert v.label.startswith("sports car")
    assert v.confidence == pytest.approx(0.90)


def test_classify_rgb_finds_pet_below_top1():
    # top-1 is a car, but the cat at index 2 is in top-5 with high confidence
    logits = np.array([0.01, 0.50, 0.35, 0.09, 0.05], dtype=np.float32)
    v = _fake_classifier(logits).classify_rgb(_crop())
    assert v.is_pet
    assert "cat" in v.label
    assert v.confidence == pytest.approx(0.35)


def test_classify_rgb_respects_min_confidence():
    # pet at 0.15, below the 0.2 default -> not a pet
    logits = np.array([0.01, 0.60, 0.15, 0.14, 0.10], dtype=np.float32)
    v = _fake_classifier(logits).classify_rgb(_crop())
    assert not v.is_pet


def test_classify_rgb_applies_softmax_to_logits():
    # Raw logits (negative values) -> treated as logits, softmax applied
    logits = np.array([0.1, -0.2, 5.0, -1.0, -3.0], dtype=np.float32)
    v = _fake_classifier(logits).classify_rgb(_crop())
    assert v.is_pet
    assert v.confidence > 0.9
    assert "cat" in v.label


def test_classify_rgb_builds_nchw_input():
    # The mock session records its feed; input must be 1x3x224x224 float32
    logits = np.array([0.01, 0.90, 0.05, 0.02, 0.02], dtype=np.float32)
    clf = _fake_classifier(logits)
    clf.classify_rgb(_crop())
    x = clf._session.last_input
    assert x.shape == (1, 3, 224, 224)
    assert x.dtype == np.float32


def test_classification_dataclass():
    c = Classification(is_pet=True, confidence=0.8, label="rabbit")
    assert c.is_pet and c.confidence == 0.8
