"""Runtime settings that survive a restart (kept in .env, like the secret).

Only operational knobs live here — the kind a self-hosters' maintenance
card exposes, not app preferences."""
import json
import os
from datetime import datetime
from urllib.parse import urlparse

import arming
from env_store import safe_set_key

# How long replays stay on disk before pruning drops them. 14 days is long
# enough to scroll back through a fortnight of activity and short enough
# that a busy camera cannot fill a small disk.
DEFAULT_REPLAY_RETENTION_DAYS = 14
MIN_REPLAY_RETENTION_DAYS = 1
MAX_REPLAY_RETENTION_DAYS = 365

# Languages the remote-alert bridge can phrase its messages in. The app
# saves its interface language here so pushes read like the app does.
SUPPORTED_NTFY_LANGS = ("en", "de", "hu", "it", "ja", "ko", "zh")

# The "don't tell me between 23:00 and 7:00" window, mirrored from the
# app so remote alerts obey the same rule. Minutes after midnight;
# from == to is an empty window and the window may wrap midnight.
DEFAULT_QUIET_FROM = 23 * 60
DEFAULT_QUIET_TO = 7 * 60


class NtfyUrlError(ValueError):
    """The topic URL is not something we can publish to."""


def _set_env(key: str, value: str) -> None:
    """Persist to the settings file and the live process environment.

    safe_set_key handles a `.env` that is not writable (or not even a
    file) and mirrors into the environment either way, so a saved setting
    takes effect now even on a box that has nowhere to keep it."""
    safe_set_key(key, value)


def get_replay_retention_days() -> int:
    raw = os.getenv("PETTRACK_REPLAY_RETENTION_DAYS", "")
    try:
        days = int(raw)
    except ValueError:
        return DEFAULT_REPLAY_RETENTION_DAYS
    return max(MIN_REPLAY_RETENTION_DAYS, min(MAX_REPLAY_RETENTION_DAYS, days))


def set_replay_retention_days(days: int) -> int:
    days = max(MIN_REPLAY_RETENTION_DAYS, min(MAX_REPLAY_RETENTION_DAYS, int(days)))
    _set_env("PETTRACK_REPLAY_RETENTION_DAYS", str(days))
    return days


# --- remote alerts (ntfy bridge) --------------------------------------------


def get_ntfy_url() -> str:
    return os.getenv("PETTRACK_NTFY_URL", "").strip()


def set_ntfy_url(url: str) -> str:
    """Store the ntfy topic URL; an empty string turns remote alerts off.

    Publishing is a plain HTTP POST to the topic URL, so anything
    ntfy-shaped works: ntfy.sh, a self-hosted ntfy, even a webhook that
    accepts POSTs. Raises NtfyUrlError for anything unpublishable."""
    url = url.strip()
    if url:
        parsed = urlparse(url)
        if parsed.scheme not in ("http", "https") or not parsed.netloc:
            raise NtfyUrlError(url)
    _set_env("PETTRACK_NTFY_URL", url)
    return url


def get_ntfy_token() -> str:
    return os.getenv("PETTRACK_NTFY_TOKEN", "").strip()


def set_ntfy_token(token: str) -> str:
    """Access token for protected ntfy topics (optional)."""
    token = token.strip()
    _set_env("PETTRACK_NTFY_TOKEN", token)
    return token


def get_ntfy_lang() -> str:
    lang = os.getenv("PETTRACK_NTFY_LANG", "en").strip()
    return lang if lang in SUPPORTED_NTFY_LANGS else "en"


def set_ntfy_lang(lang: str) -> str:
    if lang not in SUPPORTED_NTFY_LANGS:
        raise ValueError(lang)
    _set_env("PETTRACK_NTFY_LANG", lang)
    return lang


def get_quiet_hours() -> tuple[bool, int, int]:
    def minutes(name: str, default: int) -> int:
        try:
            value = int(os.getenv(name, ""))
        except ValueError:
            return default
        return max(0, min(1439, value))

    enabled = os.getenv("PETTRACK_QUIET_ENABLED", "").strip() in ("1", "true", "True")
    return (
        enabled,
        minutes("PETTRACK_QUIET_FROM", DEFAULT_QUIET_FROM),
        minutes("PETTRACK_QUIET_TO", DEFAULT_QUIET_TO),
    )


def set_quiet_hours(enabled: bool, from_minutes: int, to_minutes: int) -> tuple[bool, int, int]:
    from_minutes = max(0, min(1439, int(from_minutes)))
    to_minutes = max(0, min(1439, int(to_minutes)))
    _set_env("PETTRACK_QUIET_ENABLED", "1" if enabled else "0")
    _set_env("PETTRACK_QUIET_FROM", str(from_minutes))
    _set_env("PETTRACK_QUIET_TO", str(to_minutes))
    return enabled, from_minutes, to_minutes


def is_quiet_now(now: datetime | None = None) -> bool:
    """Same window maths as the app's isWithinQuietHours()."""
    enabled, start, end = get_quiet_hours()
    if not enabled:
        return False
    now = now or datetime.now()
    minutes = now.hour * 60 + now.minute
    if start == end:
        return False  # empty window
    if start < end:
        return start <= minutes < end
    return minutes >= start or minutes < end  # wraps midnight


# --- arming: only watch when it should ---------------------------------------
# "On" is the historical behaviour — always recording. "Schedule" arms the
# camera for the weekly windows in PETTRACK_ARMING_SCHEDULE (JSON list of
# {days, from_min, to_min}); "off" never records motion or sound. Live
# viewing keeps working either way — arming is about evidence, not access.

DEFAULT_ARMING_MODE = "on"


def get_arming_mode() -> str:
    mode = os.getenv("PETTRACK_ARMING_MODE", DEFAULT_ARMING_MODE).strip().lower()
    return mode if mode in arming.ARMING_MODES else DEFAULT_ARMING_MODE


def set_arming_mode(mode: str) -> str:
    mode = mode.strip().lower()
    if mode not in arming.ARMING_MODES:
        raise ValueError(f"unknown arming mode: {mode!r}")
    _set_env("PETTRACK_ARMING_MODE", mode)
    return mode


def get_arming_schedule() -> list[dict]:
    raw = os.getenv("PETTRACK_ARMING_SCHEDULE", "").strip()
    if not raw:
        return []
    try:
        return arming.normalize_schedule(json.loads(raw))
    except ValueError:
        return []


def set_arming_schedule(schedule: list) -> list[dict]:
    clean = arming.normalize_schedule(schedule)
    _set_env("PETTRACK_ARMING_SCHEDULE", json.dumps(clean, separators=(",", ":")))
    return clean


def is_armed_now(now: datetime | None = None) -> bool:
    """The gate the recording pipeline asks on every frame."""
    now = now or datetime.now()
    return arming.is_armed(get_arming_mode(), get_arming_schedule(), now)
