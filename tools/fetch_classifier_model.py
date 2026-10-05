#!/usr/bin/env python3
"""Download the optional tier-3 pet classifier (ONNX) into pettrack_server/models/.

The model is not committed to the repo (~14 MB). Run this once:

    python3 tools/fetch_classifier_model.py

Requires onnxruntime at runtime only:
    pip install -r pettrack_server/requirements-classifier.txt
"""
import os
import sys
import urllib.request

MODEL_URL = "https://github.com/onnx/models/raw/main/validated/vision/classification/mobilenet/model/mobilenetv2-12.onnx"
LABELS_URL = "https://raw.githubusercontent.com/onnx/models/main/validated/vision/classification/synset.txt"

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELS_DIR = os.path.join(ROOT, "pettrack_server", "models")
MODEL_PATH = os.path.join(MODELS_DIR, "classifier.onnx")
LABELS_PATH = os.path.join(MODELS_DIR, "imagenet_classes.txt")


def fetch(url: str, dest: str):
    if os.path.exists(dest) and os.path.getsize(dest) > 0:
        print(f"Already present: {dest}")
        return
    print(f"Downloading {url} ...")
    with urllib.request.urlopen(url, timeout=120) as r, open(dest, "wb") as f:
        data = r.read()
        f.write(data)
    print(f"  -> {dest} ({os.path.getsize(dest) / 1e6:.1f} MB)")


def main() -> int:
    os.makedirs(MODELS_DIR, exist_ok=True)
    try:
        fetch(MODEL_URL, MODEL_PATH)
        fetch(LABELS_URL, LABELS_PATH)
    except Exception as e:
        print(f"Download failed: {e}", file=sys.stderr)
        return 1
    print("\nDone. Install the runtime with:")
    print("    pip install -r pettrack_server/requirements-classifier.txt")
    print("The server picks the model up automatically (PETTRACK_CLASSIFIER=auto).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
