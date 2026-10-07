"""Sound events (bark / meow / loud noise) reported by the monitor."""
import api_routes


def _auth():
    from api_routes import SECRET_TOKEN
    return {"x-api-token": SECRET_TOKEN}


def _reset_cooldown():
    api_routes._last_sound_event = 0.0


def _sound_events(client):
    events = client.get("/api/activity?limit=200", headers=_auth()).json()["events"]
    return [e for e in events if e["event_type"] == "sound_detected"]


def test_sound_event_is_logged(client):
    _reset_cooldown()
    before = len(_sound_events(client))
    r = client.post("/api/monitor/sound", json={"level": -12.5}, headers=_auth())
    assert r.status_code == 200
    assert r.json() == {"status": "ok", "logged": True}

    sounds = _sound_events(client)
    assert len(sounds) == before + 1
    # Newest first from the API — the event we just logged is on top.
    assert sounds[0]["details"] == "-12 dB"


def test_sound_bursts_collapse_into_one_event(client):
    _reset_cooldown()
    before = len(_sound_events(client))
    for _ in range(5):
        r = client.post("/api/monitor/sound", json={"level": -6}, headers=_auth())
        assert r.status_code == 200
    bodies = [
        client.post("/api/monitor/sound", json={"level": -6}, headers=_auth()).json()
        for _ in range(3)
    ]
    assert all(b["logged"] is False for b in bodies)

    assert len(_sound_events(client)) == before + 1


def test_sound_needs_token(client):
    _reset_cooldown()
    assert client.post("/api/monitor/sound", json={"level": -6}).status_code == 401
