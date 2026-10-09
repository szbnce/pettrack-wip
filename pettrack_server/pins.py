"""Pinned clips — the ones the retention sweep must never eat.

The pin list is a small JSON file next to the footage itself, so it moves
with the clips it protects and `health.prune_replays` can read it without
touching the database. A pin is absolute: retention and disk pressure both
look the other way.
"""
import json
import os

PINS_FILENAME = ".pinned.json"


def _path(folder: str = "replays") -> str:
    return os.path.join(folder, PINS_FILENAME)


def load_pins(folder: str = "replays") -> set:
    """The pinned clip names. A missing or corrupt list is simply empty."""
    try:
        with open(_path(folder), encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError, ValueError):
        return set()
    if not isinstance(data, list):
        return set()
    return {str(name) for name in data}


def save_pins(names: set, folder: str = "replays") -> None:
    os.makedirs(folder, exist_ok=True)
    with open(_path(folder), "w", encoding="utf-8") as f:
        json.dump(sorted(names), f, indent=2)
        f.write("\n")


def pin(filename: str, folder: str = "replays") -> set:
    names = load_pins(folder)
    names.add(filename)
    save_pins(names, folder)
    return names


def unpin(filename: str, folder: str = "replays") -> set:
    names = load_pins(folder)
    names.discard(filename)
    save_pins(names, folder)
    return names


def is_pinned(filename: str, pinned: set | None = None, folder: str = "replays") -> bool:
    if pinned is None:
        pinned = load_pins(folder)
    return filename in pinned
