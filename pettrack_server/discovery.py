"""Optional LAN discovery: advertise the server over mDNS as _pettrack._tcp.

The apps can then find the server on the local network without anyone
typing an IP address. Requires the `zeroconf` package (in
requirements.txt); if it is missing, the server just starts without
discovery.

Environment:
  PETTRACK_MDNS=auto|off   (default: auto)
  PETTRACK_MDNS_NAME=...   (instance name, default: machine hostname)
"""
import os
import socket

SERVICE_TYPE = "_pettrack._tcp.local."

_zeroconf = None
_info = None


def _instance_name() -> str:
    raw = os.getenv("PETTRACK_MDNS_NAME") or socket.gethostname() or "pettrack"
    # mDNS instance names may not contain dots.
    return raw.replace(".", "-")[:63]


def start_advertiser(ip: str, port: int) -> bool:
    """Advertise this server on the LAN. Safe to call once at startup."""
    global _zeroconf, _info
    if os.getenv("PETTRACK_MDNS", "auto").strip().lower() == "off":
        return False
    if _zeroconf is not None:
        return True
    try:
        from zeroconf import ServiceInfo, Zeroconf
    except ImportError:
        print("mDNS discovery: zeroconf not installed, skipping", flush=True)
        return False

    name = _instance_name()
    try:
        _info = ServiceInfo(
            SERVICE_TYPE,
            f"{name}.{SERVICE_TYPE}",
            addresses=[socket.inet_aton(ip)],
            port=port,
            properties={"name": name, "app": "pettrack"},
        )
        _zeroconf = Zeroconf()
        _zeroconf.register_service(_info)
    except Exception as e:
        print(f"mDNS discovery: failed to advertise: {e}", flush=True)
        _zeroconf = None
        _info = None
        return False

    print(f"mDNS discovery: advertising '{name}' at {ip}:{port}", flush=True)
    return True


def stop_advertiser() -> None:
    """Unregister and close; no-op when discovery is not running."""
    global _zeroconf, _info
    if _zeroconf is None:
        return
    try:
        if _info is not None:
            _zeroconf.unregister_service(_info)
        _zeroconf.close()
    except Exception:
        pass
    _zeroconf = None
    _info = None
