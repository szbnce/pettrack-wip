"""Sessions, refresh rotation, logout revocation and scoped monitor tokens."""
import asyncio
import time

import jwt
import pytest

import auth
from api_routes import SECRET_TOKEN

PIN = "4242"


def _login(client):
    r = client.post("/api/auth/login", json={"secret": SECRET_TOKEN})
    assert r.status_code == 200, r.text
    return r.json()


# --- session shape -----------------------------------------------------------

def test_login_returns_access_and_refresh(client):
    body = _login(client)
    assert body["token"].startswith("eyJ")
    assert body["secret"] == body["token"]  # legacy clients read "secret"
    assert body["refresh_token"]
    assert body["expires_in"] == auth.ACCESS_TOKEN_TTL_SECONDS


def test_pin_login_can_mint_a_monitor_token(client):
    r = client.post("/api/auth/login_pin", json={"pin": PIN, "scope": "monitor"})
    assert r.status_code == 200
    body = r.json()
    claims = auth.token_payload(body["token"])
    assert claims["auth"] == "monitor"
    assert claims["sid"]


# --- refresh rotation --------------------------------------------------------

def test_refresh_rotates_the_refresh_token(client):
    body = _login(client)
    r = client.post("/api/auth/refresh", json={"refresh_token": body["refresh_token"]})
    assert r.status_code == 200
    fresh = r.json()
    assert fresh["refresh_token"] != body["refresh_token"]
    # The new access token works.
    assert client.get("/api/status", headers={"x-api-token": fresh["token"]}).status_code == 200


def test_refresh_reuse_kills_the_whole_family(client):
    body = _login(client)
    first = body["refresh_token"]
    second = client.post("/api/auth/refresh", json={"refresh_token": first}).json()
    # Presenting the rotated-out token again is treated as theft...
    assert client.post("/api/auth/refresh", json={"refresh_token": first}).status_code == 401
    # ...and the whole family dies, including the stolen-from successor.
    assert client.post("/api/auth/refresh", json={"refresh_token": second["refresh_token"]}).status_code == 401


def test_garbage_refresh_token_rejected(client):
    assert client.post("/api/auth/refresh", json={"refresh_token": "nope"}).status_code == 401


# --- logout revocation -------------------------------------------------------

def test_logout_revokes_access_tokens_too(client):
    body = _login(client)
    tok = body["token"]
    assert client.get("/api/status", headers={"x-api-token": tok}).status_code == 200
    r = client.post(
        "/api/auth/logout",
        json={"refresh_token": body["refresh_token"]},
        headers={"x-api-token": tok},
    )
    assert r.status_code == 200
    # The access token carries the session's sid — dead with the family.
    assert client.get("/api/status", headers={"x-api-token": tok}).status_code == 401
    assert client.post("/api/auth/refresh", json={"refresh_token": body["refresh_token"]}).status_code == 401


def test_logout_is_idempotent(client):
    body = _login(client)
    for _ in range(2):
        r = client.post("/api/auth/logout", json={"refresh_token": body["refresh_token"]})
        assert r.status_code == 200
        assert r.json()["status"] == "ok"


def test_monitor_logout_does_not_kill_other_sessions(client):
    viewer = _login(client)
    monitor = client.post("/api/auth/login_pin", json={"pin": PIN, "scope": "monitor"}).json()
    client.post("/api/auth/logout", json={"refresh_token": monitor["refresh_token"]})
    assert client.get("/api/status", headers={"x-api-token": viewer["token"]}).status_code == 200


# --- monitor scope -----------------------------------------------------------

def test_monitor_token_cannot_touch_the_rest(client):
    body = client.post("/api/auth/login_pin", json={"pin": PIN, "scope": "monitor"}).json()
    tok = body["token"]
    assert client.get("/api/pet", headers={"x-api-token": tok}).status_code == 403
    assert client.get("/api/zones", headers={"x-api-token": tok}).status_code == 403
    assert client.get("/api/status", headers={"x-api-token": tok}).status_code == 403
    assert client.get("/api/settings", headers={"x-api-token": tok}).status_code == 403
    # And it cannot change the pairing PIN either.
    r = client.post("/api/auth/set_pin", json={"pin": "1357"}, headers={"x-api-token": tok})
    assert r.status_code == 403


def test_monitor_token_can_do_monitor_work(client):
    body = client.post("/api/auth/login_pin", json={"pin": PIN, "scope": "monitor"}).json()
    tok = body["token"]
    r = client.post(
        "/api/monitor/update",
        json={"battery_level": 80, "is_charging": False, "monitor_id": "cam-scope"},
        headers={"x-api-token": tok},
    )
    assert r.status_code == 200, r.text
    r = client.post("/api/monitor/sound", json={"level": -12.5}, headers={"x-api-token": tok})
    assert r.status_code == 200, r.text
    r = client.post("/api/frame/web?token={}&monitor_id=cam-scope".format(tok), content=b"\xff\xd8frame")
    assert r.status_code == 200, r.text


def test_media_token_cannot_do_monitor_work(client):
    import os
    os.makedirs("replays", exist_ok=True)
    with open(os.path.join("replays", "scope.mp4"), "wb") as f:
        f.write(b"\x00\x00\x00\x18ftypmp42")
    tok = _login(client)["token"]
    media_tok = auth.mint_media_token("scope.mp4")
    r = client.post("/api/monitor/update", json={"battery_level": 1, "is_charging": False},
                    headers={"x-api-token": media_tok})
    assert r.status_code == 403


# --- persistent lockout ------------------------------------------------------

def test_lockout_counts_live_in_the_database(client):
    for _ in range(4):
        assert client.post("/api/auth/login_pin", json={"pin": "0000"}).status_code == 401
    # A fresh query — no module state involved — sees the four failures.
    assert asyncio.run(auth.failure_count("testclient")) == 4
    assert not asyncio.run(auth.is_locked_out("testclient"))
    client.post("/api/auth/login_pin", json={"pin": "0000"})
    assert asyncio.run(auth.is_locked_out("testclient"))


def test_lockout_also_guards_secret_login(client):
    for _ in range(5):
        assert client.post("/api/auth/login", json={"secret": "wrong"}).status_code == 401
    r = client.post("/api/auth/login", json={"secret": SECRET_TOKEN})
    assert r.status_code == 429


# --- legacy compatibility ----------------------------------------------------

def test_legacy_token_without_sid_still_accepted(client):
    old = jwt.encode(
        {"auth": "ok", "exp": time.time() + 86400 * 3650},
        SECRET_TOKEN,
        algorithm="HS256",
    )
    assert client.get("/api/status", headers={"x-api-token": old}).status_code == 200
