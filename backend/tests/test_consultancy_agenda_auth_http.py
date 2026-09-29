"""Agenda com JWT/planos reais em SQLite descartável, sem o fixture de banco em disco."""

from datetime import datetime, timedelta, timezone

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.business_models import AtlasActionPlanItem
from app.database import Base, get_db
from app.models import Company, Membership, OperationalTask, RefreshSession, User
from app.routers import operations
from app.routers.business import _action_task
from app.saas_growth_models import CompanySubscription, SaaSPlan
from app.security import create_access_token


@pytest.fixture
def agenda_api(monkeypatch):
    monkeypatch.setattr(
        operations, "get_settings",
        lambda: type("Settings", (), {"atlas_consultancy_plan_gate_enabled": True})(),
    )
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool,
    )
    Base.metadata.create_all(engine, tables=[
        Company.__table__, User.__table__, Membership.__table__,
        RefreshSession.__table__, SaaSPlan.__table__, CompanySubscription.__table__,
        OperationalTask.__table__, AtlasActionPlanItem.__table__,
    ])
    with Session(engine) as db:
        for code in ("basic", "consultancy"):
            db.add(SaaSPlan(
                id=f"plan-{code}", code=code, name=code,
                features_json=["consultoria"] if code == "consultancy" else [],
                limits_json={},
            ))
        for name, plan in (("basic", "basic"), ("consultancy", "consultancy"),
                           ("legacy", None)):
            db.add(Company(id=f"company-{name}", tenant_id=f"tenant-{name}", name=name))
            if plan:
                db.add(CompanySubscription(
                    id=f"subscription-{name}", company_id=f"company-{name}",
                    tenant_id=f"tenant-{name}", plan_id=f"plan-{plan}", status="active",
                ))
        for name, company, role in (
            ("basic-owner", "basic", "owner"),
            ("basic-viewer", "basic", "viewer"),
            ("consultancy-owner", "consultancy", "owner"),
            ("legacy-owner", "legacy", "owner"),
        ):
            db.add(User(id=f"user-{name}", name=name, email=f"{name}@test.invalid",
                        password_hash="unused"))
            db.add(Membership(
                id=f"membership-{name}", user_id=f"user-{name}",
                company_id=f"company-{company}", role=role, farm_ids=["farm-A"],
            ))
            db.add(RefreshSession(
                id=f"session-{name}", user_id=f"user-{name}",
                company_id=f"company-{company}", token_hash=f"unused-{name}",
                expires_at=datetime.now(timezone.utc) + timedelta(days=1),
            ))
        db.add_all([
            OperationalTask(id="legacy-variant", tenant_id="tenant-basic",
                            company_id="company-basic", farm_id="farm-A",
                            source_type=" Consultancy_Action ", source_id="action-1",
                            title="Ação consultiva anterior"),
            OperationalTask(id="ordinary", tenant_id="tenant-basic",
                            company_id="company-basic", farm_id="farm-A",
                            source_type="manual", title="Conferir cerca"),
        ])
        db.commit()

    app = FastAPI()
    app.include_router(operations.router)

    def override_db():
        with Session(engine) as db:
            yield db

    app.dependency_overrides[get_db] = override_db

    def headers(name):
        company = name.split("-")[0]
        role = "viewer" if name.endswith("viewer") else "owner"
        token = create_access_token(
            user_id=f"user-{name}", company_id=f"company-{company}",
            tenant_id=f"tenant-{company}", role=role,
            extra={"session_id": f"session-{name}"},
        )
        return {"Authorization": f"Bearer {token}"}

    with TestClient(app) as client:
        yield client, engine, headers
    engine.dispose()


def test_basic_hides_legacy_variant_but_keeps_regular_task(agenda_api):
    client, engine, headers = agenda_api
    owner = headers("basic-owner")
    listed = client.get("/operations/tasks?farm_id=farm-A", headers=owner)
    assert listed.status_code == 200
    assert [task["id"] for task in listed.json()] == ["ordinary"]
    changed = client.patch(
        "/operations/tasks/legacy-variant",
        json={"status": "completed", "evidence": "Feito"}, headers=owner,
    )
    assert changed.status_code == 403
    relabeled = client.patch(
        "/operations/tasks/ordinary",
        json={"source_type": " CONSULTANCY_ACTION "}, headers=owner,
    )
    assert relabeled.status_code == 403
    assert client.patch(
        "/operations/tasks/ordinary", json={"status": "completed"}, headers=owner,
    ).status_code == 200
    with Session(engine) as db:
        assert db.get(OperationalTask, "legacy-variant").status == "open"
        assert db.get(OperationalTask, "ordinary").status == "completed"
        assert db.get(OperationalTask, "ordinary").source_type == "manual"


def test_consultancy_creation_is_canonical_and_downgrade_blocks_it(agenda_api):
    client, engine, headers = agenda_api
    owner = headers("consultancy-owner")
    created = client.post(
        "/operations/tasks",
        json={"farm_id": "farm-A", "title": "Revisar manejo",
              "source_type": " Consultancy_Action ", "source_id": "action-2"},
        headers=owner,
    )
    assert created.status_code == 201, created.text
    assert created.json()["source_type"] == "consultancy_action"
    task_id = created.json()["id"]
    assert [item["id"] for item in client.get(
        "/operations/tasks?farm_id=farm-A", headers=owner,
    ).json()] == [task_id]
    with Session(engine) as db:
        db.get(CompanySubscription, "subscription-consultancy").plan_id = "plan-basic"
        db.commit()
    assert client.get("/operations/tasks?farm_id=farm-A", headers=owner).json() == []
    assert client.patch(
        f"/operations/tasks/{task_id}", json={"title": "Mudança indevida"},
        headers=owner,
    ).status_code == 403
    with Session(engine) as db:
        assert db.get(OperationalTask, task_id).title == "Revisar manejo"


def test_viewer_and_legacy_policy_remain_separate(agenda_api):
    client, engine, headers = agenda_api
    viewer = headers("basic-viewer")
    assert client.get("/operations/tasks?farm_id=farm-A", headers=viewer).status_code == 200
    assert client.post(
        "/operations/tasks", json={"farm_id": "farm-A", "title": "Não pode criar"},
        headers=viewer,
    ).status_code == 403
    legacy = headers("legacy-owner")
    created = client.post(
        "/operations/tasks",
        json={"farm_id": "farm-A", "title": "Ação anterior",
              "source_type": " CONSULTANCY_ACTION "}, headers=legacy,
    )
    assert created.status_code == 201
    assert created.json()["source_type"] == "consultancy_action"
    assert len(client.get("/operations/tasks?farm_id=farm-A", headers=legacy).json()) == 1
    with Session(engine) as db:
        assert db.get(OperationalTask, "legacy-variant").source_type == " Consultancy_Action "


def test_action_lookup_recognizes_legacy_variant_without_migration(agenda_api):
    _client, engine, _headers = agenda_api
    with Session(engine) as db:
        principal = type("Principal", (), {"company": type("Company", (), {"id": "company-basic"})()})()
        assert _action_task(db, principal, "action-1").id == "legacy-variant"


def test_consultancy_source_backed_legacy_task_cannot_be_reclassified(agenda_api):
    client, engine, headers = agenda_api
    with Session(engine) as db:
        db.add(OperationalTask(
            id="consultancy-old", tenant_id="tenant-consultancy",
            company_id="company-consultancy", farm_id="farm-A",
            source_type=" CONSULTANCY_ACTION ", source_id="action-3",
            title="Ação vinculada",
        ))
        db.commit()
    changed = client.patch(
        "/operations/tasks/consultancy-old",
        json={"source_type": "manual", "title": "Título atualizado"},
        headers=headers("consultancy-owner"),
    )
    assert changed.status_code == 200, changed.text
    with Session(engine) as db:
        task = db.get(OperationalTask, "consultancy-old")
        assert task.source_type == " CONSULTANCY_ACTION "
        assert task.title == "Título atualizado"
