"""Unit tests for the Home Assistant MQTT discovery bridge.

No broker needed: a fake client records publishes, and discovery payloads
are checked as plain data.
"""
import json

import pytest

import mqtt_bridge
from mqtt_bridge import MqttBridge


class FakeClient:
    def __init__(self):
        self.published = []  # (topic, payload, retain)

    def publish(self, topic, payload, retain=False):
        self.published.append((topic, payload, retain))

    def topics(self):
        return [t for t, _, _ in self.published]

    def payloads(self):
        return [p for _, p, _ in self.published]


@pytest.fixture
def bridge():
    """Enabled bridge with a fake client — publishing works without a broker."""
    b = MqttBridge(client=FakeClient())
    b._enabled = True
    return b


def test_discovery_messages_cover_all_entities(bridge):
    configs = dict(bridge.discovery_messages())
    kinds = {t.split("/")[1] for t in configs}
    assert kinds == {"binary_sensor", "sensor", "camera"}
    for topic, payload in configs.items():
        assert topic.startswith("homeassistant/")
        assert payload["unique_id"].startswith("pettrack_")
        assert payload["device"]["identifiers"] == ["pettrack"]
        assert "availability_topic" in payload


def test_discovery_camera_can_be_disabled(bridge, monkeypatch):
    monkeypatch.setenv("PETTRACK_MQTT_CAMERA_INTERVAL", "0")
    configs = dict(bridge.discovery_messages())
    assert not any(t.startswith("homeassistant/camera/") for t in configs)
    # Everything else still announced.
    assert any(t.startswith("homeassistant/binary_sensor/") for t in configs)


def test_publish_motion_only_on_change(bridge):
    bridge.publish_motion(True)
    bridge.publish_motion(True)  # no-op
    bridge.publish_motion(False)
    bridge.publish_motion(False)  # no-op
    assert bridge._client.payloads() == ["ON", "OFF"]
    assert bridge._client.topics() == ["pettrack/motion", "pettrack/motion"]
    # Motion is transient state: never retained.
    assert all(not r for _, _, r in bridge._client.published)


def test_publish_battery_and_charging(bridge):
    bridge.publish_battery(42, charging=True)
    assert ("pettrack/battery", "42", True) in bridge._client.published
    assert ("pettrack/charging", "ON", True) in bridge._client.published
    bridge.publish_battery(80, charging=False)
    assert ("pettrack/charging", "OFF", True) in bridge._client.published


def test_publish_monitor_and_availability(bridge):
    bridge.publish_monitor(True)
    bridge.publish_monitor(False)
    bridge.publish_availability(False)
    assert bridge._client.payloads() == ["ON", "OFF", "offline"]


def test_publish_event_labels_zone(bridge):
    bridge.publish_event("zone_enter", zone_name="Kitchen")
    assert bridge._client.published == [
        ("pettrack/last_event", "zone enter · Kitchen", False)
    ]
    bridge.publish_event("motion_start")
    assert bridge._client.published[-1][1] == "motion start"


def test_publish_frame_is_rate_limited(bridge, monkeypatch):
    monkeypatch.setenv("PETTRACK_MQTT_CAMERA_INTERVAL", "30")
    bridge.publish_frame(b"\xff\xd8frame")
    bridge.publish_frame(b"\xff\xd8next")
    assert bridge._client.payloads() == [b"\xff\xd8frame"]
    # Backdate the stamp: the next frame goes out.
    bridge._last_frame_publish -= 31
    bridge.publish_frame(b"\xff\xd8later")
    assert bridge._client.payloads()[-1] == b"\xff\xd8later"


def test_publish_frame_disabled_with_zero_interval(bridge, monkeypatch):
    monkeypatch.setenv("PETTRACK_MQTT_CAMERA_INTERVAL", "0")
    bridge.publish_frame(b"\xff\xd8frame")
    assert bridge._client.published == []


def test_on_connect_announces_configs_and_availability(bridge):
    mqtt_bridge._on_connect(bridge._client, bridge, None, 0)
    topics = bridge._client.topics()
    assert any(t.endswith("/motion/config") for t in topics)
    assert any(t.endswith("/battery/config") for t in topics)
    assert "pettrack/availability" in topics
    # Discovery configs are JSON blobs.
    for topic, payload, retain in bridge._client.published:
        if topic.endswith("/config"):
            json.loads(payload)
            assert retain


def test_disabled_bridge_is_a_no_op(monkeypatch):
    monkeypatch.delenv("PETTRACK_MQTT_HOST", raising=False)
    b = MqttBridge()
    assert b.start() is False
    b.publish_motion(True)
    b.publish_battery(10)
    b.publish_event("zone_exit", zone_name="Garden")
    b.publish_frame(b"jpeg")
    b.stop()
