from fastapi import WebSocket
from typing import List
from types import SimpleNamespace
import json


def client_command_to_monitor(raw: str) -> str | None:
    """Translate a viewer's JSON command into a monitor broadcast.

    Returns the message to forward to the monitor, or None when the raw
    text is not a command we know (talking viewers send nothing today).
    """
    try:
        cmd = json.loads(raw)
    except (TypeError, ValueError):
        return None
    if not isinstance(cmd, dict):
        return None
    if cmd.get("action") == "play_sound":
        return json.dumps({"action": "play_sound"})
    if cmd.get("action") == "night_mode":
        # Remote low-light toggle: torch/exposure/gamma on the monitor.
        return json.dumps({"action": "night_mode", "enabled": bool(cmd.get("enabled"))})
    return None


def watches_monitor(watch_id: str | None, source_id: str | None) -> bool:
    """Should a connection bound to watch_id receive traffic from source_id?

    A None on either side is a wildcard: an unfiltered viewer sees every
    camera (used by the web dashboard) and a frame with no known source goes
    out to everyone (backwards compatible single-camera setup).
    """
    return watch_id is None or source_id is None or watch_id == source_id


class ConnectionManager:
    def __init__(self):
        self.active = SimpleNamespace()
        self.active.connections: List[WebSocket] = []
        # Per-connection key: monitor id on the monitor side, watched monitor
        # id on the viewer side (None = interested in all of them).
        self.keys: dict = {}

    async def connect(self, websocket: WebSocket, key: str | None = None):
        await websocket.accept()
        self.active.connections.append(websocket)
        self.keys[websocket] = key

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active.connections:
            self.active.connections.remove(websocket)
        self.keys.pop(websocket, None)

    def _recipients(self, source_id: str | None):
        for connection in self.active.connections:
            if watches_monitor(self.keys.get(connection), source_id):
                yield connection

    async def broadcast_bytes(self, data: bytes, source_id: str | None = None):
        disconnected = []
        for connection in self._recipients(source_id):
            try:
                await connection.send_bytes(data)
            except Exception:
                disconnected.append(connection)
        for d in disconnected:
            self.disconnect(d)

    async def broadcast_text(self, text: str, source_id: str | None = None):
        disconnected = []
        for connection in self._recipients(source_id):
            try:
                await connection.send_text(text)
            except Exception:
                disconnected.append(connection)
        for d in disconnected:
            self.disconnect(d)

manager = ConnectionManager()
client_manager = ConnectionManager()