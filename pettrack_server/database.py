# pyrefly: ignore [missing-import]
import aiosqlite
import json
import time

import notify

DB_PATH = "pettrack.db"

async def init_db():
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("""
        CREATE TABLE IF NOT EXISTS events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp REAL NOT NULL,
            event_type TEXT NOT NULL,
            zone_name TEXT,
            details TEXT
            )
        """)
        await db.execute("""
            CREATE TABLE IF NOT EXISTS zones (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                polygon TEXT NOT NULL,
                type TEXT DEFAULT 'safe'
                )
        """)
        await db.execute("""
            CREATE TABLE IF NOT EXISTS pets (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                type TEXT NOT NULL,
                profile_pic TEXT
                )
        """)
        await db.execute("""
            CREATE TABLE IF NOT EXISTS medical_data (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                medications TEXT DEFAULT '[]',
                vaccines TEXT DEFAULT '[]'
                )
        """)
        await db.execute("""
            CREATE TABLE IF NOT EXISTS auth_sessions (
                id TEXT PRIMARY KEY,
                family TEXT NOT NULL,
                scope TEXT NOT NULL DEFAULT 'full',
                refresh_hash TEXT NOT NULL UNIQUE,
                created_at REAL NOT NULL,
                expires_at REAL NOT NULL,
                revoked_at REAL
                )
        """)
        await db.execute("""
            CREATE TABLE IF NOT EXISTS auth_failures (
                ip TEXT PRIMARY KEY,
                attempts INTEGER NOT NULL,
                last_attempt REAL NOT NULL
                )
        """)
        await db.execute("""
            CREATE TABLE IF NOT EXISTS event_feedback (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp REAL NOT NULL,
                kind TEXT NOT NULL,
                event_type TEXT,
                zone_name TEXT,
                filename TEXT,
                created_at REAL NOT NULL
                )
        """)
        try:
            await db.execute("ALTER TABLE zones ADD COLUMN type TEXT DEFAULT 'safe'")
        except Exception:
            pass
        await db.commit()
        print("Database initialized!", flush=True)

async def log_event(event_type: str, zone_name: str = None, details: str = None):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            "INSERT INTO events (timestamp, event_type, zone_name, details) VALUES (?, ?, ?, ?)",
            (time.time(), event_type, zone_name, details)
        )
        await db.commit()
    # Remote alerts ride the same funnel. A missing or slow ntfy topic
    # must never cost us the event row written above.
    try:
        await notify.push_event(event_type, zone_name=zone_name, details=details)
    except Exception as e:
        print(f"ntfy bridge: push failed: {e}", flush=True)

async def get_events(limit: int = 50):
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute(
            "SELECT * FROM events ORDER BY timestamp DESC LIMIT ?",
            (limit,)
        )
        rows = await cursor.fetchall()
        return [dict(row) for row in rows]

async def get_events_since(since_ts: float):
    """Every event from [since_ts] on, oldest first — the raw material for
    the activity insights (zone stays are computed by pairing enter/exit)."""
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute(
            "SELECT * FROM events WHERE timestamp >= ? ORDER BY timestamp",
            (since_ts,)
        )
        rows = await cursor.fetchall()
        return [dict(row) for row in rows]

async def get_event_counts_since(since_ts: float):
    """Per-day, per-type event counts for the replay timeline strip.

    Days are bucketed in the server's local time so they line up with the
    daily recap and timelapse, which use the same calendar.
    """
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute(
            "SELECT date(timestamp, 'unixepoch', 'localtime') AS day, "
            "event_type, COUNT(*) AS n FROM events "
            "WHERE timestamp >= ? GROUP BY day, event_type ORDER BY day",
            (since_ts,)
        )
        rows = await cursor.fetchall()
        return [dict(row) for row in rows]

async def get_event_hour_counts(day: str):
    """Per-hour event counts for one calendar day (server-local), for the
    day's density strip. `day` is `YYYY-MM-DD`."""
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute(
            "SELECT strftime('%H', timestamp, 'unixepoch', 'localtime') AS hour, "
            "COUNT(*) AS n FROM events "
            "WHERE date(timestamp, 'unixepoch', 'localtime') = ? "
            "GROUP BY hour ORDER BY hour",
            (day,),
        )
        rows = await cursor.fetchall()
        return [{"hour": int(r["hour"]), "n": int(r["n"])} for r in rows]

async def save_zones(zones_data):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("DELETE FROM zones")
        for zone in zones_data:
            polygon_json = json.dumps([{"x": p.x, "y": p.y} for p in zone.polygon])
            await db.execute(
                "INSERT INTO zones (name, polygon, type) VALUES (?, ?, ?)",
                (zone.name, polygon_json, zone.type)
            )
        await db.commit()

async def get_zones():
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute("SELECT * FROM zones")
        rows = await cursor.fetchall()
        return [{"name": row["name"],"polygon": json.loads(row["polygon"]), "type": dict(row).get("type", "safe")} for row in rows]

async def get_pet():
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute("SELECT * FROM pets ORDER BY id DESC LIMIT 1")
        row = await cursor.fetchone()
        return dict(row) if row else None

async def save_pet(name: str, type: str, profile_pic: str = None):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("DELETE FROM pets")
        await db.execute(
            "INSERT INTO pets (name, type, profile_pic) VALUES (?, ?, ?)",
            (name, type, profile_pic)
        )
        await db.commit()

async def get_medical_data():
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute("SELECT medications, vaccines FROM medical_data ORDER BY id DESC LIMIT 1")
        row = await cursor.fetchone()
        if row:
            return {"medications": json.loads(row["medications"]), "vaccines": json.loads(row["vaccines"])}
        return {"medications": [], "vaccines": []}

async def save_medical_data(medications: list, vaccines: list):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("DELETE FROM medical_data")
        await db.execute("INSERT INTO medical_data (medications, vaccines) VALUES (?, ?)",
                         (json.dumps(medications), json.dumps(vaccines)))
        await db.commit()

async def save_event_feedback(
    timestamp: float,
    kind: str,
    event_type: str = None,
    zone_name: str = None,
    filename: str = None,
):
    """A viewer's teaching note about one moment ("not my pet").

    Kept with the event's own context so a training pass can pair it with
    the frame later without hunting the original row."""
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute(
            "INSERT INTO event_feedback "
            "(timestamp, kind, event_type, zone_name, filename, created_at) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            (timestamp, kind, event_type, zone_name, filename, time.time()),
        )
        await db.commit()

async def get_event_feedback(limit: int = 50):
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute(
            "SELECT * FROM event_feedback ORDER BY created_at DESC LIMIT ?",
            (limit,),
        )
        rows = await cursor.fetchall()
        return [dict(row) for row in rows]
