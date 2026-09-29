"""Chat determinístico completo em SQLite migrado e descartável."""

import os
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import (
    AtlasAiAgent, AtlasAiRecommendation, AtlasAiSessionMessage,
    Company, Farm, Membership, RefreshSession, User,
)
from app.routers import atlas_ai_enterprise
from app.security import create_access_token


def test_chat_with_real_orchestrator_after_full_migration(tmp_path):
    backend = Path(__file__).resolve().parents[1]
    database = tmp_path / "ai-chat.sqlite3"
    url = f"sqlite:///{database.as_posix()}"
    environment = os.environ.copy()
    environment["ATLAS_DATABASE_URL"] = url
    migrated = subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "head"],
        cwd=backend, env=environment, capture_output=True, text=True,
        timeout=180, check=False,
    )
    assert migrated.returncode == 0, migrated.stderr[-3000:]

    engine = create_engine(url, connect_args={"check_same_thread": False})
    try:
        with Session(engine) as db:
            db.add(Company(id="company", tenant_id="tenant", name="Teste"))
            db.add(User(id="owner", name="Proprietário", email="owner@test.invalid",
                        password_hash="unused"))
            db.add(Membership(id="membership", user_id="owner", company_id="company",
                              role="owner", farm_ids=["farm-A"]))
            db.add(RefreshSession(
                id="session", user_id="owner", company_id="company",
                token_hash="unused", expires_at=datetime.now(timezone.utc) + timedelta(days=1),
            ))
            db.add(Farm(id="farm-A", tenant_id="tenant", company_id="company",
                        name="Fazenda descartável"))
            db.commit()

        app = FastAPI()
        app.include_router(atlas_ai_enterprise.router)

        def override_db():
            with Session(engine) as db:
                yield db

        app.dependency_overrides[get_db] = override_db
        token = create_access_token(
            user_id="owner", company_id="company", tenant_id="tenant",
            role="owner", extra={"session_id": "session"},
        )
        headers = {"Authorization": f"Bearer {token}"}
        with TestClient(app) as client:
            reply = client.post(
                "/atlas-ai/chat", headers=headers,
                json={"farm_id": "farm-A", "message": "Como está a fazenda?"},
            )
            assert reply.status_code == 200, reply.text
            body = reply.json()
            assert body["agent_code"] == "general"
            assert body["recommendations_created"]
            history = client.get(
                f"/atlas-ai/sessions/{body['session_id']}/messages",
                headers=headers,
            )
            assert history.status_code == 200, history.text
            assert [item["role"] for item in history.json()] == ["user", "assistant"]
        with Session(engine) as db:
            assert db.query(AtlasAiAgent).count() >= 1
            assert db.query(AtlasAiSessionMessage).count() == 2
            assert db.query(AtlasAiRecommendation).count() == 1
    finally:
        engine.dispose()
