import asyncio
import os
import sys
from pathlib import Path

# Make the server package importable and pin the secrets so importing
# api_routes never generates a real .env in the repo.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
os.environ["PETTRACK_SECRET"] = "test-master-secret-0123456789abcdef0123456789"
os.environ["PETTRACK_WEB_PIN"] = "4242"

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

import api_routes
import auth
from api_routes import auth_router, router
from database import init_db


@pytest.fixture(scope="session")
def client(tmp_path_factory):
    """TestClient over the real routers, with an isolated temp DB."""
    os.chdir(tmp_path_factory.mktemp("pettrack_db"))
    asyncio.run(init_db())
    app = FastAPI()
    app.include_router(router)
    app.include_router(auth_router)
    with TestClient(app) as c:
        yield c


@pytest.fixture(autouse=True)
def _clear_lockout():
    # The lockout counters live in the DB (persistent across restarts), so
    # every test starts and ends with a clean slate.
    asyncio.run(auth.clear_all_failures())
    yield
    asyncio.run(auth.clear_all_failures())
