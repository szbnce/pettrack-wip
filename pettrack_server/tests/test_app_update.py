"""One-tap app updates: the staged-APK endpoints behind Settings → About."""
import os

import pytest

import api_routes


def _login(client):
    return client.post(
        "/api/auth/login", json={"secret": api_routes.SECRET_TOKEN}
    ).json()["token"]


@pytest.fixture
def stage(tmp_path, monkeypatch):
    """Points the updater at an empty staging dir a test can fill."""

    def _stage(version="2.1.0", apk=b"fake-apk-bytes", meta=None):
        monkeypatch.setenv("PETTRACK_UPDATE_DIR", str(tmp_path))
        if apk is not None:
            (tmp_path / api_routes.UPDATE_APK_NAME).write_bytes(apk)
        if meta is not False:
            (tmp_path / "update.json").write_text(
                meta if meta is not None else f'{{"version": "{version}"}}'
            )
        return tmp_path

    return _stage


# --- probe -------------------------------------------------------------------


def test_probe_says_nothing_when_nothing_is_staged(client, stage):
    stage(apk=None, meta=False)
    resp = client.get("/api/app/update")
    assert resp.status_code == 200
    assert resp.json() == {"version": None}


def test_probe_reports_the_staged_version_and_size(client, stage):
    stage(version="2.1.0", apk=b"0123456789")
    resp = client.get("/api/app/update")
    assert resp.status_code == 200
    assert resp.json() == {"version": "2.1.0", "apk_bytes": 10}


def test_an_apk_without_metadata_is_not_an_update(client, stage):
    stage(apk=b"bytes", meta=False)
    assert client.get("/api/app/update").json() == {"version": None}


def test_metadata_without_an_apk_is_not_an_update(client, stage):
    stage(apk=None, meta='{"version": "2.1.0"}')
    assert client.get("/api/app/update").json() == {"version": None}


def test_unparseable_or_empty_metadata_is_not_an_update(client, stage):
    stage(apk=b"bytes", meta="not json at all")
    assert client.get("/api/app/update").json() == {"version": None}
    stage(apk=b"bytes", meta='{"version": ""}')
    assert client.get("/api/app/update").json() == {"version": None}


def test_staging_is_read_at_call_time(client, stage):
    """No restart needed: drop the files in and the probe sees them."""
    stage(apk=None, meta=False)
    assert client.get("/api/app/update").json() == {"version": None}
    stage(version="2.2.0", apk=b"apk")
    assert client.get("/api/app/update").json()["version"] == "2.2.0"


# --- download ----------------------------------------------------------------


def test_the_apk_download_needs_credentials(client, stage):
    stage(version="2.1.0", apk=b"apk")
    resp = client.get("/api/app/update/apk")
    assert resp.status_code == 401


def test_the_apk_download_delivers_the_staged_bytes(client, stage):
    stage(version="2.1.0", apk=b"the-whole-apk")
    resp = client.get(
        "/api/app/update/apk", headers={"x-api-token": _login(client)}
    )
    assert resp.status_code == 200
    assert resp.content == b"the-whole-apk"
    assert resp.headers["content-type"] == "application/vnd.android.package-archive"


def test_the_apk_download_is_404_when_nothing_is_staged(client, stage):
    stage(apk=None, meta=False)
    resp = client.get(
        "/api/app/update/apk", headers={"x-api-token": _login(client)}
    )
    assert resp.status_code == 404
