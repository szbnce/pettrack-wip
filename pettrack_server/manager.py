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
    if isinstance(cmd, dict) and cmd.get("action") == "play_sound":
        return json.dumps({"action": "play_sound"})
    return None


class ConnectionManager:
    def __init__(self):
        self.active = SimpleNamespace()
        self.active.connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active.connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active.connections:
            self.active.connections.remove(websocket)

    async def broadcast_bytes(self, data: bytes):
        disconnected = []
        for connection in self.active.connections:
            try:
                await connection.send_bytes(data)
            except Exception:
                disconnected.append(connection)
        for d in disconnected:
            self.disconnect(d)

    async def broadcast_text(self, text: str):
        disconnected = []
        for connection in self.active.connections:
            try:
                await connection.send_text(text)
            except Exception:
                disconnected.append(connection)
        for d in disconnected:
            self.disconnect(d)

manager = ConnectionManager()
client_manager = ConnectionManager()