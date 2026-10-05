"""Auth and endpoint-security tests for the PetTrack server API."""
import api_routes
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
    assert not api_routes.failed_login_attempts


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
