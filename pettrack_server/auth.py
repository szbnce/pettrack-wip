"""Tokens, sessions and login lockout.

Three kinds of signed JWTs (HS256 with the master secret):

- full access: {"auth": "ok", "sid": <session>} — the whole API
- monitor:     {"auth": "monitor", "sid": <session>} — frame upload, monitor
  status and sound reports only
- media:       {"auth": "media", "file": <name>} — one replay file, for URLs

Access tokens live one hour. A rotating refresh token (kept hashed in the
database) mints new ones; presenting a rotated or revoked refresh token is
treated as theft and kills the whole session family. Logging out revokes the
family, which also invalidates the access tokens carrying its sid. The raw
master secret is still accepted everywhere for QR provisioning and scripts.
"""
import base64
import hashlib
import hmac
import os
import secrets
import time
import uuid

import aiosqlite
import jwt
from cryptography.fernet import Fernet

from database import DB_PATH
from env_store import load_persistent_env, safe_set_key

load_persistent_env()

SECRET_TOKEN = os.getenv("PETTRACK_SECRET")
if not SECRET_TOKEN:
    print("No secret found! Generating a new ultra-secure 64-char token...")
    new_secret = secrets.token_urlsafe(48)
    # Never fatal: a settings file we cannot write is not worth a dead
    # server — but the secret has to survive a restart, or every session,
    # PIN and encrypted record dies with this process.
    if not safe_set_key("PETTRACK_SECRET", new_secret):
        print(
            "auth: WARNING — the secret could not be saved anywhere. "
            "Every restart will look like a new install. Set PETTRACK_SECRET "
            "in the environment (or PETTRACK_SECRET_FILE to a writable path).",
            flush=True,
        )
    SECRET_TOKEN = new_secret


def get_fernet_key(secret: str) -> bytes:
    digest = hashlib.sha256(secret.encode()).digest()
    return base64.urlsafe_b64encode(digest)


fernet = Fernet(get_fernet_key(SECRET_TOKEN))

ACCESS_TOKEN_TTL_SECONDS = 3600
REFRESH_TOKEN_TTL_SECONDS = 90 * 86400
MEDIA_TOKEN_TTL_SECONDS = 3600
# A "share link" to one clip, for someone on the LAN who has no session:
# a week, still scoped to that single file.
SHARE_LINK_TTL_SECONDS = 7 * 86400

# PIN/secret login: five failures lock the caller out for five minutes.
# The counters live in the database, so a restart does not clear them.
LOCKOUT_ATTEMPTS = 5
LOCKOUT_WINDOW_SECONDS = 300

# All a monitor token may touch. WebSockets are checked in main.py.
MONITOR_PATHS = ("/api/frame/web", "/api/monitor/update", "/api/monitor/sound")


# --- tokens ------------------------------------------------------------------

def mint_access_token(session_id: str, scope: str = "full") -> str:
    return jwt.encode(
        {
            "auth": "monitor" if scope == "monitor" else "ok",
            "sid": session_id,
            "jti": uuid.uuid4().hex,
            "exp": time.time() + ACCESS_TOKEN_TTL_SECONDS,
        },
        SECRET_TOKEN,
        algorithm="HS256",
    )


def mint_media_token(filename: str, ttl_seconds: int = MEDIA_TOKEN_TTL_SECONDS) -> str:
    """Token scoped to a single replay file, safe for URLs.

    Short-lived by default (player links); a share link passes
    SHARE_LINK_TTL_SECONDS so it can travel to someone without a session."""
    return jwt.encode(
        {"auth": "media", "file": filename, "exp": time.time() + ttl_seconds},
        SECRET_TOKEN,
        algorithm="HS256",
    )


def token_valid(req_token: str) -> bool:
    """Accepts a signed JWT or the raw secret (constant-time compare)."""
    if not req_token:
        return False
    try:
        jwt.decode(req_token, SECRET_TOKEN, algorithms=["HS256"])
        return True
    except jwt.PyJWTError:
        return hmac.compare_digest(req_token, SECRET_TOKEN)


def token_payload(req_token: str) -> dict | None:
    """Claims of a signed JWT, or None for the raw secret and other junk."""
    try:
        return jwt.decode(req_token, SECRET_TOKEN, algorithms=["HS256"])
    except jwt.PyJWTError:
        return None


def scope_allows(payload: dict | None, path: str) -> bool:
    """Raw secret and full tokens go everywhere; media and monitor tokens are
    fenced into the paths they were minted for."""
    if payload is None:  # raw master secret
        return True
    kind = payload.get("auth")
    if kind == "media":
        return path.startswith("/api/replays/")
    if kind == "monitor":
        return path.startswith(MONITOR_PATHS)
    return True


# --- sessions ----------------------------------------------------------------

def _hash(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


async def create_session(scope: str = "full") -> dict:
    if scope not in ("full", "monitor"):
        scope = "full"
    session_id = uuid.uuid4().hex
    family = uuid.uuid4().hex
    refresh = secrets.token_urlsafe(32)
    now = time.time()
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            "INSERT INTO auth_sessions (id, family, scope, refresh_hash, created_at, expires_at)"
            " VALUES (?, ?, ?, ?, ?, ?)",
            (session_id, family, scope, _hash(refresh), now, now + REFRESH_TOKEN_TTL_SECONDS),
        )
        await db.commit()
    return {
        "token": mint_access_token(session_id, scope),
        "refresh_token": refresh,
        "expires_in": ACCESS_TOKEN_TTL_SECONDS,
        "session_id": session_id,
        "family": family,
        "scope": scope,
    }


async def rotate_session(refresh_token: str) -> dict | None:
    """Exchange a refresh token for a fresh pair. A token that was already
    rotated or revoked is treated as theft — the whole family dies."""
    now = time.time()
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cur = await db.execute(
            "SELECT * FROM auth_sessions WHERE refresh_hash = ?", (_hash(refresh_token),)
        )
        row = await cur.fetchone()
        if row is None:
            return None
        if row["revoked_at"] is not None:
            await _revoke_family(db, row["family"])
            await db.commit()
            return None
        if row["expires_at"] <= now:
            return None
        await db.execute(
            "UPDATE auth_sessions SET revoked_at = ? WHERE id = ?", (now, row["id"])
        )
        session_id = uuid.uuid4().hex
        refresh = secrets.token_urlsafe(32)
        await db.execute(
            "INSERT INTO auth_sessions (id, family, scope, refresh_hash, created_at, expires_at)"
            " VALUES (?, ?, ?, ?, ?, ?)",
            (session_id, row["family"], row["scope"], _hash(refresh), now,
             now + REFRESH_TOKEN_TTL_SECONDS),
        )
        await db.commit()
    return {
        "token": mint_access_token(session_id, row["scope"]),
        "refresh_token": refresh,
        "expires_in": ACCESS_TOKEN_TTL_SECONDS,
        "session_id": session_id,
        "family": row["family"],
        "scope": row["scope"],
    }


async def revoke_session(refresh_token: str | None = None, session_id: str | None = None) -> bool:
    """Kill the family behind a refresh token or an access token's sid."""
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        if refresh_token:
            cur = await db.execute(
                "SELECT family FROM auth_sessions WHERE refresh_hash = ?",
                (_hash(refresh_token),),
            )
        elif session_id:
            cur = await db.execute(
                "SELECT family FROM auth_sessions WHERE id = ?", (session_id,)
            )
        else:
            return False
        row = await cur.fetchone()
        if row is None:
            return False
        await _revoke_family(db, row["family"])
        await db.commit()
        return True


async def _revoke_family(db, family: str) -> None:
    await db.execute(
        "UPDATE auth_sessions SET revoked_at = ? WHERE family = ? AND revoked_at IS NULL",
        (time.time(), family),
    )


async def session_active(session_id: str) -> bool:
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cur = await db.execute(
            "SELECT revoked_at, expires_at FROM auth_sessions WHERE id = ?", (session_id,)
        )
        row = await cur.fetchone()
    return row is not None and row["revoked_at"] is None and row["expires_at"] > time.time()


# --- login lockout (persistent) ----------------------------------------------

async def is_locked_out(ip: str, now: float | None = None) -> bool:
    now = now or time.time()
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cur = await db.execute(
            "SELECT attempts, last_attempt FROM auth_failures WHERE ip = ?", (ip,)
        )
        row = await cur.fetchone()
    return (
        row is not None
        and row["attempts"] >= LOCKOUT_ATTEMPTS
        and now - row["last_attempt"] <= LOCKOUT_WINDOW_SECONDS
    )


async def record_failure(ip: str) -> None:
    now = time.time()
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cur = await db.execute(
            "SELECT attempts, last_attempt FROM auth_failures WHERE ip = ?", (ip,)
        )
        row = await cur.fetchone()
        if row is None or now - row["last_attempt"] > LOCKOUT_WINDOW_SECONDS:
            attempts = 1
        else:
            attempts = row["attempts"] + 1
        await db.execute(
            "INSERT INTO auth_failures (ip, attempts, last_attempt) VALUES (?, ?, ?)"
            " ON CONFLICT(ip) DO UPDATE SET"
            " attempts = excluded.attempts, last_attempt = excluded.last_attempt",
            (ip, attempts, now),
        )
        await db.commit()


async def clear_failures(ip: str) -> None:
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("DELETE FROM auth_failures WHERE ip = ?", (ip,))
        await db.commit()


async def clear_all_failures() -> None:
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("DELETE FROM auth_failures")
        await db.commit()


async def failure_count(ip: str) -> int:
    async with aiosqlite.connect(DB_PATH) as db:
        cur = await db.execute(
            "SELECT attempts FROM auth_failures WHERE ip = ?", (ip,)
        )
        row = await cur.fetchone()
    return row[0] if row else 0
