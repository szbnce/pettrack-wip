"""Tests for mDNS advertisement (zeroconf mocked, no real network)."""
import sys
import types

import pytest

import discovery


class _FakeServiceInfo:
    def __init__(self, type_, name, addresses, port, properties):
        self.type = type_
        self.name = name
        self.addresses = addresses
        self.port = port
        self.properties = properties


class _FakeZeroconf:
    instances = []

    def __init__(self):
        self.registered = []
        self.closed = False
        _FakeZeroconf.instances.append(self)

    def register_service(self, info):
        self.registered.append(info)

    def unregister_service(self, info):
        self.registered.remove(info)

    def close(self):
        self.closed = True


@pytest.fixture(autouse=True)
def _reset(monkeypatch):
    discovery.stop_advertiser()
    _FakeZeroconf.instances.clear()
    fake = types.SimpleNamespace(Zeroconf=_FakeZeroconf, ServiceInfo=_FakeServiceInfo)
    monkeypatch.setitem(sys.modules, "zeroconf", fake)
    yield
    discovery.stop_advertiser()


def test_advertises_pettrack_service():
    assert discovery.start_advertiser(ip="192.168.1.10", port=8000)
    zc = _FakeZeroconf.instances[-1]
    assert len(zc.registered) == 1
    info = zc.registered[0]
    assert info.type == "_pettrack._tcp.local."
    assert info.name.endswith("._pettrack._tcp.local.")
    assert info.port == 8000
    assert info.properties.get("app") == "pettrack"
    assert info.properties.get("name")


def test_mdns_off_skips_advertisement(monkeypatch):
    monkeypatch.setenv("PETTRACK_MDNS", "off")
    assert not discovery.start_advertiser(ip="192.168.1.10", port=8000)
    assert _FakeZeroconf.instances == []


def test_instance_name_env_override(monkeypatch):
    monkeypatch.setenv("PETTRACK_MDNS_NAME", "my.server")
    assert discovery._instance_name() == "my-server"


def test_start_is_idempotent():
    assert discovery.start_advertiser(ip="10.0.0.2", port=8000)
    assert discovery.start_advertiser(ip="10.0.0.2", port=8000)
    assert len(_FakeZeroconf.instances) == 1


def test_stop_unregisters_and_closes():
    discovery.start_advertiser(ip="10.0.0.2", port=8000)
    zc = _FakeZeroconf.instances[-1]
    discovery.stop_advertiser()
    assert zc.registered == []
    assert zc.closed
    # And a second stop is a no-op.
    discovery.stop_advertiser()


def test_missing_zeroconf_degrades_gracefully(monkeypatch):
    monkeypatch.setitem(sys.modules, "zeroconf", None)  # import raises ImportError
    assert not discovery.start_advertiser(ip="10.0.0.2", port=8000)
