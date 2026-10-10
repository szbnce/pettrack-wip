"""Writing the settings that survive a restart — without letting the file
we chose take the server down with it.

`.env` is the usual home. Deployments mount all sorts of things over it: a
Docker bind mount, a Kubernetes secret volume, an over-eager `mkdir .env`.
Every writer in this project used to assume `.env` was a file, so the first
write crashed the boot — and the "fallback" reopened the same directory and
crashed again. On the secret that was worse than a dead server: every crash
loop minted a *new* master secret, which is the same as throwing away every
session, PIN and piece of encrypted state.

Writes therefore go through :func:`safe_set_key`, which takes no for an
answer and falls back to a sibling ``pettrack.env``. Reads come back through
:func:`load_persistent_env`, which knows about both. Nothing in here raises.
"""
import os

from dotenv import load_dotenv, set_key

# Where a setting lands when `.env` is not a home for settings. Same shape
# as `.env` (KEY=VALUE lines), so it is obvious what it is and easy to move.
SIDECAR_NAME = "pettrack.env"


def _is_directory(path: str) -> bool:
    return bool(path) and os.path.isdir(path)


def sidecar_path() -> str:
    """Where the fallback settings file goes.

    A Docker bind mount of `./…/.env:/app/.env` that had no host file is
    created by Docker as a *directory* — and it is a mounted volume, so it
    is the one place that survives a rebuild. Put the sidecar inside it.
    Otherwise use a sibling file beside the code.
    """
    return os.path.join(".env", SIDECAR_NAME) if _is_directory(".env") else SIDECAR_NAME


def _write_key(path: str, key: str, value: str) -> bool:
    """One attempt at one file. Never raises."""
    if _is_directory(path):
        print(f"env store: {path} is a directory, not a settings file — skipping", flush=True)
        return False
    try:
        set_key(path, key, value)
        return True
    except (OSError, ValueError) as e:
        # The Docker bind mount where os.replace fails: appending sometimes
        # still gets in.
        print(f"env store: could not rewrite {path}: {e}", flush=True)
    try:
        with open(path, "a", encoding="utf-8") as f:
            f.write(f"\n{key}={value}\n")
        return True
    except OSError as e:
        print(f"env store: could not append to {path}: {e}", flush=True)
        return False


def safe_set_key(key: str, value: str) -> bool:
    """Persist one setting and mirror it into the live process.

    Returns True when it landed on disk somewhere. The environment is
    updated either way — the running server keeps the new value even if
    this box has nowhere to write it.
    """
    os.environ[key] = value
    named = os.getenv("PETTRACK_ENV_FILE", "").strip()
    for path in (named, ".env", sidecar_path()):
        if not path:
            continue
        if _write_key(path, key, value):
            return True
    print(
        f"env store: nowhere to keep {key} — it lives for this run only",
        flush=True,
    )
    return False


def _parse_env_file(path: str) -> dict[str, str]:
    """KEY=VALUE lines, the dotenv subset we write ourselves."""
    values: dict[str, str] = {}
    try:
        with open(path, encoding="utf-8") as f:
            lines = f.readlines()
    except OSError as e:
        print(f"env store: could not read {path}: {e}", flush=True)
        return values
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, raw = line.partition("=")
        key = key.strip()
        value = raw.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
            value = value[1:-1]
        if key:
            values[key] = value
    return values


def load_persistent_env() -> None:
    """Bring back what a previous run saved.

    Precedence: whatever the container already set is the operator's word
    and wins; then the sidecar (where a write fell back to, so it is the
    newer truth); then `.env`.

    The path is pinned: bare ``load_dotenv()`` walks up the tree and would
    quietly adopt a *parent* directory's ``.env``, which is somebody else's
    secrets. A directory named ``.env`` is not a settings file — it loads
    nothing here and the sidecar takes over, which is the whole point.
    """
    operator = set(os.environ)
    load_dotenv(".env", override=False)
    sidecar = sidecar_path()
    if os.path.isfile(sidecar):
        for key, value in _parse_env_file(sidecar).items():
            if key not in operator:
                os.environ[key] = value
