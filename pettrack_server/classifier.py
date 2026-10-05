"""Optional tier-3: pet / not-pet classification of motion crops (ONNX).

When a moving blob is found, we crop around it and ask a small ImageNet
classifier what it sees. If the answer is "a common pet" (cat, dog,
rabbit, ...) the motion becomes a zone event; everything else - people
walking past, curtains, shadows - is noise and gets dropped.

The model is NOT bundled with the repo. Get one with:

    python3 tools/fetch_classifier_model.py

or point PETTRACK_CLASSIFIER_MODEL / PETTRACK_CLASSIFIER_LABELS at any
ImageNet-compatible ONNX classifier plus its label list.
"""
import os
import re
from dataclasses import dataclass

import numpy as np

DEFAULT_MODEL_PATH = os.getenv("PETTRACK_CLASSIFIER_MODEL", "models/classifier.onnx")
DEFAULT_LABELS_PATH = os.getenv("PETTRACK_CLASSIFIER_LABELS", "models/imagenet_classes.txt")
DEFAULT_MIN_CONFIDENCE = float(os.getenv("PETTRACK_CLASSIFIER_MIN_CONF", "0.2"))
TOP_K = 5

# Labels are matched as whole words/phrases, wild animals win over pets:
# ImageNet has both "tiger cat" (a tabby) and "leopard cat" (a wild cat),
# and we prefer to miss an event over spamming the user.
PET_PATTERNS = re.compile(
    # Household pets, plus common breed words ("golden retriever" has no "dog").
    r"\b(cat|cats|kitten|dog|dogs|puppy|canine|retriever|terrier|spaniel|"
    r"poodle|beagle|bulldog|husky|malamute|chihuahua|dalmatian|corgi|collie|"
    r"sheepdog|schnauzer|setter|pointer|hound|pinscher|spitz|mastiff|"
    r"doberman|rottweiler|samoyed|pomeranian|papillon|pekinese|maltese|"
    r"borzoi|whippet|greyhound|saluki|weimaraner|vizsla|briard|kelpie|"
    r"schipperke|basenji|bloodhound|harrier|basset|lapdog|"
    r"rabbit|bunny|guinea pig|hamster|ferret|mouse|mice|rat|gerbil|"
    r"parrot|macaw|parakeet|budgie|canary|finch|cockatiel|cockatoo|"
    r"lovebird|goldfish|iguana|tortoise|turtle|gecko)\b",
    re.IGNORECASE,
)
WILD_PATTERNS = re.compile(
    r"\b(tiger|lion|leopard|cheetah|jaguar|lynx|bobcat|cougar|puma|panther|"
    r"ocelot|serval|wildcat|catamount|wolf|fox|bear|hyena|jackal|otter|"
    r"weasel|mink|skunk|raccoon|deer|elk|moose|boar|monkey|ape|gorilla|"
    r"chimpanzee|orangutan|baboon|marmoset|tamarin|hare|squirrel|beaver|"
    r"porcupine|shark|snake|lizard)\b",
    re.IGNORECASE,
)

# ImageNet normalization used by MobileNetV2-style models.
_MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
_STD = np.array([0.229, 0.224, 0.225], dtype=np.float32)


@dataclass(frozen=True)
class Classification:
    is_pet: bool
    confidence: float
    label: str


def label_is_pet(label: str) -> bool:
    """True when an ImageNet label looks like a common household pet."""
    if WILD_PATTERNS.search(label):
        return False
    return bool(PET_PATTERNS.search(label))


def _load_labels(path: str) -> list[str]:
    with open(path, encoding="utf-8") as f:
        return [line.strip() for line in f if line.strip()]


class PetClassifier:
    def __init__(
        self,
        model_path: str = DEFAULT_MODEL_PATH,
        labels_path: str = DEFAULT_LABELS_PATH,
    ):
        import onnxruntime as ort  # optional dependency (requirements-classifier.txt)

        self._session = ort.InferenceSession(
            model_path, providers=["CPUExecutionProvider"]
        )
        self._input_name = self._session.get_inputs()[0].name
        shape = self._session.get_inputs()[0].shape  # [1, 3, H, W]
        self._input_h = int(shape[2]) if isinstance(shape[2], int) else 224
        self._input_w = int(shape[3]) if isinstance(shape[3], int) else 224

        labels = _load_labels(labels_path)
        # Some ImageNet models include a background class at index 0.
        self._labels = labels

    def _label_of(self, index: int) -> str:
        if 0 <= index < len(self._labels):
            return self._labels[index]
        return f"class_{index}"

    def classify_rgb(
        self,
        crop_rgb: np.ndarray,
        min_confidence: float = DEFAULT_MIN_CONFIDENCE,
    ) -> Classification:
        """Classify an HxWx3 RGB crop; returns what the moving blob probably is."""
        from PIL import Image

        img = Image.fromarray(crop_rgb.astype("uint8"), mode="RGB").resize(
            (self._input_w, self._input_h), Image.Resampling.BILINEAR
        )
        x = np.asarray(img, dtype=np.float32) / 255.0
        x = (x - _MEAN) / _STD
        x = np.ascontiguousarray(x.transpose(2, 0, 1)[None])  # NCHW

        outputs = self._session.run(None, {self._input_name: x})[0][0]
        outputs = np.asarray(outputs, dtype=np.float32)
        # Accept both probability and logit outputs.
        if float(outputs.min()) < 0 or abs(float(outputs.sum()) - 1.0) > 0.05:
            e = np.exp(outputs - outputs.max())
            outputs = e / e.sum()

        top = np.argsort(outputs)[::-1][:TOP_K]
        top_label = self._label_of(int(top[0]))
        best = Classification(
            is_pet=False, confidence=float(outputs[top[0]]), label=top_label
        )
        for i in top:
            label = self._label_of(int(i))
            if label_is_pet(label):
                confidence = float(outputs[i])
                if confidence >= min_confidence:
                    return Classification(True, confidence, label)
        return best


def load_classifier(
    model_path: str = DEFAULT_MODEL_PATH,
    labels_path: str = DEFAULT_LABELS_PATH,
):
    """Return a PetClassifier, or None when no usable model is available."""
    if not (os.path.exists(model_path) and os.path.exists(labels_path)):
        return None
    try:
        return PetClassifier(model_path, labels_path)
    except Exception as e:  # pragma: no cover - depends on local model files
        print(f"Vision tier 3: failed to load classifier: {e}", flush=True)
        return None
