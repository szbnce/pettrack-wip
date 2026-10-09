"""Viewer → monitor command forwarding (the "play a sound" button), and
the fan-out contract behind the < 1 s stream-latency target."""
import asyncio
import json

from manager import ConnectionManager, client_command_to_monitor, watches_monitor


class FakeSocket:
    """Stands in for a WebSocket; records what was sent to it."""

    def __init__(self):
        self.sent_bytes = []
        self.sent_text = []
        self.accepted = False

    async def accept(self):
        self.accepted = True

    async def send_bytes(self, data):
        self.sent_bytes.append(data)

    async def send_text(self, text):
        self.sent_text.append(text)


class StuckSocket(FakeSocket):
    """A client whose TCP buffer is full — sends wait on [gate]."""

    def __init__(self, gate: asyncio.Event):
        super().__init__()
        self.gate = gate

    async def send_bytes(self, data):
        await self.gate.wait()
        self.sent_bytes.append(data)


class DeadSocket(FakeSocket):
    """A client that vanished mid-send."""

    async def send_bytes(self, data):
        raise ConnectionResetError("gone")

    async def send_text(self, text):
        raise ConnectionResetError("gone")


def test_play_sound_command_is_forwarded():
    assert client_command_to_monitor('{"action": "play_sound"}') == (
        '{"action": "play_sound"}'
    )


def test_night_mode_command_is_forwarded_with_flag():
    on = json.loads(client_command_to_monitor('{"action": "night_mode", "enabled": true}'))
    assert on == {"action": "night_mode", "enabled": True}
    off = json.loads(client_command_to_monitor('{"action": "night_mode"}'))
    assert off == {"action": "night_mode", "enabled": False}


def test_unknown_commands_are_dropped():
    assert client_command_to_monitor('{"action": "nuke"}') is None
    assert client_command_to_monitor('not json') is None
    assert client_command_to_monitor('') is None
    assert client_command_to_monitor('["play_sound"]') is None


def test_watches_monitor_wildcards():
    assert watches_monitor(None, "cam_a")  # unfiltered viewer sees everything
    assert watches_monitor("cam_a", None)  # unknown source goes to everyone
    assert watches_monitor("cam_a", "cam_a")
    assert not watches_monitor("cam_a", "cam_b")


def test_frames_are_routed_per_camera():
    async def run():
        mgr = ConnectionManager()
        viewer_a, viewer_b, viewer_all = FakeSocket(), FakeSocket(), FakeSocket()
        await mgr.connect(viewer_a, key="cam_a")
        await mgr.connect(viewer_b, key="cam_b")
        await mgr.connect(viewer_all)  # no key = web dashboard behaviour

        await mgr.broadcast_bytes(b"frame-a", source_id="cam_a")
        await mgr.flush()

        assert viewer_a.sent_bytes == [b"frame-a"]
        assert viewer_b.sent_bytes == []
        assert viewer_all.sent_bytes == [b"frame-a"]

        await mgr.broadcast_text("cmd", source_id="cam_b")
        await mgr.flush()
        assert viewer_a.sent_text == []
        assert viewer_b.sent_text == ["cmd"]
        assert viewer_all.sent_text == ["cmd"]

    asyncio.run(run())


def test_a_stuck_client_never_delays_the_others():
    """One full TCP buffer must not become everyone's latency."""

    async def run():
        mgr = ConnectionManager()
        gate = asyncio.Event()  # closed = the slow client's buffer is full
        slow, fast = StuckSocket(gate), FakeSocket()
        await mgr.connect(slow, key="cam_a")
        await mgr.connect(fast, key="cam_a")

        await mgr.broadcast_bytes(b"f1", source_id="cam_a")
        await asyncio.sleep(0)  # let the per-peer senders run

        # The healthy client has its frame while the stuck one is still
        # waiting on its socket — delivery is per-peer, never serial.
        assert fast.sent_bytes == [b"f1"]
        assert slow.sent_bytes == []

        gate.set()
        await mgr.flush()
        assert slow.sent_bytes == [b"f1"]

    asyncio.run(run())


def test_a_lagging_client_skips_to_the_newest_frame():
    """Latest-wins: the backlog of stale frames is dropped, not replayed."""

    async def run():
        mgr = ConnectionManager()
        gate = asyncio.Event()
        slow = StuckSocket(gate)
        await mgr.connect(slow, key="cam_a")

        await mgr.broadcast_bytes(b"f1", source_id="cam_a")
        await asyncio.sleep(0)  # f1 is now stuck in flight
        await mgr.broadcast_bytes(b"f2", source_id="cam_a")
        await mgr.broadcast_bytes(b"f3", source_id="cam_a")

        gate.set()
        await mgr.flush()

        # In-flight f1 finishes, then the queue skips straight to f3.
        assert slow.sent_bytes == [b"f1", b"f3"]

    asyncio.run(run())


def test_text_commands_are_never_dropped_and_keep_order():
    async def run():
        mgr = ConnectionManager()
        sock = FakeSocket()
        await mgr.connect(sock, key="cam_a")

        await mgr.broadcast_text("cmd-1", source_id="cam_a")
        await mgr.broadcast_bytes(b"f1", source_id="cam_a")
        await mgr.broadcast_text("cmd-2", source_id="cam_a")
        await mgr.flush()

        assert sock.sent_text == ["cmd-1", "cmd-2"]
        assert sock.sent_bytes == [b"f1"]

    asyncio.run(run())


def test_a_dead_socket_is_swept_off_the_manager():
    async def run():
        mgr = ConnectionManager()
        dead, alive = DeadSocket(), FakeSocket()
        await mgr.connect(dead, key="cam_a")
        await mgr.connect(alive, key="cam_a")

        await mgr.broadcast_bytes(b"f1", source_id="cam_a")
        await mgr.flush()
        await mgr.broadcast_bytes(b"f2", source_id="cam_a")  # sweeps the dead peer
        await mgr.flush()

        assert dead not in mgr.active.connections
        assert alive.sent_bytes == [b"f1", b"f2"]

    asyncio.run(run())


def test_disconnect_clears_the_watch_key():
    async def run():
        mgr = ConnectionManager()
        sock = FakeSocket()
        await mgr.connect(sock, key="cam_a")
        mgr.disconnect(sock)
        assert sock not in mgr.active.connections
        assert sock not in mgr.keys

    asyncio.run(run())
