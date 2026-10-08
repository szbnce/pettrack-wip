"""Arming: the server watches only when it should.

Three modes — always on (the old behaviour), a weekly schedule, or off.
This module is pure logic: no env, no IO, just window maths the settings
layer and the tests can both lean on.
"""
from datetime import datetime

ARMING_MODE_ON = "on"
ARMING_MODE_OFF = "off"
ARMING_MODE_SCHEDULE = "schedule"
ARMING_MODES = (ARMING_MODE_ON, ARMING_MODE_OFF, ARMING_MODE_SCHEDULE)

MAX_WINDOWS = 7
MINUTES_PER_DAY = 24 * 60


def normalize_window(raw) -> dict | None:
    """One schedule window, cleaned up — or None if it is junk.

    Days are ISO weekdays (1 = Monday .. 7 = Sunday); times are minutes
    since midnight. Anything that does not parse that way is dropped
    rather than guessed at.
    """
    if not isinstance(raw, dict):
        return None
    days_raw = raw.get("days")
    if not isinstance(days_raw, (list, tuple)):
        return None
    days = set()
    for raw_day in days_raw:
        if isinstance(raw_day, bool) or not isinstance(raw_day, (int, float)):
            continue
        day = int(raw_day)
        if 1 <= day <= 7:
            days.add(day)
    if not days:
        return None
    try:
        from_min = int(raw.get("from_min"))
        to_min = int(raw.get("to_min"))
    except (TypeError, ValueError):
        return None
    if not (0 <= from_min < MINUTES_PER_DAY and 0 <= to_min < MINUTES_PER_DAY):
        return None
    return {"days": sorted(days), "from_min": from_min, "to_min": to_min}


def normalize_schedule(raw) -> list[dict]:
    """The full schedule: junk windows dropped, capped at MAX_WINDOWS."""
    if not isinstance(raw, (list, tuple)):
        return []
    out = []
    for entry in raw:
        window = normalize_window(entry)
        if window is not None:
            out.append(window)
        if len(out) >= MAX_WINDOWS:
            break
    return out


def window_covers(window: dict, now: datetime) -> bool:
    """Does this window cover `now`?

    A window is [from_min, to_min) on its listed days. from == to is an
    empty window. When the window wraps past midnight (22:00–06:00), the
    tail after midnight belongs to *yesterday's* listed day — you say
    "Monday night" and mean the night that starts on Monday.
    """
    start, end = window["from_min"], window["to_min"]
    if start == end:
        return False  # empty window
    minutes = now.hour * 60 + now.minute
    days = window.get("days", ())
    if start < end:
        return now.isoweekday() in days and start <= minutes < end
    # Wrapping window: the evening half is today's, the tail after
    # midnight is yesterday's night ("Monday night" runs into Tuesday).
    return (now.isoweekday() in days and minutes >= start) or (
        (now.isoweekday() - 1 or 7) in days and minutes < end
    )


def is_armed(mode: str, schedule: list[dict], now: datetime) -> bool:
    """The one question the recording pipeline asks every frame."""
    if mode == ARMING_MODE_ON:
        return True
    if mode == ARMING_MODE_SCHEDULE:
        return any(window_covers(w, now) for w in schedule)
    return False
