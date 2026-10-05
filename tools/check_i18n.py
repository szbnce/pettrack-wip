#!/usr/bin/env python3
"""i18n parity checker for PetTrack.

Keeps every pettrack_app locale in sync with the en template:
  pettrack_app/lib/l10n/app_en.arb  <->  app_{de,hu,it,ja,ko,zh}.arb

Errors (exit code 1):
  * keys present in en but missing from a locale (or extra keys in a locale)
  * keys referenced in Dart code (l10n.<key>) but missing from the dictionary
  * duplicate keys inside a single file
  * mismatched {placeholders} between en and a locale's message
  * @key placeholder metadata that doesn't match its message
  * empty message strings

Warnings (reported, but exit code 0):
  * keys not referenced anywhere in the app's source code

Usage: python3 tools/check_i18n.py
"""

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

L10N_DIR = REPO_ROOT / "pettrack_app/lib/l10n"
SOURCE_DIRS = [REPO_ROOT / "pettrack_app/lib"]
LOCALES = ["de", "hu", "it", "ja", "ko", "zh"]

# Key accesses in Dart: l10n.someKey (also covers AppLocalizations variables
# named l10n; generated classes are excluded from the scan).
DART_USAGE_RE = re.compile(r"\bl10n\.([A-Za-z_][A-Za-z0-9_]*)")

PLACEHOLDER_RE = re.compile(r"\{(\w+)\}")
GENERATED_DIR_NAME = "l10n"  # skip generated files when scanning for key usage


class DuplicateKeyError(ValueError):
    pass


def _no_dupes(pairs):
    obj = {}
    for key, value in pairs:
        if key in obj:
            raise DuplicateKeyError(f"duplicate key: {key!r}")
        obj[key] = value
    return obj


def load_json(path):
    """Load JSON/arb, failing on duplicate keys. Returns (data, error)."""
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f, object_pairs_hook=_no_dupes), None
    except DuplicateKeyError as e:
        return None, str(e)
    except (OSError, json.JSONDecodeError) as e:
        return None, str(e)


def flatten(data, prefix=""):
    """Flatten nested dicts to dotted keys. Non-dict values become leaf entries."""
    flat = {}
    for key, value in data.items():
        if key.startswith("@"):
            continue  # arb placeholder metadata, checked separately
        name = f"{prefix}{key}"
        if isinstance(value, dict):
            flat.update(flatten(value, f"{name}."))
        else:
            flat[name] = value
    return flat


def source_blob(source_dirs):
    """Concatenate non-generated source files for key usage lookups."""
    blob = []
    for src_dir in source_dirs:
        if not src_dir.exists():
            continue
        for path in src_dir.rglob("*"):
            if not path.is_file():
                continue
            if GENERATED_DIR_NAME in path.parts and path.suffix == ".dart":
                continue  # generated l10n classes reference every key
            if path.suffix != ".dart":
                continue
            blob.append(path.read_text(encoding="utf-8"))
    return "\n".join(blob)


def key_is_used(key, blob):
    """True when the key name appears in source (l10n.<key> style)."""
    top = key.split(".")[0]
    return re.search(r"\b" + re.escape(top) + r"\b", blob) is not None


def check_locale(label, en_flat, loc_flat, en_file, loc_file):
    errors = []

    missing = sorted(set(en_flat) - set(loc_flat))
    extra = sorted(set(loc_flat) - set(en_flat))
    for key in missing:
        errors.append(f"{label}: key only in en: {key}")
    for key in extra:
        errors.append(f"{label}: key only in {loc_file.name}: {key}")

    for key in sorted(set(en_flat) & set(loc_flat)):
        en_val, loc_val = en_flat[key], loc_flat[key]
        if not str(loc_val).strip():
            errors.append(f"{label}: empty value: {key}")
        en_ph = sorted(PLACEHOLDER_RE.findall(str(en_val)))
        loc_ph = sorted(PLACEHOLDER_RE.findall(str(loc_val)))
        if en_ph != loc_ph:
            errors.append(
                f"{label}: placeholder mismatch in {key}: "
                f"en={en_ph or '[]'} {label}={loc_ph or '[]'}"
            )
    return errors


def check_metadata(en, en_flat, label="en"):
    errors = []
    for key, meta in en.items():
        if not key.startswith("@") or not isinstance(meta, dict):
            continue
        message_key = key[1:]
        if message_key not in en_flat:
            errors.append(f"{label}: metadata without message: {key}")
            continue
        declared = sorted(meta.get("placeholders", {}).keys())
        actual = sorted(PLACEHOLDER_RE.findall(str(en_flat[message_key])))
        if declared != actual:
            errors.append(
                f"{label}: metadata mismatch in {key}: declared={declared or '[]'} "
                f"message={actual or '[]'}"
            )
    return errors


def check_usage(en, en_flat, blob):
    errors = []
    warnings = []

    top_level = {k for k in en if not k.startswith("@")}
    seen = set()
    for match in DART_USAGE_RE.finditer(blob):
        key = match.group(1)
        if key in seen:
            continue
        seen.add(key)
        if key not in top_level:
            errors.append(f"code references undefined key: l10n.{key}")

    for key in sorted(en_flat):
        if not key_is_used(key, blob):
            warnings.append(f"key not referenced in code: {key}")
    return errors, warnings


def main():
    en_path = L10N_DIR / "app_en.arb"
    errors = []
    warnings = []

    en, en_err = load_json(en_path)
    if en_err:
        print(f"ERROR: {en_path.name}: {en_err}")
        return 1

    en_flat = flatten(en)
    for key, val in en_flat.items():
        if not str(val).strip():
            errors.append(f"en: empty value: {key}")
    errors += check_metadata(en, en_flat)

    for locale in LOCALES:
        loc_path = L10N_DIR / f"app_{locale}.arb"
        loc, loc_err = load_json(loc_path)
        if loc_err:
            errors.append(f"{loc_path.name}: {loc_err}")
            continue
        loc_flat = flatten(loc)
        errors += check_locale(locale, en_flat, loc_flat, en_path, loc_path)
        errors += check_metadata(loc, loc_flat, label=locale)

    blob = source_blob(SOURCE_DIRS)
    usage_errors, warnings = check_usage(en, en_flat, blob)
    errors += usage_errors

    print(f"== pettrack_app ({', '.join(['en'] + LOCALES)}) ==")
    if not errors and not warnings:
        print("   OK: all locales in sync, no warnings")
    for msg in errors:
        print(f"   ERROR: {msg}")
    for msg in warnings:
        print(f"   warn:  {msg}")
    print()

    if errors:
        print(f"FAILED: {len(errors)} error(s)")
        return 1
    print("PASSED: all translation files are in sync")
    return 0


if __name__ == "__main__":
    sys.exit(main())
