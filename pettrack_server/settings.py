"""Runtime settings that survive a restart (kept in .env, like the secret).

Only operational knobs live here — the kind a self-hosters' maintenance
card exposes, not app preferences."""
import os

from dotenv import set_key

# How long replays stay on disk before pruning drops them. 14 days is long
# enough to scroll back through a fortnight of activity and short enough
# that a busy camera cannot fill a small disk.
DEFAULT_REPLAY_RETENTION_DAYS = 14
MIN_REPLAY_RETENTION_DAYS = 1
MAX_REPLAY_RETENTION_DAYS = 365


def get_replay_retention_days() -> int:
    raw = os.getenv("PETTRACK_REPLAY_RETENTION_DAYS", "")
    try:
        days = int(raw)
    except ValueError:
        return DEFAULT_REPLAY_RETENTION_DAYS
    return max(MIN_REPLAY_RETENTION_DAYS, min(MAX_REPLAY_RETENTION_DAYS, days))


def set_replay_retention_days(days: int) -> int:
    days = max(MIN_REPLAY_RETENTION_DAYS, min(MAX_REPLAY_RETENTION_DAYS, int(days)))
    try:
        set_key(".env", "PETTRACK_REPLAY_RETENTION_DAYS", str(days))
    except OSError:
        # Fallback for Docker bind mounts where os.replace fails.
        with open(".env", "a") as f:
            f.write(f"\nPETTRACK_REPLAY_RETENTION_DAYS={days}\n")
    os.environ["PETTRACK_REPLAY_RETENTION_DAYS"] = str(days)
    return days
