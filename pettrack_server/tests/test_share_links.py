"""Share links: a week-long, file-scoped URL for someone with no session."""
import os
import time

import jwt

import api_routes
import auth


def _login(client):
    return client.post(
        "/api/auth/login", json={"secret": api_routes.SECRET_TOKEN}
    ).json()["token"]


def test_mint_media_token_honours_a_custom_ttl():
    token = auth.mint_media_token(
        "replay_1.mp4", ttl_seconds=auth.SHARE_LINK_TTL_SECONDS
    )
    payload = jwt.decode(token, api_routes.SECRET_TOKEN, algorithms=["HS256"])
    assert payload["file"] == "replay_1.mp4"
    assert payload["exp"] - time.time() > 6 * 86400  # about a week


def test_share_needs_a_session_to_mint(client):
    assert client.post("/api/replays/replay_1.mp4/share").status_code == 401


def test_share_of_a_missing_clip_is_404(client):
    token = _login(client)
    resp = client.post(
        "/api/replays/nope.mp4/share", headers={"x-api-token": token}
    )
    assert resp.status_code == 404


def test_a_share_link_opens_the_clip_without_a_session(client):
    token = _login(client)
    os.makedirs("replays", exist_ok=True)
    with open("replays/replay_share.mp4", "wb") as f:
        f.write(b"fake-mp4-bytes")

    resp = client.post(
        "/api/replays/replay_share.mp4/share", headers={"x-api-token": token}
    )

    assert resp.status_code == 200
    body = resp.json()
    assert body["expires_in"] == auth.SHARE_LINK_TTL_SECONDS
    assert "token=" in body["url"]

    # The recipient has nothing but the link — that must be enough.
    got = client.get(body["url"])
    assert got.status_code == 200
    assert got.content == b"fake-mp4-bytes"


def test_a_share_link_stays_locked_to_its_file(client):
    token = _login(client)
    os.makedirs("replays", exist_ok=True)
    for name in ("replay_a.mp4", "replay_b.mp4"):
        with open(f"replays/{name}", "wb") as f:
            f.write(b"x")

    body = client.post(
        "/api/replays/replay_a.mp4/share", headers={"x-api-token": token}
    ).json()
    other_file = body["url"].replace("replay_a.mp4", "replay_b.mp4")

    assert client.get(other_file).status_code == 403
