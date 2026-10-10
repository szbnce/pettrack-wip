"""The settings file must never take the server down with it.

The bug this pins: a deployment left a *directory* named `.env`. Every
writer assumed it was a file, the "fallback" reopened the same directory,
and the boot crashed — on the secret, in a loop that minted a fresh master
secret every time, which is the same as throwing away every session and
encrypted record.
"""
import os

import pytest

import env_store
from env_store import load_persistent_env, safe_set_key, sidecar_path


@pytest.fixture()
def scratch(tmp_path, monkeypatch):
    """A directory of its own: these tests build a broken `.env` on purpose,
    and the shared test cwd must not see it."""
    monkeypatch.chdir(tmp_path)
    monkeypatch.delenv("PETTRACK_ENV_FILE", raising=False)
    for key in ("PETTRACK_SECRET", "PETTRACK_WEB_PIN", "PETTRACK_NTFY_URL"):
        monkeypatch.delenv(key, raising=False)
    return tmp_path


def test_a_healthy_env_file_takes_the_setting(scratch):
    (scratch / ".env").write_text("PETTRACK_NTFY_URL=old\n")

    assert safe_set_key("PETTRACK_NTFY_URL", "https://ntfy.example/pets") is True
    assert os.environ["PETTRACK_NTFY_URL"] == "https://ntfy.example/pets"
    body = (scratch / ".env").read_text()
    assert "https://ntfy.example/pets" in body
    assert "old" not in body


def test_a_directory_called_env_is_not_the_end_of_the_world(scratch):
    """The reported crash: `IsADirectoryError: '.env'` on every boot."""
    (scratch / ".env").mkdir()

    # The old code raised here, twice — once in set_key, once in its own
    # fallback that reopened the same directory.
    assert safe_set_key("PETTRACK_SECRET", "s3cret-value") is True

    # It landed in the sidecar instead, and the live process has it.
    assert os.environ["PETTRACK_SECRET"] == "s3cret-value"
    # Inside the mounted `.env` directory — the one place that survives
    # a rebuild — not beside the code in the container layer.
    assert sidecar_path() == os.path.join(".env", "pettrack.env")
    sidecar = (scratch / ".env" / "pettrack.env").read_text()
    assert "PETTRACK_SECRET" in sidecar
    assert "s3cret-value" in sidecar


def test_the_secret_survives_a_restart_when_env_is_a_directory(scratch):
    (scratch / ".env").mkdir()
    safe_set_key("PETTRACK_SECRET", "s3cret-value")

    # ...and a fresh boot finds it, instead of minting another one.
    os.environ.pop("PETTRACK_SECRET", None)
    load_persistent_env()
    assert os.environ["PETTRACK_SECRET"] == "s3cret-value"


def test_nowhere_to_write_still_keeps_the_running_server_working(scratch, capsys):
    """A read-only box must start. It just cannot promise a restart."""
    (scratch / ".env").mkdir()
    (scratch / ".env" / env_store.SIDECAR_NAME).mkdir()  # even the fallback is taken

    assert safe_set_key("PETTRACK_WEB_PIN", "4242") is False
    assert os.environ["PETTRACK_WEB_PIN"] == "4242"
    assert "lives for this run only" in capsys.readouterr().out


def test_the_operator_wins_over_what_we_wrote(scratch, monkeypatch):
    (scratch / ".env").mkdir()
    safe_set_key("PETTRACK_SECRET", "from-file")
    monkeypatch.setenv("PETTRACK_SECRET", "from-the-container")

    # A value the container set is deliberate — the sidecar must not
    # quietly overrule it.
    load_persistent_env()
    assert os.environ["PETTRACK_SECRET"] == "from-the-container"


def test_a_named_secret_file_is_the_first_place_we_look(scratch, monkeypatch):
    target = scratch / "keys" / "secret"
    target.parent.mkdir()
    target.write_text("from-the-named-file\n")
    monkeypatch.setenv("PETTRACK_SECRET_FILE", str(target))
    monkeypatch.setenv("PETTRACK_ENV_FILE", str(scratch / "custom.env"))

    assert safe_set_key("PETTRACK_SECRET", "s3cret-value") is True
    assert (scratch / "custom.env").exists()
    assert "s3cret-value" in (scratch / "custom.env").read_text()


def test_the_settings_save_survives_a_directory_called_env(scratch):
    """Settings → a save used to 500 the same way the boot used to die."""
    import settings as app_settings

    (scratch / ".env").mkdir()
    app_settings.set_replay_retention_days(7)

    assert app_settings.get_replay_retention_days() == 7
    assert os.environ["PETTRACK_REPLAY_RETENTION_DAYS"] == "7"
    sidecar = (scratch / ".env" / env_store.SIDECAR_NAME).read_text()
    assert "PETTRACK_REPLAY_RETENTION_DAYS" in sidecar
    assert "7" in sidecar
