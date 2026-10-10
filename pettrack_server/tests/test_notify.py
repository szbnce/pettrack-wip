"""Remote alerts: the ntfy bridge, its settings and the quiet-hours fence."""
import asyncio
import os
from datetime import datetime

import pytest

import api_routes
import notify
import settings as app_settings
from database import log_event, save_pet

ENV_KEYS = (
    "PETTRACK_NTFY_URL",
    "PETTRACK_NTFY_TOKEN",
    "PETTRACK_NTFY_LANG",
    "PETTRACK_QUIET_ENABLED",
    "PETTRACK_QUIET_FROM",
    "PETTRACK_QUIET_TO",
)


@pytest.fixture(autouse=True)
def clean_env():
    """These tests read and write live env; keep them hermetic."""
    saved = {key: os.environ.pop(key, None) for key in ENV_KEYS}
    yield
    for key in ENV_KEYS:
        os.environ.pop(key, None)
    for key, value in saved.items():
        if value is not None:
            os.environ[key] = value


@pytest.fixture()
def pushes(monkeypatch):
    """Record what would have gone out on the wire."""
    sent = []

    def _fake_post(title, body, tags, priority):
        sent.append((title, body, tags, priority))
        return True

    monkeypatch.setattr(notify, "_post", _fake_post)
    return sent


def _login(client):
    return client.post(
        "/api/auth/login", json={"secret": api_routes.SECRET_TOKEN}
    ).json()["token"]


# --- settings ---------------------------------------------------------------


def test_remote_alert_settings_round_trip(client):
    headers = {"x-api-token": _login(client)}
    resp = client.post(
        "/api/settings",
        json={
            "ntfy_url": "https://ntfy.example/pettrack-demo",
            "ntfy_token": "tk_secret",
            "ntfy_lang": "hu",
            "quiet_hours_enabled": True,
            "quiet_hours_from": 23 * 60,
            "quiet_hours_to": 7 * 60,
        },
        headers=headers,
    )
    assert resp.status_code == 200
    after = client.get("/api/settings", headers=headers).json()
    assert after["ntfy_url"] == "https://ntfy.example/pettrack-demo"
    assert after["ntfy_token"] == "tk_secret"
    assert after["ntfy_lang"] == "hu"
    assert after["quiet_hours_enabled"] is True
    assert (after["quiet_hours_from"], after["quiet_hours_to"]) == (23 * 60, 7 * 60)


def test_settings_rejects_an_unpublishable_topic_url(client):
    headers = {"x-api-token": _login(client)}
    for bad in ("not a url", "ftp://example.com/pets"):
        assert (
            client.post(
                "/api/settings", json={"ntfy_url": bad}, headers=headers
            ).status_code
            == 400
        )
    assert client.get("/api/settings", headers=headers).json()["ntfy_url"] == ""


def test_settings_rejects_an_unknown_push_language(client):
    headers = {"x-api-token": _login(client)}
    resp = client.post("/api/settings", json={"ntfy_lang": "xx"}, headers=headers)
    assert resp.status_code == 400


# --- the bridge -------------------------------------------------------------


def test_a_zone_crossing_reaches_the_topic(pushes):
    os.environ["PETTRACK_NTFY_URL"] = "https://ntfy.example/pets"
    asyncio.run(log_event("zone_enter", zone_name="bed"))
    assert len(pushes) == 1
    title, body, tags, priority = pushes[0]
    assert "bed" in body
    assert title  # the pet's name, or the product name
    assert tags == "tada"


def test_a_zone_exit_stays_feed_only(pushes):
    os.environ["PETTRACK_NTFY_URL"] = "https://ntfy.example/pets"
    asyncio.run(log_event("zone_exit", zone_name="bed"))
    assert pushes == []


def test_no_topic_means_silence(pushes):
    asyncio.run(log_event("sound_detected", details="72 dB"))
    assert pushes == []


def test_watchdog_warnings_push_with_high_priority(pushes):
    os.environ["PETTRACK_NTFY_URL"] = "https://ntfy.example/pets"
    asyncio.run(log_event("camera_offline"))
    asyncio.run(log_event("disk_low"))
    assert [tags for _, _, tags, _ in pushes] == ["warning", "warning"]
    assert [priority for _, _, _, priority in pushes] == ["4", "4"]


def test_quiet_hours_mute_the_pet_not_the_product(pushes, monkeypatch):
    """Sleeping through a dead camera is the worst thing a surveillance
    tool can do. Quiet hours hush the dog; they do not hush the alarm."""
    os.environ["PETTRACK_NTFY_URL"] = "https://ntfy.example/pets"
    monkeypatch.setattr(app_settings, "is_quiet_now", lambda now=None: True)

    asyncio.run(log_event("zone_enter", zone_name="bed"))
    asyncio.run(log_event("sound_detected", details="72 dB"))
    assert pushes == []

    asyncio.run(log_event("camera_offline"))
    asyncio.run(log_event("disk_low"))
    assert [tags for _, _, tags, _ in pushes] == ["warning", "warning"]


def test_quiet_window_maths_match_the_app():
    os.environ["PETTRACK_QUIET_ENABLED"] = "1"
    os.environ["PETTRACK_QUIET_FROM"] = str(23 * 60)
    os.environ["PETTRACK_QUIET_TO"] = str(7 * 60)
    night = datetime(2026, 1, 1, 23, 30)
    morning_edge = datetime(2026, 1, 1, 6, 59)
    noon = datetime(2026, 1, 1, 12, 0)
    assert app_settings.is_quiet_now(night) is True
    assert app_settings.is_quiet_now(morning_edge) is True
    assert app_settings.is_quiet_now(noon) is False
    # from == to is an empty window
    os.environ["PETTRACK_QUIET_FROM"] = "600"
    os.environ["PETTRACK_QUIET_TO"] = "600"
    assert app_settings.is_quiet_now(noon) is False
    # and a disabled window is never quiet
    os.environ["PETTRACK_QUIET_ENABLED"] = "0"
    os.environ["PETTRACK_QUIET_FROM"] = str(23 * 60)
    os.environ["PETTRACK_QUIET_TO"] = str(7 * 60)
    assert app_settings.is_quiet_now(night) is False


def test_push_language_follows_the_app():
    os.environ["PETTRACK_NTFY_LANG"] = "hu"
    assert notify.format_message("disk_low") == "Kevés a lemezterület"
    assert "bed" in notify.format_message("zone_enter", zone_name="bed")
    # An unsaved language falls back to English rather than silence.
    os.environ["PETTRACK_NTFY_LANG"] = "xx"
    assert notify.format_message("disk_low") == "Disk space is low"


def test_the_pet_name_heads_the_push(pushes):
    os.environ["PETTRACK_NTFY_URL"] = "https://ntfy.example/pets"
    asyncio.run(save_pet("Berci", "rabbit"))
    asyncio.run(log_event("zone_enter", zone_name="bed"))
    assert pushes[0][0] == "Berci"


# --- the setup check --------------------------------------------------------


def test_test_endpoint_without_a_topic_is_400(client):
    headers = {"x-api-token": _login(client)}
    assert client.post("/api/notify/test", headers=headers).status_code == 400


def test_test_endpoint_delivers_even_in_quiet_hours(client, pushes, monkeypatch):
    headers = {"x-api-token": _login(client)}
    client.post(
        "/api/settings",
        json={"ntfy_url": "https://ntfy.example/pets"},
        headers=headers,
    )
    monkeypatch.setattr(app_settings, "is_quiet_now", lambda now=None: True)
    resp = client.post("/api/notify/test", headers=headers)
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok", "sent": True}
    assert len(pushes) == 1
    assert "PetTrack" in pushes[0][1]  # the test body names the product


def test_test_endpoint_reports_an_undeliverable_topic(client, monkeypatch):
    headers = {"x-api-token": _login(client)}
    client.post(
        "/api/settings",
        json={"ntfy_url": "https://ntfy.example/pets"},
        headers=headers,
    )
    monkeypatch.setattr(notify, "_post", lambda *args, **kwargs: False)
    assert client.post("/api/notify/test", headers=headers).status_code == 502


# --- the retry queue ---------------------------------------------------------
#
# A failed push is not a lost alert. A "your dog barked" that arrives twenty
# minutes late is still news; one that never arrives is the product failing
# at its one job.


@pytest.fixture(autouse=True)
def _clear_pending():
    notify.reset_pending()
    yield
    notify.reset_pending()


def test_a_failed_push_waits_for_another_go(pushes, monkeypatch):
    os.environ["PETTRACK_NTFY_URL"] = "https://ntfy.example/pets"
    monkeypatch.setattr(notify, "_post", lambda *a, **k: False)

    # Handled, not lost: the caller is told the alert is on its way.
    assert asyncio.run(
        notify.push_event("zone_enter", zone_name="bed")
    ) is True
    assert notify.pending_count() == 1

    # The topic comes back...
    def _recovered_post(title, body, tags, priority):
        pushes.append((title, body, tags, priority))
        return True

    monkeypatch.setattr(notify, "_post", _recovered_post)
    assert asyncio.run(notify.flush_pending()) == 1
    assert notify.pending_count() == 0
    assert len(pushes) == 1
    assert "bed" in pushes[0][1]


def test_the_retry_leaves_alone_alerts_that_went_out(pushes):
    os.environ["PETTRACK_NTFY_URL"] = "https://ntfy.example/pets"
    assert asyncio.run(notify.push_event("sound_detected", details="72 dB")) is True
    assert notify.pending_count() == 0
    assert asyncio.run(notify.flush_pending()) == 0
    assert len(pushes) == 1  # exactly one, not one plus a retry


def test_an_alert_older_than_an_hour_is_dropped_not_delivered(pushes, monkeypatch):
    """A stale 'your dog barked' is worse than silence."""
    os.environ["PETTRACK_NTFY_URL"] = "https://ntfy.example/pets"
    monkeypatch.setattr(notify, "_post", lambda *a, **k: False)
    asyncio.run(notify.push_event("sound_detected", details="72 dB"))
    assert notify.pending_count() == 1

    # Age it past the window.
    notify._pending[0].queued_at -= notify.MAX_ALERT_AGE + 1

    monkeypatch.setattr(notify, "_post", lambda *a, **k: True)
    assert asyncio.run(notify.flush_pending()) == 0
    assert notify.pending_count() == 0
    assert pushes == []


def test_a_full_queue_keeps_the_newest_news(monkeypatch):
    os.environ["PETTRACK_NTFY_URL"] = "https://ntfy.example/pets"
    monkeypatch.setattr(notify, "_post", lambda *a, **k: False)
    for i in range(notify.MAX_PENDING + 5):
        asyncio.run(notify.push_event("zone_enter", zone_name=f"z{i}"))
    assert notify.pending_count() == notify.MAX_PENDING
    # The oldest made room; the newest is still there.
    assert notify._pending[-1].zone_name == f"z{notify.MAX_PENDING + 4}"


def test_a_silent_topic_queue_is_not_an_endless_pile(monkeypatch):
    """No topic configured means nothing was ever meant to go out."""
    monkeypatch.setattr(notify, "_post", lambda *a, **k: False)
    assert asyncio.run(notify.push_event("zone_enter", zone_name="bed")) is False
    assert notify.pending_count() == 0
