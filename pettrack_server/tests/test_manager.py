"""Viewer → monitor command forwarding (the "play a sound" button)."""
import json

from manager import client_command_to_monitor


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
