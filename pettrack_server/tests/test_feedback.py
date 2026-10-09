"""Teaching notes: long-press "not my pet" / "that's my pet" on a feed row."""
import time

import api_routes


def _login(client, scope: str = "full"):
    return client.post(
        "/api/auth/login",
        json={"secret": api_routes.SECRET_TOKEN, "scope": scope},
    ).json()["token"]


def test_feedback_needs_a_session(client):
    resp = client.post(
        "/api/feedback", json={"timestamp": 1.0, "kind": "not_my_pet"}
    )
    assert resp.status_code == 401


def test_a_monitor_token_cannot_teach(client):
    token = _login(client, scope="monitor")
    resp = client.post(
        "/api/feedback",
        json={"timestamp": 1.0, "kind": "not_my_pet"},
        headers={"x-api-token": token},
    )
    assert resp.status_code == 403


def test_an_unknown_kind_is_rejected(client):
    token = _login(client)
    resp = client.post(
        "/api/feedback",
        json={"timestamp": 1.0, "kind": "banana"},
        headers={"x-api-token": token},
    )
    assert resp.status_code == 400


def test_both_teaching_kinds_are_taken(client):
    token = _login(client)
    for kind in ("not_my_pet", "is_my_pet"):
        resp = client.post(
            "/api/feedback",
            json={"timestamp": time.time(), "kind": kind},
            headers={"x-api-token": token},
        )
        assert resp.status_code == 200


def test_a_note_keeps_its_moment_and_context(client):
    token = _login(client)
    ts = 1_700_000_123.5
    resp = client.post(
        "/api/feedback",
        json={
            "timestamp": ts,
            "kind": "not_my_pet",
            "event_type": "zone_enter",
            "zone_name": "Kitchen",
        },
        headers={"x-api-token": token},
    )
    assert resp.status_code == 200

    notes = client.get(
        "/api/feedback", headers={"x-api-token": token}
    ).json()["notes"]
    mine = [n for n in notes if n["timestamp"] == ts]
    assert mine, "the note should be readable back"
    assert mine[0]["kind"] == "not_my_pet"
    assert mine[0]["event_type"] == "zone_enter"
    assert mine[0]["zone_name"] == "Kitchen"
