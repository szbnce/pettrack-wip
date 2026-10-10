"""Remote alerts: forward events to an ntfy topic so they reach you anywhere.

The phone app can only notify while it is running; this bridge makes the
interesting events (zone crossings, barks, watchdog warnings) arrive via
ntfy — in the ntfy app, a browser, or wherever the topic is subscribed —
so a barking dog is news at work too. Opt-in: nothing is sent until a
topic URL is saved in Settings → Alerts, and the app's quiet-hours window
is honoured the same way local notifications honour it.

Quiet hours mute the pet, not the product. A camera that went dark or a
disk that filled up is the tool saying it is broken, and that has to
reach you whether or not the house is asleep.

Message copy lives here rather than in the app's .arb files because the
push is sent when no UI is open; it follows the language the app saved
(ntfy_lang)."""
import asyncio
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from email.header import Header

import settings as app_settings

# What becomes a push. zone_exit is only half a story (someone left) and
# would double the noise, so it stays feed-only.
PUSH_EVENTS = {"zone_enter", "sound_detected", "camera_offline", "disk_low"}

# The product telling you it is broken. These punch through quiet hours —
# sleeping through a dead camera is the worst failure mode a surveillance
# tool has.
HEALTH_EVENTS = {"camera_offline", "disk_low"}

_TAGS = {
    "zone_enter": "tada",
    "sound_detected": "bell",
    "camera_offline": "warning",
    "disk_low": "warning",
    "test": "white_check_mark",
}
_PRIORITY = {"camera_offline": "4", "disk_low": "4"}

_TITLES = {
    "zone_enter": {
        "en": "Entered the {zone} zone",
        "de": "Zone {zone} betreten",
        "hu": "Belépett a(z) {zone} zónába",
        "it": "È entrato nella zona {zone}",
        "ja": "{zone} ゾーンに入りました",
        "ko": "{zone} 구역에 들어왔습니다",
        "zh": "进入了 {zone} 区域",
    },
    "sound_detected": {
        "en": "Sound detected ({details})",
        "de": "Geräusch erkannt ({details})",
        "hu": "Hangot észleltünk ({details})",
        "it": "Suono rilevato ({details})",
        "ja": "音を検知しました（{details}）",
        "ko": "소리 감지 ({details})",
        "zh": "检测到声音（{details}）",
    },
    "camera_offline": {
        "en": "Camera went offline",
        "de": "Kamera ist offline",
        "hu": "A kamera offline lett",
        "it": "La fotocamera è andata offline",
        "ja": "カメラがオフラインになりました",
        "ko": "카메라가 오프라인 상태입니다",
        "zh": "摄像头已离线",
    },
    "disk_low": {
        "en": "Disk space is low",
        "de": "Wenig Speicherplatz",
        "hu": "Kevés a lemezterület",
        "it": "Spazio su disco in esaurimento",
        "ja": "ディスクの空き容量が不足しています",
        "ko": "디스크 공간이 부족합니다",
        "zh": "磁盘空间不足",
    },
    "test": {
        "en": "Test notification — PetTrack alerts are working",
        "de": "Testbenachrichtigung — PetTrack-Warnungen funktionieren",
        "hu": "Teszt értesítés — a PetTrack riasztásai működnek",
        "it": "Notifica di prova — gli avvisi di PetTrack funzionano",
        "ja": "テスト通知 — PetTrackのアラートは動作しています",
        "ko": "테스트 알림 — PetTrack 경보가 작동 중입니다",
        "zh": "测试通知 — PetTrack 警报工作正常",
    },
}


def format_message(event_type: str, zone_name: str = None, details: str = None) -> str | None:
    """The push body for an event in the saved language, or None if the
    event type is not a thing we phrase."""
    table = _TITLES.get(event_type)
    if not table:
        return None
    text = table.get(app_settings.get_ntfy_lang()) or table["en"]
    return text.replace("{zone}", zone_name or "?").replace("{details}", details or "")


def _post(title: str, body: str, tags: str, priority: str) -> bool:
    """One blocking HTTP POST to the topic URL — runs in a worker thread.

    urllib keeps the server dependency-free (ntfy publishing is one POST);
    the title rides as an RFC 2047 word so accented text survives the
    latin-1 header rules."""
    url = app_settings.get_ntfy_url()
    if not url:
        return False
    request = urllib.request.Request(url, data=body.encode("utf-8"), method="POST")
    request.add_header("Title", str(Header(title, "utf-8")))
    request.add_header("Tags", tags)
    request.add_header("Priority", priority)
    request.add_header("Content-Type", "text/plain; charset=utf-8")
    token = app_settings.get_ntfy_token()
    if token:
        request.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            return 200 <= response.status < 300
    except (urllib.error.URLError, OSError, ValueError) as e:
        print(f"ntfy bridge: publish failed: {e}", flush=True)
        return False


async def _publish(title: str, body: str, event_type: str) -> bool:
    """Fire the POST off the event loop; a slow topic must never stall
    the frame pipeline that logged the event."""
    return await asyncio.to_thread(
        _post, title, body, _TAGS.get(event_type, "bell"), _PRIORITY.get(event_type, "3")
    )


async def _publish_for(event_type: str, zone_name: str = None, details: str = None) -> bool:
    body = format_message(event_type, zone_name, details)
    if body is None:
        return False
    # Lazy import: notify is called from database.log_event, so importing
    # the database at module load would close an import cycle.
    from database import get_pet

    pet = await get_pet()
    title = (pet or {}).get("name") or "PetTrack"
    return await _publish(title, body, event_type)


# --- the retry queue ---------------------------------------------------------
#
# A failed push is not a lost alert. A "your dog barked" that arrives twenty
# minutes late is still news; one that never arrives is the product failing
# at its one job. Anything that cannot go out waits here and the retry loop
# in tasks.py walks it until it lands.
#
# Kept in memory on purpose: the common failure is a ntfy blip measured in
# seconds to minutes, and the events themselves are in the feed either way.
# Alerts older than an hour are dropped — a stale alert is worse than silence.


MAX_ALERT_AGE = 60 * 60
MAX_PENDING = 100


@dataclass
class _Pending:
    event_type: str
    zone_name: str | None = None
    details: str | None = None
    queued_at: float = field(default_factory=time.time)
    attempts: int = 0


_pending: list[_Pending] = []


def pending_count() -> int:
    return len(_pending)


def reset_pending() -> None:
    _pending.clear()


def _queue(event_type: str, zone_name: str | None, details: str | None) -> bool:
    if len(_pending) >= MAX_PENDING:
        # A full queue is a long outage — keep the newest news.
        _pending.pop(0)
    _pending.append(_Pending(event_type, zone_name, details))
    return True


async def flush_pending() -> int:
    """Retry whatever is waiting. Returns how many landed this pass."""
    if not _pending or not app_settings.get_ntfy_url():
        return 0
    now = time.time()
    landed = 0
    for item in list(_pending):
        if now - item.queued_at > MAX_ALERT_AGE:
            _pending.remove(item)
            continue
        item.attempts += 1
        if await _publish_for(item.event_type, item.zone_name, item.details):
            _pending.remove(item)
            landed += 1
    return landed


async def push_event(event_type: str, zone_name: str = None, details: str = None) -> bool:
    """Push one interesting event, unless config or quiet hours say no.

    Returns True when the alert is on its way — either delivered or waiting
    for a retry — and False only when we never intend to send it."""
    if event_type not in PUSH_EVENTS:
        return False
    if not app_settings.get_ntfy_url():
        return False
    if app_settings.is_quiet_now() and event_type not in HEALTH_EVENTS:
        return False
    if await _publish_for(event_type, zone_name, details):
        return True
    return _queue(event_type, zone_name, details)


async def push_test() -> bool:
    """A deliberate setup check — ignores quiet hours, like the in-app
    test-notification button does. Never queued: the button is asking
    "does it work right now", not "will it work eventually"."""
    if not app_settings.get_ntfy_url():
        return False
    return await _publish_for("test")
