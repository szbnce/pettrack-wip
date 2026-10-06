"""Optional Home Assistant integration via MQTT discovery.

Publishes PetTrack's sensors and camera to an MQTT broker using Home
Assistant's MQTT discovery protocol, so everything shows up in Home
Assistant without any yaml. Disabled unless PETTRACK_MQTT_HOST is set.
Requires the `paho-mqtt` package (in requirements.txt); if it is missing,
the server just runs without the bridge.

Environment:
  PETTRACK_MQTT_HOST                 broker host (unset/empty = disabled)
  PETTRACK_MQTT_PORT                 (default 1883)
  PETTRACK_MQTT_USER / PETTRACK_MQTT_PASSWORD
  PETTRACK_MQTT_DISCOVERY_PREFIX     (default "homeassistant")
  PETTRACK_MQTT_BASE                 state topic prefix (default "pettrack")
  PETTRACK_MQTT_CAMERA_INTERVAL      seconds between camera snapshots
                                     (default 30, 0 = no camera entity)
"""
import json
import os
import socket
import time

# Discovery/state topics. Availability is shared so one LWT covers the device.
TOPIC_AVAILABILITY = "availability"
TOPIC_MONITOR = "monitor"
TOPIC_MOTION = "motion"
TOPIC_BATTERY = "battery"
TOPIC_CHARGING = "charging"
TOPIC_LAST_EVENT = "last_event"
TOPIC_CAMERA = "camera/image"


def _env(name: str, default: str = "") -> str:
    return os.getenv(name, default).strip()


def _camera_interval() -> float:
    try:
        return max(0.0, float(_env("PETTRACK_MQTT_CAMERA_INTERVAL", "30")))
    except ValueError:
        return 30.0


class MqttBridge:
    """Thin publisher around a paho-mqtt client.

    A [client] can be injected for tests; it only needs `publish()` and
    `user_data_set()`-style wiring is done by [start].
    """

    def __init__(self, client=None):
        self._client = client
        self._enabled = bool(_env("PETTRACK_MQTT_HOST"))
        self._started = False
        self._last_frame_publish = 0.0
        self._motion_on = False

    # -- topics -----------------------------------------------------------
    @property
    def _base(self) -> str:
        return _env("PETTRACK_MQTT_BASE", "pettrack").rstrip("/")

    @property
    def _discovery_prefix(self) -> str:
        return _env("PETTRACK_MQTT_DISCOVERY_PREFIX", "homeassistant").rstrip("/")

    def _state_topic(self, topic: str) -> str:
        return f"{self._base}/{topic}"

    # -- discovery payloads ----------------------------------------------
    def discovery_messages(self) -> list[tuple[str, dict]]:
        """(config topic, payload) pairs for every HA entity we expose."""
        base = self._base
        device = {
            "identifiers": ["pettrack"],
            "name": "PetTrack",
            "manufacturer": "PetTrack",
            "model": "Self-hosted pet monitor",
        }
        avail = {  # shared availability fragment
            "availability_topic": f"{base}/{TOPIC_AVAILABILITY}",
            "payload_available": "online",
            "payload_not_available": "offline",
            "device": device,
        }

        configs = [
            (
                "binary_sensor/pettrack/motion/config",
                {
                    **avail,
                    "name": "Motion",
                    "unique_id": "pettrack_motion",
                    "device_class": "motion",
                    "state_topic": f"{base}/{TOPIC_MOTION}",
                    "payload_on": "ON",
                    "payload_off": "OFF",
                },
            ),
            (
                "binary_sensor/pettrack/monitor/config",
                {
                    **avail,
                    "name": "Monitor online",
                    "unique_id": "pettrack_monitor",
                    "device_class": "connectivity",
                    "state_topic": f"{base}/{TOPIC_MONITOR}",
                    "payload_on": "ON",
                    "payload_off": "OFF",
                },
            ),
            (
                "sensor/pettrack/battery/config",
                {
                    **avail,
                    "name": "Monitor battery",
                    "unique_id": "pettrack_battery",
                    "device_class": "battery",
                    "unit_of_measurement": "%",
                    "state_topic": f"{base}/{TOPIC_BATTERY}",
                },
            ),
            (
                "binary_sensor/pettrack/charging/config",
                {
                    **avail,
                    "name": "Monitor charging",
                    "unique_id": "pettrack_charging",
                    "device_class": "battery_charging",
                    "state_topic": f"{base}/{TOPIC_CHARGING}",
                    "payload_on": "ON",
                    "payload_off": "OFF",
                },
            ),
            (
                "sensor/pettrack/last_event/config",
                {
                    **avail,
                    "name": "Last event",
                    "unique_id": "pettrack_last_event",
                    "icon": "mdi:paw",
                    "state_topic": f"{base}/{TOPIC_LAST_EVENT}",
                },
            ),
        ]

        if _camera_interval() > 0:
            configs.append(
                (
                    "camera/pettrack/camera/config",
                    {
                        **avail,
                        "name": "Camera",
                        "unique_id": "pettrack_camera",
                        "topic": f"{base}/{TOPIC_CAMERA}",
                    },
                )
            )
        return [
            (f"{self._discovery_prefix}/{path}", payload)
            for path, payload in configs
        ]

    # -- lifecycle ---------------------------------------------------------
    def start(self) -> bool:
        """Connect to the broker and publish discovery configs."""
        if not self._enabled or self._started:
            return self._started
        host = _env("PETTRACK_MQTT_HOST")
        port = int(_env("PETTRACK_MQTT_PORT", "1883") or 1883)
        try:
            import paho.mqtt.client as mqtt
        except ImportError:
            print("MQTT bridge: paho-mqtt not installed, skipping", flush=True)
            return False

        if self._client is None:
            try:
                # paho-mqtt 2.x requires the callback API version; 1.x rejects it.
                self._client = mqtt.Client(
                    mqtt.CallbackAPIVersion.VERSION1,
                    client_id=f"pettrack-{socket.gethostname()}",
                )
            except (AttributeError, TypeError):
                self._client = mqtt.Client(
                    client_id=f"pettrack-{socket.gethostname()}"
                )
            user = _env("PETTRACK_MQTT_USER")
            if user:
                self._client.username_pw_set(user, _env("PETTRACK_MQTT_PASSWORD"))

        self._client.user_data_set(self)
        self._client.on_connect = _on_connect
        self._client.on_disconnect = _on_disconnect
        # Home Assistant marks the device offline if we drop without saying so.
        self._client.will_set(
            self._state_topic(TOPIC_AVAILABILITY), "offline", retain=True
        )
        try:
            self._client.connect(host, port, keepalive=60)
            self._client.loop_start()
        except Exception as e:
            print(f"MQTT bridge: failed to connect to {host}:{port}: {e}", flush=True)
            self._client = None
            return False

        self._started = True
        print(f"MQTT bridge: connected to {host}:{port}", flush=True)
        return True

    def stop(self) -> None:
        if self._client is None:
            return
        try:
            self.publish_availability(False)
            self._client.loop_stop()
            self._client.disconnect()
        except Exception:
            pass
        self._client = None
        self._started = False

    # -- publishing ---------------------------------------------------------
    def _publish(self, topic: str, payload: str, retain: bool = True) -> None:
        if self._client is None:
            return
        try:
            self._client.publish(self._state_topic(topic), payload, retain=retain)
        except Exception as e:
            print(f"MQTT bridge: publish failed: {e}", flush=True)

    def publish_availability(self, online: bool) -> None:
        self._publish(TOPIC_AVAILABILITY, "online" if online else "offline")

    def publish_motion(self, active: bool) -> None:
        if active == self._motion_on:
            return
        self._motion_on = active
        self._publish(TOPIC_MOTION, "ON" if active else "OFF", retain=False)

    def publish_battery(self, level: int, charging: bool = False) -> None:
        self._publish(TOPIC_BATTERY, str(int(level)))
        self._publish(TOPIC_CHARGING, "ON" if charging else "OFF")

    def publish_monitor(self, online: bool) -> None:
        self._publish(TOPIC_MONITOR, "ON" if online else "OFF")

    def publish_event(self, event_type: str, zone_name: str = None) -> None:
        label = event_type.replace("_", " ")
        if zone_name:
            label = f"{label} · {zone_name}"
        self._publish(TOPIC_LAST_EVENT, label, retain=False)

    def publish_frame(self, jpeg: bytes) -> None:
        """Snapshot for the HA camera entity, rate-limited."""
        if self._client is None or not jpeg:
            return
        interval = _camera_interval()
        if interval <= 0:
            return
        now = time.time()
        if now - self._last_frame_publish < interval:
            return
        self._last_frame_publish = now
        try:
            self._client.publish(self._state_topic(TOPIC_CAMERA), jpeg, retain=True)
        except Exception as e:
            print(f"MQTT bridge: frame publish failed: {e}", flush=True)


def _on_connect(client, userdata, flags, rc, *args):
    bridge: MqttBridge = userdata
    for topic, payload in bridge.discovery_messages():
        client.publish(topic, json.dumps(payload), retain=True)
    bridge.publish_availability(True)
    print("MQTT bridge: discovery configs published", flush=True)


def _on_disconnect(client, userdata, rc, *args):
    if rc != 0:
        print(f"MQTT bridge: unexpected disconnect (rc={rc})", flush=True)


# Module-level singleton: the rest of the server talks to this one.
bridge = MqttBridge()


def start() -> bool:
    return bridge.start()


def stop() -> None:
    bridge.stop()
