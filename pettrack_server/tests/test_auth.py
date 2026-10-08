"""Auth and endpoint-security tests for the PetTrack server API."""
import asyncio

import auth
from api_routes import SECRET_TOKEN

PIN = "4242"


# --- login_pin ---------------------------------------------------------------

def test_login_pin_returns_jwt_not_raw_secret(client):
    r = client.post("/api/auth/login_pin", json={"pin": PIN})
    assert r.status_code == 200, r.text
    body = r.json()
    # The "secret" key is kept for client compatibility, but it must carry a
    # JWT now — never the raw master secret.
    assert body["secret"] == body["token"]
    assert body["secret"].startswith("eyJ")
    assert body["secret"] != SECRET_TOKEN


def test_login_pin_rejects_wrong_pin(client):
    assert client.post("/api/auth/login_pin", json={"pin": "0000"}).status_code == 401


def test_login_pin_lockout_after_five_failures(client):
    for _ in range(5):
        assert client.post("/api/auth/login_pin", json={"pin": "0000"}).status_code == 401
    # Locked out now — even the correct PIN is refused.
    assert client.post("/api/auth/login_pin", json={"pin": PIN}).status_code == 429


def test_login_pin_clears_lockout_on_success(client):
    client.post("/api/auth/login_pin", json={"pin": "0000"})
    assert client.post("/api/auth/login_pin", json={"pin": PIN}).status_code == 200
    assert asyncio.run(auth.failure_count("testclient")) == 0


# --- token acceptance --------------------------------------------------------

def _pin_token(client):
    return client.post("/api/auth/login_pin", json={"pin": PIN}).json()["token"]


def test_jwt_accepted_via_header_and_query(client):
    tok = _pin_token(client)
    assert client.get("/api/status", headers={"x-api-token": tok}).status_code == 200
    assert client.get(f"/api/status?token={tok}").status_code == 200


def test_raw_secret_still_accepted_for_qr_provisioning(client):
    assert client.get("/api/status", headers={"x-api-token": SECRET_TOKEN}).status_code == 200


def test_bad_or_missing_tokens_rejected(client):
    assert client.get("/api/status").status_code == 401
    assert client.get("/api/status", headers={"x-api-token": "garbage"}).status_code == 401
    assert client.get("/api/status?token=garbage").status_code == 401


# --- login -------------------------------------------------------------------

def test_login_mints_jwt_for_secret_holder(client):
    r = client.post("/api/auth/login", json={"secret": SECRET_TOKEN})
    assert r.status_code == 200
    assert r.json()["token"].startswith("eyJ")


def test_login_rejects_wrong_secret(client):
    assert client.post("/api/auth/login", json={"secret": "nope"}).status_code == 401


# --- set_pin -----------------------------------------------------------------

def test_set_pin_validates_format(client):
    tok = _pin_token(client)
    for bad in ("abc", "12", "1234567890", ""):
        r = client.post("/api/auth/set_pin", json={"pin": bad}, headers={"x-api-token": tok})
        assert r.status_code == 422, bad


def test_set_pin_requires_auth(client):
    assert client.post("/api/auth/set_pin", json={"pin": "1357"}).status_code == 401


# --- endpoint hardening ------------------------------------------------------

def test_replay_path_traversal_rejected(client):
    tok = _pin_token(client)
    r = client.get("/api/replays/..%2F..%2Fetc%2Fpasswd", headers={"x-api-token": tok})
    assert r.status_code == 404


def test_protected_endpoints_require_token(client):
    for path in ("/api/zones", "/api/pet", "/api/activity", "/api/replays"):
        assert client.get(path).status_code == 401, path


# --- media tokens (signed replay links) --------------------------------------

def _make_replays(client):
    import os
    os.makedirs("replays", exist_ok=True)
    for name in ("clip.mp4", "other.mp4"):
        with open(os.path.join("replays", name), "wb") as f:
            f.write(b"\x00\x00\x00\x18ftypmp42")


def test_replay_listing_embeds_short_lived_url(client):
    _make_replays(client)
    tok = _pin_token(client)
    r = client.get("/api/replays", headers={"x-api-token": tok})
    assert r.status_code == 200
    by_name = {x["filename"]: x for x in r.json()["replays"]}
    assert by_name["clip.mp4"]["url"].startswith("/api/replays/clip.mp4?token=")
    media_tok = by_name["clip.mp4"]["url"].split("token=")[1]
    assert media_tok != tok and media_tok.startswith("eyJ")


def test_media_token_opens_only_its_own_file(client):
    _make_replays(client)
    tok = _pin_token(client)
    media_tok = client.get("/api/replays", headers={"x-api-token": tok}).json()["replays"]
    urls = {x["filename"]: x["url"] for x in media_tok}
    assert client.get(urls["clip.mp4"]).status_code == 200
    # Same token must not unlock the other file...
    stolen = urls["clip.mp4"].split("token=")[1]
    assert client.get(f"/api/replays/other.mp4?token={stolen}").status_code == 403
    # ...nor any general API endpoint.
    assert client.get(f"/api/pet?token={stolen}").status_code == 403
    assert client.get(f"/api/zones?token={stolen}").status_code == 403


# --- public health endpoint (connection-status chip) --------------------------

def test_health_needs_no_token(client):
    r = client.get("/api/health")
    assert r.status_code == 200
    body = r.json()
    assert body["ok"] is True
    assert isinstance(body["name"], str) and body["name"]


def test_health_is_public_even_with_any_token(client):
    # A media token is fine here too - health is public and says nothing secret.
    _make_replays(client)
    tok = _pin_token(client)
    media_tok = client.get("/api/replays", headers={"x-api-token": tok}).json()["replays"]
    stolen = media_tok[0]["url"].split("token=")[1]
    assert client.get(f"/api/health?token={stolen}").status_code == 200


# --- public version endpoint (app update check) ------------------------------

def test_version_needs_no_token(client):
    r = client.get("/api/version")
    assert r.status_code == 200
    body = r.json()
    # Dotted version, e.g. "1.0.0" — the app compares against its own.
    assert body["version"].count(".") == 2
    assert isinstance(body["name"], str) and body["name"]
