from fastapi import WebSocket
from typing import List
from types import SimpleNamespace
import asyncio
from collections import deque
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


class _Peer:
    """One socket plus its own sender, so no client can stall another.

    Frames are latest-wins: while a send is in flight, a newer frame
    replaces whatever is still queued. A viewer that cannot keep up skips
    to the present instead of building a backlog of stale seconds — that
    backlog is what turns a live stream into a time machine. Text
    messages (commands, fps changes) ride the same sender in order and
    are never dropped.
    """

    def __init__(self, websocket: WebSocket):
        self.websocket = websocket
        self.pending_frame: bytes | None = None
        self.pending_text: deque[str] = deque()
        self.dead = False
        self._busy = False
        self._task: asyncio.Task | None = None

    def offer_frame(self, data: bytes) -> None:
        self.pending_frame = data
        self._wake()

    def offer_text(self, text: str) -> None:
        self.pending_text.append(text)
        self._wake()

    def _wake(self) -> None:
        if self._busy or self.dead:
            return
        self._busy = True
        self._task = asyncio.create_task(self._drain())

    async def _drain(self) -> None:
        try:
            while self.pending_text or self.pending_frame is not None:
                while self.pending_text:
                    await self.websocket.send_text(self.pending_text.popleft())
                frame, self.pending_frame = self.pending_frame, None
                if frame is not None:
                    await self.websocket.send_bytes(frame)
        except Exception:
            # A dead socket must not wedge its queue. The next broadcast
            # sweeps the peer off the manager.
            self.dead = True
        finally:
            self._busy = False

    def cancel(self) -> None:
        self.dead = True
        if self._task is not None:
            self._task.cancel()


class ConnectionManager:
    def __init__(self):
        self.active = SimpleNamespace()
        self.active.connections: List[WebSocket] = []
        # Per-connection key: monitor id on the monitor side, watched monitor
        # id on the viewer side (None = interested in all of them).
        self.keys: dict = {}
        self.peers: dict = {}

    async def connect(self, websocket: WebSocket, key: str | None = None):
        await websocket.accept()
        self.active.connections.append(websocket)
        self.keys[websocket] = key
        self.peers[websocket] = _Peer(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active.connections:
            self.active.connections.remove(websocket)
        self.keys.pop(websocket, None)
        peer = self.peers.pop(websocket, None)
        if peer is not None:
            peer.cancel()

    def _recipients(self, source_id: str | None):
        for connection in self.active.connections:
            if watches_monitor(self.keys.get(connection), source_id):
                yield connection

    def _offer(self, websocket, frame: bytes | None = None, text: str | None = None):
        peer = self.peers.get(websocket)
        if peer is None:
            return
        if peer.dead:
            self.disconnect(websocket)
            return
        if frame is not None:
            peer.offer_frame(frame)
        if text is not None:
            peer.offer_text(text)

    async def broadcast_bytes(self, data: bytes, source_id: str | None = None):
        """Queue the newest frame on every matching viewer and return.

        Delivery runs on the per-peer senders above — one slow client
        delays only itself (and skips ahead to the newest frame)."""
        for connection in list(self._recipients(source_id)):
            self._offer(connection, frame=data)

    async def broadcast_text(self, text: str, source_id: str | None = None):
        for connection in list(self._recipients(source_id)):
            self._offer(connection, text=text)

    async def flush(self):
        """Wait until every queued send has settled.

        Tests and shutdown use this; the live path never needs to wait."""
        while True:
            tasks = [
                peer._task
                for peer in list(self.peers.values())
                if peer._task is not None and not peer._task.done()
            ]
            if not tasks:
                return
            await asyncio.gather(*tasks, return_exceptions=True)

manager = ConnectionManager()
client_manager = ConnectionManager()