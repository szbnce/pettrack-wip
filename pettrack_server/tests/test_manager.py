"""Viewer → monitor command forwarding (the "play a sound" button)."""
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
    import asyncio

    async def run():
        mgr = ConnectionManager()
        viewer_a, viewer_b, viewer_all = FakeSocket(), FakeSocket(), FakeSocket()
        await mgr.connect(viewer_a, key="cam_a")
        await mgr.connect(viewer_b, key="cam_b")
        await mgr.connect(viewer_all)  # no key = web dashboard behaviour

        await mgr.broadcast_bytes(b"frame-a", source_id="cam_a")

        assert viewer_a.sent_bytes == [b"frame-a"]
        assert viewer_b.sent_bytes == []
        assert viewer_all.sent_bytes == [b"frame-a"]

        await mgr.broadcast_text("cmd", source_id="cam_b")
        assert viewer_a.sent_text == []
        assert viewer_b.sent_text == ["cmd"]
        assert viewer_all.sent_text == ["cmd"]

    asyncio.run(run())


def test_disconnect_clears_the_watch_key():
    import asyncio

    async def run():
        mgr = ConnectionManager()
        sock = FakeSocket()
        await mgr.connect(sock, key="cam_a")
        mgr.disconnect(sock)
        assert sock not in mgr.active.connections
        assert sock not in mgr.keys

    asyncio.run(run())
