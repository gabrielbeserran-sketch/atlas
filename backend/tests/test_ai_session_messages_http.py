"""Histórico de sessões Atlas AI em banco e JWT descartáveis."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.models import (
    AtlasAiSession, AtlasAiSessionMessage, Company, Membership,
    RefreshSession, User,
)
from app.routers import atlas_ai_enterprise
from app.security import create_access_token


@pytest.fixture
def ai_api(monkeypatch):
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool,
    )
    Base.metadata.create_all(engine, tables=[
        Company.__table__, User.__table__, Membership.__table__,
        RefreshSession.__table__, AtlasAiSession.__table__,
        AtlasAiSessionMessage.__table__,
    ])
    with Session(engine) as db:
        db.add(Company(id="company", tenant_id="tenant", name="Teste"))
        for name, farms in (("one", ["farm-A"]), ("two", ["farm-B"])):
            db.add(User(id=name, name=name, email=f"{name}@test.invalid",
                        password_hash="unused"))
            db.add(Membership(id=f"membership-{name}", user_id=name,
                              company_id="company", role="owner", farm_ids=farms))
            db.add(RefreshSession(
                id=f"session-{name}", user_id=name, company_id="company",
                token_hash=f"unused-{name}",
                expires_at=datetime.now(timezone.utc) + timedelta(days=1),
            ))
        db.commit()
    monkeypatch.setattr(atlas_ai_enterprise, "ensure_default_agents", lambda *_args, **_kwargs: None)
    monkeypatch.setattr(atlas_ai_enterprise, "orchestrator", SimpleNamespace(
        execute=lambda *_args, **_kwargs: SimpleNamespace(
            answer="Resumo de teste", agent_code="general",
            confidence_percent=80, evidence=[], limitations=[], recommendation=None,
        ),
    ))
    app = FastAPI()
    app.include_router(atlas_ai_enterprise.router)

    def override_db():
        with Session(engine) as db:
            yield db

    app.dependency_overrides[get_db] = override_db

    def headers(name):
        token = create_access_token(
            user_id=name, company_id="company", tenant_id="tenant", role="owner",
            extra={"session_id": f"session-{name}"},
        )
        return {"Authorization": f"Bearer {token}"}

    with TestClient(app) as client:
        yield client, engine, headers
    engine.dispose()


def test_chat_persists_session_messages_without_writing_legacy_conversation(ai_api):
    client, engine, headers = ai_api
    created = client.post(
        "/atlas-ai/chat", json={"farm_id": "farm-A", "message": "Como está a fazenda?"},
        headers=headers("one"),
    )
    assert created.status_code == 200, created.text
    session_id = created.json()["session_id"]
    listed = client.get(
        f"/atlas-ai/sessions/{session_id}/messages", headers=headers("one"),
    )
    assert listed.status_code == 200, listed.text
    assert [row["role"] for row in listed.json()] == ["user", "assistant"]
    assert listed.json()[1]["content"] == "Resumo de teste"
    with Session(engine) as db:
        assert db.query(AtlasAiSessionMessage).count() == 2
        assert db.get(AtlasAiSession, session_id).user_id == "one"


def test_another_user_cannot_read_or_reuse_session_id(ai_api):
    client, engine, headers = ai_api
    created = client.post(
        "/atlas-ai/chat", json={"farm_id": "farm-A", "message": "Privado"},
        headers=headers("one"),
    )
    session_id = created.json()["session_id"]
    assert client.get(
        f"/atlas-ai/sessions/{session_id}/messages", headers=headers("two"),
    ).status_code == 404
    assert client.post(
        "/atlas-ai/chat",
        json={"session_id": session_id, "farm_id": "farm-B", "message": "Intrusão"},
        headers=headers("two"),
    ).status_code == 404
    assert client.post(
        "/atlas-ai/chat",
        json={"session_id": session_id, "farm_id": "farm-B", "message": "Outra fazenda"},
        headers=headers("one"),
    ).status_code == 409
    with Session(engine) as db:
        assert db.query(AtlasAiSessionMessage).count() == 2
