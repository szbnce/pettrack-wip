import os
import glob
import json
import socket
from fastapi import APIRouter, Depends, HTTPException, Query, Header, Response, Request
from fastapi.responses import FileResponse
from typing import List, Dict
import time
import asyncio
from datetime import datetime
from database import get_events, get_event_counts_since, get_events_since, get_zones, save_zones, get_pet, save_pet, get_medical_data, save_medical_data, log_event
from schemas import ZoneConfig, Point, MonitorUpdate, LoginRequest, PetProfile, MedicalDataSync, SoundEvent
from email.utils import formatdate
import jwt
import hmac
from dotenv import set_key
from pydantic import BaseModel, Field
from manager import client_manager
import mqtt_bridge
import notify
import timelapse
import health
import settings as app_settings
import arming

# Token, session and lockout machinery lives in auth.py; the names are
# re-exported here because main.py and the tests import them from this module.
from auth import (
    SECRET_TOKEN,
    fernet,
    get_fernet_key,
    token_valid,
    token_payload,
    scope_allows,
    mint_access_token,
    mint_media_token,
    create_session,
    rotate_session,
    revoke_session,
    session_active,
    is_locked_out,
    record_failure,
    clear_failures,
    failure_count,
    ACCESS_TOKEN_TTL_SECONDS,
    MEDIA_TOKEN_TTL_SECONDS,
)

# Reported by /api/version so the apps can show "Server vX" and warn when the
# two sides are out of step. Keep in sync with the app's kAppVersion.
SERVER_VERSION = "2.1.0"

async def verify_token(request: Request, token: str = Query(None), x_api_token: str = Header(None)):
    req_token = token or x_api_token
    if not token_valid(req_token):
        raise HTTPException(status_code=401, detail="Invalid token")
    payload = token_payload(req_token)
    # Media and monitor tokens stay fenced into the paths they were minted for.
    if not scope_allows(payload, request.url.path):
        raise HTTPException(status_code=403, detail="Token not valid here")
    sid = payload.get("sid") if payload else None
    if sid and not await session_active(sid):
        raise HTTPException(status_code=401, detail="Session revoked")

router = APIRouter(dependencies=[Depends(verify_token)])
auth_router = APIRouter()

monitor_state = {
    "online": False,
    "frame_count": 0,
}
active_zones: Dict[str, List[Point]] = {}

# One entry per camera phone. monitor_state above is only a mirror of the
# freshest camera so single-camera clients (/api/status, the Wear app) keep
# working unchanged once a second monitor joins.
monitor_registry: Dict[str, Dict] = {}
monitor_frames: Dict[str, Dict] = {}
ONLINE_TIMEOUT = 5.0

latest_frame_info = {
    "data": None,
    "timestamp": 0.0,
}

def _fresh_monitors(now: float | None = None):
    now = now or time.time()
    return [
        e
        for e in monitor_registry.values()
        if e.get("online") and now - e.get("last_seen", now) <= ONLINE_TIMEOUT
    ]

def _mirror_active_monitor() -> None:
    """Point the legacy single-camera state at the freshest camera."""
    entries = _fresh_monitors()
    if not entries:
        monitor_state["online"] = False
        return
    entry = max(entries, key=lambda e: e.get("last_seen", 0.0))
    monitor_state.update(
        {
            "id": entry["id"],
            "online": True,
            "last_seen": entry["last_seen"],
            "frame_count": entry.get("frame_count", 0),
            "battery_level": entry.get("battery_level", 100),
            "is_charging": entry.get("is_charging", False),
        }
    )

def touch_monitor(monitor_id: str | None = None, **fields) -> str:
    """Register or refresh one camera and re-mirror the active-camera state."""
    mid = monitor_id or "unnamed_monitor"
    entry = _ensure_monitor(mid)
    entry.update(fields)
    entry["last_seen"] = time.time()
    entry["online"] = True
    _mirror_active_monitor()
    return mid

def _ensure_monitor(mid: str) -> Dict:
    return monitor_registry.setdefault(
        mid,
        {
            "id": mid,
            "online": True,
            "frame_count": 0,
            "battery_level": 100,
            "is_charging": False,
            "last_seen": 0.0,
        },
    )

def mark_monitor_offline(monitor_id: str | None = None) -> None:
    mid = monitor_id or "unnamed_monitor"
    entry = monitor_registry.get(mid)
    if entry:
        entry["online"] = False
    was_online = monitor_state.get("online", False)
    _mirror_active_monitor()
    if was_online and not monitor_state.get("online"):
        mqtt_bridge.bridge.publish_monitor(False)

def update_latest_frame(data: bytes, monitor_id: str | None = None):
    now = time.time()
    latest_frame_info["data"] = data
    latest_frame_info["timestamp"] = now
    mid = monitor_id or "unnamed_monitor"
    entry = _ensure_monitor(mid)
    entry["frame_count"] = entry.get("frame_count", 0) + 1
    monitor_frames[mid] = {"data": data, "timestamp": now}
    touch_monitor(mid)
    mqtt_bridge.bridge.publish_frame(data)
    timelapse.maybe_sample(data)
    return mid

def frame_media_type(data: bytes) -> str:
    """JPEG or PNG, whichever the monitor actually sent."""
    return "image/jpeg" if data[:2] == b"\xff\xd8" else "image/png"

class PinRequest(BaseModel):
    pin: str
    scope: str = "full"


class RefreshRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: str | None = None


def _monitor_list() -> List[Dict]:
    """Snapshot of every camera that has checked in, freshest status first."""
    now = time.time()
    out = []
    for mid, entry in monitor_registry.items():
        online = entry.get("online", False) and now - entry.get("last_seen", now) <= ONLINE_TIMEOUT
        out.append(
            {
                "id": entry["id"],
                "online": online,
                "frame_count": entry.get("frame_count", 0),
                "battery_level": entry.get("battery_level", 100),
                "is_charging": entry.get("is_charging", False),
                "last_seen": entry.get("last_seen", 0.0),
            }
        )
    out.sort(key=lambda e: e["id"])
    return out


@router.get("/api/status")
async def get_status():
    is_online = monitor_state.get("online", False)
    if is_online and time.time() - monitor_state.get("last_seen", time.time()) > ONLINE_TIMEOUT:
        mark_monitor_offline(monitor_state.get("id"))
        is_online = False

    return {
        "monitor_online": is_online,
        "frame_count": monitor_state.get("frame_count", 0),
        "monitor_id": monitor_state.get("id", "unnamed_monitor"),
        "battery_level": monitor_state.get("battery_level", 100),
        "is_charging": monitor_state.get("is_charging", False),
        "monitors": _monitor_list(),
        # Riding the existing poll: is the camera actually watching right now?
        "arming": {
            "mode": app_settings.get_arming_mode(),
            "armed": app_settings.is_armed_now(),
        },
    }

@router.get("/api/monitors")
async def list_monitors():
    """Every camera that has checked in, for the multi-camera dashboard."""
    return _monitor_list()

@router.get("/api/monitors/{monitor_id}/frame")
async def get_monitor_frame(monitor_id: str):
    """Latest still from one camera — used by the grid thumbnails."""
    info = monitor_frames.get(monitor_id)
    if info and info["data"]:
        headers = {"Last-Modified": formatdate(info["timestamp"], usegmt=True)}
        return Response(
            content=info["data"],
            media_type=frame_media_type(info["data"]),
            headers=headers,
        )
    raise HTTPException(status_code=404, detail="No frame from this monitor yet")

@auth_router.get("/api/health")
async def health_probe():
    """Unauthenticated liveness probe for the apps' connection-status chip.

    Deliberately minimal: it must work even with a missing/expired token so
    the UI can say "server unreachable" vs "wrong token". The full watchdog
    view lives at /api/system-health (authenticated).
    """
    return {"ok": True, "name": socket.gethostname() or "pettrack"}

@auth_router.get("/api/version")
async def get_version():
    """Unauthenticated version probe for the apps' update check."""
    return {"version": SERVER_VERSION, "name": socket.gethostname() or "pettrack"}

# --- staged app updates ------------------------------------------------------
# Self-hosted one-tap updates: drop PetTrack.apk and update.json into the
# updates/ directory (see docs/RELEASE_CHECKLIST.md) and every installed app
# can update itself. update.json carries the version: {"version": "2.1.0"}.

UPDATE_APK_NAME = "PetTrack.apk"


def staged_update() -> dict | None:
    """The staged APK and its version, or None when nothing is staged.

    Both files must be present: an APK alone says nothing about what it
    is, and a version without bytes is just a tease. Read at call time so
    staging a file needs no server restart."""
    update_dir = os.getenv("PETTRACK_UPDATE_DIR", "updates")
    apk_path = os.path.join(update_dir, UPDATE_APK_NAME)
    meta_path = os.path.join(update_dir, "update.json")
    if not (os.path.isfile(apk_path) and os.path.isfile(meta_path)):
        return None
    try:
        with open(meta_path) as f:
            version = str(json.load(f).get("version") or "").strip()
    except (OSError, ValueError):
        return None
    if not version:
        return None
    return {"version": version, "path": apk_path}


@auth_router.get("/api/app/update")
async def get_app_update():
    """Unauthenticated update probe (like /api/version): what this server
    has staged for the app, if anything. The app decides whether it is
    newer than the build it is running."""
    staged = staged_update()
    if staged is None:
        return {"version": None}
    return {
        "version": staged["version"],
        "apk_bytes": os.path.getsize(staged["path"]),
    }


@router.get("/api/app/update/apk")
async def download_app_update():
    """The staged APK. Valid credentials required — this is the one file
    on the server that, once installed, owns the phone."""
    staged = staged_update()
    if staged is None:
        raise HTTPException(status_code=404, detail="no update staged")
    return FileResponse(
        staged["path"],
        media_type="application/vnd.android.package-archive",
        filename=UPDATE_APK_NAME,
    )

@router.post("/api/frame/web")
async def receive_web_frame(request: Request, token: str = "", monitor_id: str = ""):
    if not token_valid(token):
        return {"error": "Invalid token"}
    data = await request.body()
    mid = update_latest_frame(data, monitor_id or None)

    # Broadcast to WebSocket clients watching this camera
    asyncio.create_task(client_manager.broadcast_bytes(data, source_id=mid))

    # Run vision every 30 frames
    if monitor_registry[mid]["frame_count"] % 30 == 0:
        from vision import process_and_save_frame
        asyncio.create_task(process_and_save_frame(data))

    return {"status": "ok"}

def _session_response(session: dict) -> dict:
    # The "secret" key is kept for existing clients; it carries the same
    # short-lived access JWT as "token".
    return {
        "token": session["token"],
        "secret": session["token"],
        "refresh_token": session["refresh_token"],
        "expires_in": session["expires_in"],
    }


async def _client_locked_out(request: Request) -> None:
    if await is_locked_out(request.client.host):
        raise HTTPException(
            status_code=429, detail="Too many failed attempts. Try again in 5 minutes."
        )


async def require_full_token(req_token: str | None) -> None:
    """Full access only — a monitor or media token must never reach here."""
    if not token_valid(req_token):
        raise HTTPException(status_code=401, detail="Unauthorized to set PIN")
    payload = token_payload(req_token) if req_token else None
    if payload is not None:
        if payload.get("auth") != "ok":
            raise HTTPException(status_code=403, detail="Scoped token not valid here")
        sid = payload.get("sid")
        if sid and not await session_active(sid):
            raise HTTPException(status_code=401, detail="Session revoked")


@auth_router.post("/api/auth/login")
async def login(req: LoginRequest, request: Request):
    await _client_locked_out(request)
    if not hmac.compare_digest(req.secret, SECRET_TOKEN or ""):
        await record_failure(request.client.host)
        raise HTTPException(status_code=401, detail="Invalid secret")
    await clear_failures(request.client.host)
    return _session_response(await create_session(req.scope))


@auth_router.post("/api/auth/refresh")
async def refresh(req: RefreshRequest):
    session = await rotate_session(req.refresh_token)
    if session is None:
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    return _session_response(session)


@auth_router.post("/api/auth/logout")
async def logout(req: LogoutRequest, x_api_token: str = Header(None)):
    """Revoke the session family behind the refresh token and/or the access
    token — its access tokens die with it. Idempotent."""
    if req.refresh_token:
        await revoke_session(refresh_token=req.refresh_token)
    payload = token_payload(x_api_token) if x_api_token else None
    sid = payload.get("sid") if payload else None
    if sid:
        await revoke_session(session_id=sid)
    return {"status": "ok"}


@auth_router.post("/api/auth/set_pin")
async def set_pin(req: PinRequest, x_api_token: str = Header(None)):
    await require_full_token(x_api_token)
    if not re.fullmatch(r"\d{4,8}", req.pin):
        raise HTTPException(status_code=422, detail="PIN must be 4-8 digits")

    set_key(".env", "PETTRACK_WEB_PIN", req.pin)
    os.environ["PETTRACK_WEB_PIN"] = req.pin
    return {"status": "success"}


@auth_router.post("/api/auth/login_pin")
async def login_pin(req: PinRequest, request: Request):
    await _client_locked_out(request)
    if not hmac.compare_digest(req.pin, os.getenv("PETTRACK_WEB_PIN") or ""):
        await record_failure(request.client.host)
        raise HTTPException(status_code=401, detail="Invalid PIN")
    await clear_failures(request.client.host)
    # Scoped minting: a monitor PIN login gets only the frame and status
    # paths, never the settings and pet data.
    return _session_response(await create_session(req.scope))


@router.get("/api/pet")
async def get_pet_profile():
    pet = await get_pet()
    return pet if pet else {"name": "Unknown", "type": "Unknown", "profile_pic": None}

@router.post("/api/pet")
async def update_pet_profile(pet: PetProfile):
    await save_pet(pet.name, pet.type, pet.profile_pic)
    return {"status": "ok"}

@router.post("/api/monitor/update")
async def update_monitor_status(update: MonitorUpdate):
    touch_monitor(
        update.monitor_id,
        battery_level=update.battery_level,
        is_charging=update.is_charging,
    )
    mqtt_bridge.bridge.publish_battery(update.battery_level, update.is_charging)
    mqtt_bridge.bridge.publish_monitor(True)
    return {"status": "ok"}

# Sound events (bark / meow / loud noise) come from the monitor's mic-level
# sampler. A pet can bark for a whole minute, so collapse bursts into one
# event per window instead of one per sample.
SOUND_EVENT_COOLDOWN = 60.0
_last_sound_event = 0.0

@router.post("/api/monitor/sound")
async def report_sound_event(event: SoundEvent):
    global _last_sound_event
    if not app_settings.is_armed_now():
        # Disarmed keeps no evidence — sounds are dropped before the
        # cooldown is consumed, so re-arming is not punished for the wait.
        return {"status": "ok", "logged": False}
    now = time.time()
    if now - _last_sound_event < SOUND_EVENT_COOLDOWN:
        return {"status": "ok", "logged": False}
    _last_sound_event = now
    await log_event("sound_detected", details=f"{event.level:.0f} dB")
    mqtt_bridge.bridge.publish_event("sound_detected")
    return {"status": "ok", "logged": True}

@router.get("/api/activity")
async def get_activity(limit: int = 50):
    events = await get_events(limit)
    return {"events": events}

@router.get("/api/timeline")
async def get_timeline(days: int = Query(default=14, ge=1, le=90)):
    """Day-by-day activity for the replay timeline strip.

    One entry per calendar day that had events or motion clips, bucketed in
    the server's local timezone — the same calendar the daily recap and
    timelapse use. Days with nothing are left out; clients fill the gaps.
    """
    since = time.time() - days * 86400

    events_by_day: Dict[str, Dict[str, int]] = {}
    for row in await get_event_counts_since(since):
        bucket = events_by_day.setdefault(row["day"], {})
        bucket[row["event_type"]] = int(row["n"])

    clips_by_day: Dict[str, int] = {}
    folder = "replays"
    if os.path.isdir(folder):
        for filename in os.listdir(folder):
            if not (
                filename.startswith("replay_")
                and filename.endswith(".mp4")
                and not filename.endswith("_raw.mp4")
            ):
                continue
            path = os.path.join(folder, filename)
            mtime = os.path.getmtime(path)
            if mtime < since:
                continue
            day = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d")
            clips_by_day[day] = clips_by_day.get(day, 0) + 1

    out = []
    for day in sorted(set(events_by_day) | set(clips_by_day)):
        events = events_by_day.get(day, {})
        out.append({
            "date": day,
            "events": events,
            "total": sum(events.values()),
            "clips": clips_by_day.get(day, 0),
        })
    return {"days": out}

# One motion recording is started with a 30-second window (see vision.py),
# which is close enough to count activity time without probing every file.
MOTION_CLIP_SECONDS = 30.0
# A stay longer than this is a lost zone_exit, not a real visit.
MAX_ZONE_STAY_SECONDS = 8 * 3600


def zone_stays(events: List[Dict]):
    """Seconds spent per zone, pairing each zone_enter with its matching exit.

    Returns (totals_by_zone, per_day_by_zone); an interval is attributed to
    the day it started on. A stay with no exit is dropped (it would be a
    guess), and a stay longer than MAX_ZONE_STAY_SECONDS is clipped to it.
    """
    totals: Dict[str, float] = {}
    per_day: Dict[str, Dict[str, float]] = {}
    open_since: Dict[str, float] = {}
    for ev in sorted(events, key=lambda e: e.get("timestamp", 0.0)):
        zone = ev.get("zone_name") or ""
        ts = float(ev.get("timestamp", 0.0))
        if ev.get("event_type") == "zone_enter":
            open_since[zone] = ts
        elif ev.get("event_type") == "zone_exit":
            start = open_since.pop(zone, None)
            if start is None:
                continue
            seconds = min(ts - start, MAX_ZONE_STAY_SECONDS)
            day = datetime.fromtimestamp(start).strftime("%Y-%m-%d")
            totals[zone] = totals.get(zone, 0.0) + seconds
            bucket = per_day.setdefault(day, {})
            bucket[zone] = bucket.get(zone, 0.0) + seconds
    return totals, per_day


@router.get("/api/insights")
async def get_insights(days: int = Query(default=14, ge=1, le=90)):
    """Activity insights for the charts.

    Per calendar day (server-local, same bucketing as /api/timeline):
    estimated active seconds (one motion clip ≈ 30 s of recording), the
    motion clips and sound events behind it, and time spent per zone.
    """
    since = time.time() - days * 86400

    events = await get_events_since(since)
    zone_totals, zone_per_day = zone_stays(events)

    sounds_by_day: Dict[str, int] = {}
    events_by_day: Dict[str, int] = {}
    for ev in events:
        day = datetime.fromtimestamp(ev["timestamp"]).strftime("%Y-%m-%d")
        events_by_day[day] = events_by_day.get(day, 0) + 1
        if ev.get("event_type") == "sound_detected":
            sounds_by_day[day] = sounds_by_day.get(day, 0) + 1

    clips_by_day: Dict[str, int] = {}
    folder = "replays"
    if os.path.isdir(folder):
        for filename in os.listdir(folder):
            if not (
                filename.startswith("replay_")
                and filename.endswith(".mp4")
                and not filename.endswith("_raw.mp4")
            ):
                continue
            mtime = os.path.getmtime(os.path.join(folder, filename))
            if mtime < since:
                continue
            day = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d")
            clips_by_day[day] = clips_by_day.get(day, 0) + 1

    out = []
    totals = {
        "active_seconds": 0.0,
        "clips": 0,
        "sounds": 0,
        "events": 0,
        "zone_seconds": {},
    }
    for day in sorted(
        set(clips_by_day) | set(sounds_by_day)
        | set(events_by_day) | set(zone_per_day)
    ):
        clips = clips_by_day.get(day, 0)
        sounds = sounds_by_day.get(day, 0)
        zone_seconds = zone_per_day.get(day, {})
        active = clips * MOTION_CLIP_SECONDS
        out.append({
            "date": day,
            "clips": clips,
            "sounds": sounds,
            "events": events_by_day.get(day, 0),
            "active_seconds": active,
            "zone_seconds": zone_seconds,
        })
        totals["active_seconds"] += active
        totals["clips"] += clips
        totals["sounds"] += sounds
        totals["events"] += events_by_day.get(day, 0)
        for zone, seconds in zone_seconds.items():
            totals["zone_seconds"][zone] = (
                totals["zone_seconds"].get(zone, 0.0) + seconds
            )

    return {"days": out, "totals": totals, "zone_totals": zone_totals}

@router.get("/api/system-health")
async def get_system_health():
    """Watchdog view for the app's system-health card.

    Is the camera still streaming, is the disk running out of room, and
    how much history is kept — the things a self-hoster wants to know
    before trusting the setup to run unattended. (Not to be confused with
    the unauthenticated /api/health liveness probe.)"""
    now = time.time()
    monitors = _monitor_list()
    disk = health.disk_snapshot("replays" if os.path.isdir("replays") else ".")

    alerts = []
    if health.offline_cameras(monitor_registry, now):
        alerts.append("camera_offline")
    if disk["low"]:
        alerts.append("disk_low")

    freshest = max((m["last_seen"] for m in monitors), default=0.0)
    return {
        "camera_online": any(m["online"] for m in monitors),
        "camera_quiet_seconds": (now - freshest) if freshest else None,
        "monitors": monitors,
        "alerts": alerts,
        "disk": disk,
        "replays": {
            **health.replay_stats(),
            "retention_days": app_settings.get_replay_retention_days(),
        },
    }

class SettingsUpdate(BaseModel):
    replay_retention_days: int | None = Field(
        default=None,
        ge=app_settings.MIN_REPLAY_RETENTION_DAYS,
        le=app_settings.MAX_REPLAY_RETENTION_DAYS,
    )
    # Remote alerts (ntfy bridge) + the quiet-hours window it honours.
    ntfy_url: str | None = None
    ntfy_token: str | None = None
    ntfy_lang: str | None = None
    quiet_hours_enabled: bool | None = None
    quiet_hours_from: int | None = Field(default=None, ge=0, le=1439)
    quiet_hours_to: int | None = Field(default=None, ge=0, le=1439)

@router.get("/api/settings")
async def get_server_settings():
    quiet_enabled, quiet_from, quiet_to = app_settings.get_quiet_hours()
    return {
        "replay_retention_days": app_settings.get_replay_retention_days(),
        "ntfy_url": app_settings.get_ntfy_url(),
        "ntfy_token": app_settings.get_ntfy_token(),
        "ntfy_lang": app_settings.get_ntfy_lang(),
        "quiet_hours_enabled": quiet_enabled,
        "quiet_hours_from": quiet_from,
        "quiet_hours_to": quiet_to,
    }

@router.post("/api/settings")
async def update_server_settings(req: SettingsUpdate):
    out = {}
    if req.replay_retention_days is not None:
        out["replay_retention_days"] = app_settings.set_replay_retention_days(
            req.replay_retention_days
        )
    if req.ntfy_url is not None:
        try:
            out["ntfy_url"] = app_settings.set_ntfy_url(req.ntfy_url)
        except ValueError:
            raise HTTPException(status_code=400, detail="invalid ntfy topic URL")
    if req.ntfy_token is not None:
        out["ntfy_token"] = app_settings.set_ntfy_token(req.ntfy_token)
    if req.ntfy_lang is not None:
        if req.ntfy_lang not in app_settings.SUPPORTED_NTFY_LANGS:
            raise HTTPException(status_code=400, detail="unsupported language")
        out["ntfy_lang"] = app_settings.set_ntfy_lang(req.ntfy_lang)
    if (
        req.quiet_hours_enabled is not None
        or req.quiet_hours_from is not None
        or req.quiet_hours_to is not None
    ):
        quiet_enabled, quiet_from, quiet_to = app_settings.get_quiet_hours()
        quiet_enabled, quiet_from, quiet_to = app_settings.set_quiet_hours(
            req.quiet_hours_enabled if req.quiet_hours_enabled is not None else quiet_enabled,
            req.quiet_hours_from if req.quiet_hours_from is not None else quiet_from,
            req.quiet_hours_to if req.quiet_hours_to is not None else quiet_to,
        )
        out["quiet_hours_enabled"] = quiet_enabled
        out["quiet_hours_from"] = quiet_from
        out["quiet_hours_to"] = quiet_to
    return out


class ArmingWindow(BaseModel):
    days: List[int]
    from_min: int = Field(ge=0, le=1439)
    to_min: int = Field(ge=0, le=1439)


class ArmingUpdate(BaseModel):
    mode: str | None = None
    schedule: List[ArmingWindow] | None = None


def _arming_state() -> dict:
    mode = app_settings.get_arming_mode()
    schedule = app_settings.get_arming_schedule()
    return {
        "mode": mode,
        "schedule": schedule,
        "armed": arming.is_armed(mode, schedule, datetime.now()),
    }


@router.get("/api/arming")
async def get_arming():
    return _arming_state()


@router.post("/api/arming")
async def update_arming(req: ArmingUpdate, x_api_token: str = Header(None)):
    # Security-adjacent: arming decides what gets recorded. Monitor and
    # media tokens must never be able to disarm the camera.
    await require_full_token(x_api_token)
    if req.mode is not None:
        try:
            app_settings.set_arming_mode(req.mode)
        except ValueError:
            raise HTTPException(status_code=400, detail="invalid arming mode")
    if req.schedule is not None:
        app_settings.set_arming_schedule([w.model_dump() for w in req.schedule])
    return _arming_state()

@router.post("/api/notify/test")
async def send_test_notification():
    """One-tap setup check from the app: proves the topic actually works.

    A deliberate test ignores quiet hours — the same courtesy the in-app
    test-notification button gets."""
    if not app_settings.get_ntfy_url():
        raise HTTPException(status_code=400, detail="remote alerts are not configured")
    if not await notify.push_test():
        raise HTTPException(status_code=502, detail="could not deliver to the ntfy topic")
    return {"status": "ok", "sent": True}

@router.get("/api/zones")
async def get_zones_list():
    zones = await get_zones()
    return {"zones": zones}

@router.post("/api/zones")
async def update_zones(zones: List[ZoneConfig]):
    global active_zones
    active_zones.clear()
    for z in zones:
        active_zones[z.name] = [{"x": p.x, "y": p.y} for p in z.polygon]
    await save_zones(zones)
    return {"message": "Zones updated successfully!"}

@router.get("/api/medical")
async def get_medical_route(token: str = None):
    data = await get_medical_data()
    return data

@router.post("/api/medical")
async def update_medical_route(data: MedicalDataSync, token: str = None):
    await save_medical_data(data.medications, data.vaccines)
    return {"status": "ok"}

@router.get("/api/frame/latest")
async def get_latest_frame():
    if latest_frame_info["data"]:
        headers = {
            "Last-Modified": formatdate(latest_frame_info["timestamp"], usegmt=True)
        }
        return Response(content=latest_frame_info["data"], media_type=frame_media_type(latest_frame_info["data"]), headers=headers)
    
    folder = "captured_images"
    if not os.path.exists(folder):
        return {"error": "No images found"}

    files = glob.glob(os.path.join(folder, "*.png"))
    if not files:
        return {"error": "No images found"}

    latest = max(files, key=os.path.getmtime)
    with open(latest, "rb") as f:
        img_data = f.read()
    headers = {
        "Last-Modified": formatdate(os.path.getmtime(latest), usegmt=True)
    }
    return Response(content=img_data, media_type=frame_media_type(img_data), headers=headers)


@router.get("/api/frame/web")
async def get_web_frame():
    if latest_frame_info["data"]:
        headers = {
            "Last-Modified": formatdate(latest_frame_info["timestamp"], usegmt=True)
        }
        return Response(content=latest_frame_info["data"], media_type=frame_media_type(latest_frame_info["data"]), headers=headers)

    folder = "captured_images"
    if not os.path.exists(folder):
        return {"error": "No images found"}
        
    files = glob.glob(os.path.join(folder, "*.png"))
    if not files:
        return {"error": "No images found"}
    
    latest = max(files, key=os.path.getmtime)
    with open(latest, "rb") as f:
        img_data = f.read()
    headers = {
        "Last-Modified": formatdate(os.path.getmtime(latest), usegmt=True)
    }
    return Response(content=img_data, media_type=frame_media_type(img_data), headers=headers)

@router.get("/api/replays")
async def list_replays():
    folder = "replays"
    if not os.path.exists(folder):
        return {"replays": []}
    
    files = []
    for filename in os.listdir(folder):
        if filename.endswith(".mp4"):
            # Recaps and timelapses live in the same folder so the existing
            # signed-URL endpoint can serve them, but they are not events.
            if (
                filename.startswith("highlight_")
                or filename.startswith("timelapse_")
                or filename.endswith("_raw.mp4")
            ):
                continue
            file_path = os.path.join(folder, filename)
            files.append({
                "filename": filename,
                "timestamp": int(os.path.getmtime(file_path)),
                "size": os.path.getsize(file_path),
                # Short-lived, file-scoped URL so clients never have to put
                # their long-lived token into a link.
                "url": f"/api/replays/{filename}?token={mint_media_token(filename)}",
            })

    # Sort newest first
    files.sort(key=lambda x: x["timestamp"], reverse=True)
    return {"replays": files}


@router.get("/api/highlight")
async def get_daily_highlight(date: str = Query(default=None)):
    """Daily recap: the day's motion moments stitched into one clip.

    Built on demand and cached in replays/highlight_<date>.mp4; returns 404
    when the day has no motion events (or ffmpeg is unavailable).
    """
    import highlight as highlight_mod

    if date is None:
        day = None
    else:
        try:
            day = datetime.strptime(date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="date must be YYYY-MM-DD")

    result = await asyncio.to_thread(highlight_mod.build_daily_highlight, day)
    if result is None:
        raise HTTPException(status_code=404, detail="no motion events for this day")

    return {
        "date": result["date"],
        "clip_count": result["clip_count"],
        "filename": result["filename"],
        "url": f"/api/replays/{result['filename']}?token={mint_media_token(result['filename'])}",
    }

@router.get("/api/timelapse")
async def get_timelapse(date: str = Query(default=None)):
    """Daily timelapse: the day's sampled stills stitched into one clip.

    Built on demand and cached in replays/timelapse_<date>.mp4; returns 404
    when the day has too few stills (or ffmpeg is unavailable).
    """
    if date is None:
        day = None
    else:
        try:
            day = datetime.strptime(date, "%Y-%m-%d").date()
        except ValueError:
            raise HTTPException(status_code=400, detail="date must be YYYY-MM-DD")

    result = await asyncio.to_thread(timelapse.build_timelapse, day)
    if result is None:
        raise HTTPException(status_code=404, detail="not enough frames for this day")

    return {
        "date": result["date"],
        "frame_count": result["frame_count"],
        "filename": result["filename"],
        "url": f"/api/replays/{result['filename']}?token={mint_media_token(result['filename'])}",
    }

import re
from fastapi import Request
from fastapi.responses import StreamingResponse

def range_requests_response(request: Request, file_path: str, content_type: str):
    file_size = os.stat(file_path).st_size
    range_header = request.headers.get("range")

    headers = {
        "content-type": content_type,
        "accept-ranges": "bytes",
        "content-encoding": "identity",
        "content-length": str(file_size),
        "access-control-expose-headers": (
            "content-type, accept-ranges, content-length, "
            "content-range, content-encoding"
        ),
    }
    start = 0
    end = file_size - 1
    status_code = 200

    if range_header is not None:
        range_match = re.match(r"bytes=(\d+)-(\d*)", range_header)
        if range_match:
            start = int(range_match.group(1))
            end = int(range_match.group(2)) if range_match.group(2) else file_size - 1
            
        size = end - start + 1
        headers["content-length"] = str(size)
        headers["content-range"] = f"bytes {start}-{end}/{file_size}"
        status_code = 206

    def send_bytes_range_requests(f_path: str, st: int, en: int):
        with open(f_path, mode="rb") as f:
            f.seek(st)
            pos = st
            while pos <= en:
                read_size = min(1024 * 1024, en - pos + 1)
                data = f.read(read_size)
                if not data:
                    break
                pos += len(data)
                yield data

    return StreamingResponse(
        send_bytes_range_requests(file_path, start, end),
        headers=headers,
        status_code=status_code,
    )

@router.get("/api/replays/{filename}")
async def get_replay_video(filename: str, request: Request, token: str = Query(None), x_api_token: str = Header(None)):
    folder = "replays"
    safe_filename = os.path.basename(filename)
    file_path = os.path.join(folder, safe_filename)
    if not os.path.exists(file_path) or not file_path.endswith(".mp4"):
        raise HTTPException(status_code=404, detail="Replay not found")

    # A media token is only valid for the exact file it was minted for.
    req_token = token or x_api_token
    try:
        payload = jwt.decode(req_token, SECRET_TOKEN, algorithms=["HS256"])
        if "file" in payload and payload["file"] != safe_filename:
            raise HTTPException(status_code=403, detail="Token is not valid for this file")
    except jwt.PyJWTError:
        pass  # raw secret or already-validated token

    if request.headers.get("range"):
        return range_requests_response(request, file_path, "video/mp4")
    return FileResponse(file_path, media_type="video/mp4")