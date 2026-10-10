"""Delete a clip now: the false alarm, the knocked-over camera.

Deletion is irreversible, so it asks for a full session token and leaves
nothing behind — not the file, not its pin.
"""
import os

import api_routes
import pins


def _login(client):
    return client.post(
        "/api/auth/login", json={"secret": api_routes.SECRET_TOKEN}
    ).json()["token"]


def _monitor_token(client):
    return client.post(
        "/api/auth/login",
        json={"secret": api_routes.SECRET_TOKEN, "scope": "monitor"},
    ).json()["token"]


def _make_clip(name="doomed.mp4"):
    os.makedirs("replays", exist_ok=True)
    with open(f"replays/{name}", "wb") as f:
        f.write(b"video bytes")
    return name


def test_delete_removes_the_file_and_says_so(client):
    token = _login(client)
    name = _make_clip("gone.mp4")

    resp = client.delete(
        f"/api/replays/{name}", headers={"x-api-token": token}
    )
    assert resp.status_code == 200
    assert resp.json() == {"filename": "gone.mp4", "deleted": True}
    assert not os.path.exists(f"replays/{name}")


def test_deleting_takes_the_pin_with_it(client):
    """A pin entry for a vanished file is noise — the delete sweeps it."""
    token = _login(client)
    name = _make_clip("pinned_then_gone.mp4")
    pins.pin(name)

    resp = client.delete(
        f"/api/replays/{name}", headers={"x-api-token": token}
    )
    assert resp.status_code == 200
    assert not pins.is_pinned(name)
    assert name not in pins.load_pins()


def test_delete_needs_a_session(client):
    assert client.delete("/api/replays/a.mp4").status_code == 401


def test_a_monitor_token_cannot_delete_footage(client):
    """A monitor phone is a camera, not a cleaner."""
    token = _monitor_token(client)
    name = _make_clip("kept.mp4")

    resp = client.delete(
        f"/api/replays/{name}", headers={"x-api-token": token}
    )
    assert resp.status_code == 403
    assert os.path.exists(f"replays/{name}")


def test_deleting_a_missing_clip_is_404(client):
    token = _login(client)
    resp = client.delete(
        "/api/replays/nope.mp4", headers={"x-api-token": token}
    )
    assert resp.status_code == 404


def test_delete_stays_inside_the_folder(client):
    os.makedirs("replays", exist_ok=True)
    # A file that sits beside the folder, not in it — the climb target.
    with open("outside.mp4", "wb") as f:
        f.write(b"not yours")

    token = _login(client)
    resp = client.delete(
        "/api/replays/../outside.mp4", headers={"x-api-token": token}
    )
    # basename() flattens the climb to "outside.mp4", which is not in
    # replays/ — 404, and the file beside the folder is untouched.
    assert resp.status_code == 404
    assert os.path.exists("outside.mp4")


def test_the_list_lets_go_of_a_deleted_clip(client):
    token = _login(client)
    name = _make_clip("listed_then_gone.mp4")

    listing = client.get("/api/replays", headers={"x-api-token": token}).json()[
        "replays"
    ]
    assert any(r["filename"] == name for r in listing)

    client.delete(f"/api/replays/{name}", headers={"x-api-token": token})
    listing = client.get("/api/replays", headers={"x-api-token": token}).json()[
        "replays"
    ]
    assert all(r["filename"] != name for r in listing)
