import argparse
import uvicorn
import os
import asyncio
import json
import random
import jwt
import socket
import qrcode
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

from manager import manager, client_manager, client_command_to_monitor
from api_routes import router as zones_router, auth_router, monitor_state, active_zones, update_latest_frame, touch_monitor, mark_monitor_offline, SECRET_TOKEN, fernet, token_valid, token_payload, session_active
from env_store import safe_set_key
from tasks import alert_retry_loop, cleanup_old_images, watchdog_loop
from vision import process_and_save_frame
from database import init_db, get_zones
from discovery import start_advertiser, stop_advertiser
import mqtt_bridge

app = FastAPI()

# Analysis rides beside the live stream, never in front of it. The receive
# loop only enqueues; a frame is broadcast the moment it arrives and the
# vision work (decode, motion, DB writes) keeps up on its own. The queue is
# unbounded and in-order: nothing is dropped, and the video writer always
# sees frames in capture order.
_frame_queue: asyncio.Queue = asyncio.Queue()


async def _vision_worker():
    while True:
        data = await _frame_queue.get()
        try:
            await process_and_save_frame(data)
        except Exception as e:
            print(f"Vision: frame processing failed: {e}", flush=True)
        finally:
            _frame_queue.task_done()

# Cross-origin access is off by default: the web dashboard is served from this
# same origin, and the mobile/wear apps are not subject to CORS. Set
# PETTRACK_CORS_ORIGINS (comma-separated) to whitelist extra origins if you
# host the dashboard somewhere else.
cors_origins = [o.strip() for o in os.getenv("PETTRACK_CORS_ORIGINS", "").split(",") if o.strip()]
if cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"]
    )

app.include_router(zones_router)
app.include_router(auth_router)

@app.on_event("startup")
async def startup_event():
    await init_db()
    
    # Load saved zones from database into memory
    zones = await get_zones()
    for z in zones:
        active_zones[z["name"]] = z["polygon"]
        
    asyncio.create_task(cleanup_old_images())
    asyncio.create_task(watchdog_loop())
    asyncio.create_task(alert_retry_loop())
    asyncio.create_task(_vision_worker())

    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
    except:
        ip = "127.0.0.1"

    # Advertise on the LAN (mDNS) so apps can find this server without typing an IP.
    start_advertiser(ip=ip, port=9500)

    # Home Assistant MQTT discovery (no-op unless PETTRACK_MQTT_HOST is set).
    mqtt_bridge.start()

    qr_data = f'{{"ip": "{ip}:9500", "secret": "{SECRET_TOKEN}"}}'
    qr_img = qrcode.make(qr_data)
    qr = qrcode.QRCode()
    qr.add_data(qr_data)
    qr.make(fit=True)

    web_pin = os.getenv("PETTRACK_WEB_PIN")
    if not web_pin:
        while True:
            web_pin = f"{random.randint(1000, 9999):04d}"
            if web_pin != "8068":
                break
        safe_set_key("PETTRACK_WEB_PIN", web_pin)

    print("\n" + "="*55)
    print("SCAN THIS QR CODE WITH PETTRACK CLIENT!")
    print("="*55)
    qr.print_ascii(invert=True)
    print("="*55)
    print("OR ENTER THESE DETAILS MANUALLY:")
    print(f"Server IP: {ip}:9500")
    print(f"Secret Token: {SECRET_TOKEN}")
    print("="*55)
    print(f"WEB DASHBOARD PIN: {web_pin}")
    print("="*55 + "\n")

@app.on_event("shutdown")
async def shutdown_event():
    stop_advertiser()
    mqtt_bridge.stop()

from fastapi.staticfiles import StaticFiles

@app.websocket("/ws")
async def tracker_websocket(websocket: WebSocket, token: str = None, client_id: str = "unknown"):
    # Cameras upload here (full or monitor scope); viewers watch on /ws/client.
    if not await ws_token_ok(token, ("ok", "monitor")):
        print("Connection rejected: Invalid Token", flush=True)
        await websocket.close(code=1008)
        return

    monitor_id = client_id
    await manager.connect(websocket, key=monitor_id)
    touch_monitor(monitor_id, frame_count=0)
    monitor_state["frame_count"] = 0
    mqtt_bridge.bridge.publish_monitor(True)
    print(f"Monitor {monitor_id} connected!", flush=True)

    if len(client_manager.active.connections) > 0:
        await websocket.send_text(json.dumps({"action": "set_fps", "fps": 5}))

    try:
        while True:
            data = await websocket.receive_bytes()
            mid = update_latest_frame(data, monitor_id)

            # Only viewers watching this camera (or all of them) get the
            # frame — and they get it now; the vision worker picks it up
            # off the queue behind us.
            await client_manager.broadcast_bytes(data, source_id=mid)
            _frame_queue.put_nowait(data)

            if monitor_state["frame_count"] % 10 == 0:
                print(f"Received frame #{monitor_state['frame_count']} from {monitor_id}: {len(data)} bytes", flush=True)

    except WebSocketDisconnect:
        manager.disconnect(websocket)
        mark_monitor_offline(monitor_id)
        print(f"Monitor {monitor_id} disconnected normally.", flush=True)
    except Exception as e:
        manager.disconnect(websocket)
        mark_monitor_offline(monitor_id)
        print(f"Error: {e}", flush=True)

@app.websocket("/ws/client")
async def client_websocket(websocket: WebSocket, token: str = None, monitor: str = None):
    # Full access only: viewers can also send commands to the cameras.
    if not await ws_token_ok(token, ("ok",)):
        await websocket.close(code=1008)
        return
    # monitor=<id> narrows the stream to one camera; no param keeps the old
    # "every camera" behaviour for the web dashboard.
    await client_manager.connect(websocket, key=monitor or None)
    await manager.broadcast_text(json.dumps({"action": "set_fps", "fps": 5}), source_id=monitor or None)
    try:
        while True:
            message = await websocket.receive()
            # Viewers can send commands (e.g. "play a sound" on the monitor).
            text = message.get("text") if isinstance(message, dict) else None
            if text:
                forwarded = client_command_to_monitor(text)
                if forwarded:
                    await manager.broadcast_text(forwarded, source_id=monitor or None)
    except Exception:
        client_manager.disconnect(websocket)
        if len(client_manager.active.connections) == 0:
            await manager.broadcast_text(json.dumps({"action": "set_fps", "fps": 0.5}))


if os.path.exists("static"):
    app.mount("/", StaticFiles(directory="static", html=True), name="static")
else:
    @app.get("/")
    def read_root():
        return {"message": "PetTrack server is running (Web Dashboard not built)"}

async def ws_token_ok(token: str | None, allowed: tuple) -> bool:
    """WebSocket flavour of the API token rules: same scopes, same session
    revocation. The raw master secret keeps full access."""
    if not token_valid(token):
        return False
    payload = token_payload(token)
    if payload is not None:
        if payload.get("auth") not in allowed:
            return False
        sid = payload.get("sid")
        if sid and not await session_active(sid):
            return False
    return True

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run the PetTrack Server")
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose logging")
    args = parser.parse_args()

    log_level = "debug" if args.verbose else "info"

    # HTTPS when a certificate is configured (PETTRACK_TLS_CERT/KEY); plain
    # HTTP on the LAN otherwise. See README "HTTPS" for how to get a cert.
    ssl_cert = os.getenv("PETTRACK_TLS_CERT")
    ssl_key = os.getenv("PETTRACK_TLS_KEY")
    ssl_kwargs = {}
    if ssl_cert and ssl_key:
        ssl_kwargs = {"ssl_certfile": ssl_cert, "ssl_keyfile": ssl_key}

    uvicorn.run("main:app", host="0.0.0.0", port=9500, log_level=log_level, **ssl_kwargs)