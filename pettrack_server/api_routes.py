import os
import glob
import socket
from fastapi import APIRouter, Depends, HTTPException, Query, Header, Response, Request
from fastapi.responses import FileResponse
from typing import List, Dict
import time
import asyncio
from database import get_events, get_zones, save_zones, get_pet, save_pet, get_medical_data, save_medical_data
from schemas import ZoneConfig, Point, MonitorUpdate, LoginRequest, PetProfile, MedicalDataSync
from email.utils import formatdate
import jwt
from cryptography.fernet import Fernet
import base64
import hashlib
import hmac
import secrets
from dotenv import load_dotenv, set_key
from pydantic import BaseModel
from manager import client_manager

load_dotenv()

SECRET_TOKEN = os.getenv("PETTRACK_SECRET")
if not SECRET_TOKEN:
    print("No secret found! Generating a new ultra-secure 64-char token...")
    new_secret = secrets.token_urlsafe(48)
    try:
        set_key(".env", "PETTRACK_SECRET", new_secret)
    except OSError:
        # Fallback for Docker bind mounts where os.replace fails
        with open(".env", "a") as f:
            f.write(f"\nPETTRACK_SECRET='{new_secret}'\n")
    SECRET_TOKEN = new_secret

def get_fernet_key(secret: str) -> bytes:
    digest = hashlib.sha256(secret.encode()).digest()
    return base64.urlsafe_b64encode(digest)

fernet = Fernet(get_fernet_key(SECRET_TOKEN))

JWT_TTL_SECONDS = 86400 * 3650
MEDIA_TOKEN_TTL_SECONDS = 3600

def mint_token() -> str:
    return jwt.encode(
        {"auth": "ok", "exp": time.time() + JWT_TTL_SECONDS},
        SECRET_TOKEN,
        algorithm="HS256",
    )

def mint_media_token(filename: str) -> str:
    """Short-lived token scoped to a single replay file, safe for URLs."""
    return jwt.encode(
        {"auth": "media", "file": filename, "exp": time.time() + MEDIA_TOKEN_TTL_SECONDS},
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

async def verify_token(request: Request, token: str = Query(None), x_api_token: str = Header(None)):
    req_token = token or x_api_token
    if not token_valid(req_token):
        raise HTTPException(status_code=401, detail="Invalid token")

    # A media token only unlocks the replay file it was minted for.
    try:
        payload = jwt.decode(req_token, SECRET_TOKEN, algorithms=["HS256"])
    except jwt.PyJWTError:
        return  # raw secret: full access
    if "file" in payload and not request.url.path.startswith("/api/replays/"):
        raise HTTPException(status_code=403, detail="Media token not valid here")

router = APIRouter(dependencies=[Depends(verify_token)])
auth_router = APIRouter()

monitor_state = {
    "online": False,
    "frame_count": 0,
}
active_zones: Dict[str, List[Point]] = {}

latest_frame_info = {
    "data": None,
    "timestamp": 0.0,
}

def update_latest_frame(data: bytes):
    latest_frame_info["data"] = data
    latest_frame_info["timestamp"] = time.time()

def frame_media_type(data: bytes) -> str:
    """JPEG or PNG, whichever the monitor actually sent."""
    return "image/jpeg" if data[:2] == b"\xff\xd8" else "image/png"

class PinRequest(BaseModel):
    pin: str

failed_login_attempts = {}


@router.get("/api/status")
async def get_status():
    is_online = monitor_state.get("online", False)
    if is_online and time.time() - monitor_state.get("last_seen", time.time()) > 5:
        monitor_state["online"] = False
        is_online = False

    return {
        "monitor_online": is_online,
        "frame_count": monitor_state.get("frame_count", 0),
        "monitor_id": monitor_state.get("id", "unnamed_monitor"),
        "battery_level": monitor_state.get("battery_level", 100),
        "is_charging": monitor_state.get("is_charging", False),
    }

@auth_router.get("/api/health")
async def health():
    """Unauthenticated liveness probe for the apps' connection-status chip.

    Deliberately minimal: it must work even with a missing/expired token so
    the UI can say "server unreachable" vs "wrong token".
    """
    return {"ok": True, "name": socket.gethostname() or "pettrack"}

@router.post("/api/frame/web")
async def receive_web_frame(request: Request, token: str = ""):
    if not token_valid(token):
        return {"error": "Invalid token"}
    data = await request.body()
    update_latest_frame(data)
    
    # Broadcast to WebSocket clients
    asyncio.create_task(client_manager.broadcast_bytes(data))

    monitor_state["online"] = True
    monitor_state["last_seen"] = time.time()
    monitor_state["frame_count"] = monitor_state.get("frame_count", 0) + 1
    
    # Run vision every 30 frames
    if monitor_state["frame_count"] % 30 == 0:
        from vision import process_and_save_frame
        asyncio.create_task(process_and_save_frame(data))
        
    return {"status": "ok"}

@auth_router.post("/api/auth/login")
async def login(req: LoginRequest):
    if not hmac.compare_digest(req.secret, SECRET_TOKEN or ""):
        raise HTTPException(status_code=401, detail="Invalid secret")

    return {"token": mint_token()}

@auth_router.post("/api/auth/set_pin")
async def set_pin(req: PinRequest, x_api_token: str = Header(None)):
    if not token_valid(x_api_token):
        raise HTTPException(status_code=401, detail="Unauthorized to set PIN")
    if not re.fullmatch(r"\d{4,8}", req.pin):
        raise HTTPException(status_code=422, detail="PIN must be 4-8 digits")

    set_key(".env", "PETTRACK_WEB_PIN", req.pin)
    os.environ["PETTRACK_WEB_PIN"] = req.pin
    return {"status": "success"}

@auth_router.post("/api/auth/login_pin")
async def login_pin(req: PinRequest, request: Request):
    ip = request.client.host
    now = time.time()

    if ip in failed_login_attempts:
        attempts, last_time = failed_login_attempts[ip]
        if now - last_time > 300:
            failed_login_attempts[ip] = (0, now)
        elif attempts >= 5:
            raise HTTPException(status_code=429, detail="Too many failed attempts. Try again in 5 minutes.")

    if not hmac.compare_digest(req.pin, os.getenv("PETTRACK_WEB_PIN") or ""):
        attempts, _ = failed_login_attempts.get(ip, (0, now))
        failed_login_attempts[ip] = (attempts + 1, now)
        raise HTTPException(status_code=401, detail="Invalid PIN")

    if ip in failed_login_attempts:
        del failed_login_attempts[ip]

    # Mint a scoped token instead of handing out the raw master secret.
    # The "secret" key is kept for existing clients; it now carries a JWT,
    # which every auth path (header, query, WebSocket) accepts.
    token = mint_token()
    return {"token": token, "secret": token}


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
    monitor_state["battery_level"] = update.battery_level
    monitor_state["is_charging"] = update.is_charging
    return {"status": "ok"}

@router.get("/api/activity")
async def get_activity(limit: int = 50):
    events = await get_events(limit)
    return {"events": events}

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