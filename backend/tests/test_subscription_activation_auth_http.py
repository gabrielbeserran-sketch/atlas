"""Ativação de planos via HTTP/JWT em banco exclusivamente descartável."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.models import Company, Membership, RefreshSession, User
from app.routers import saas_growth
from app.saas_growth_models import AdminAuditAction, CompanySubscription, SaaSPlan
from app.security import create_access_token


@pytest.fixture
def subscription_api(monkeypatch):
    toggle = SimpleNamespace(atlas_consultancy_plan_gate_enabled=True)
    monkeypatch.setattr(saas_growth, "get_settings", lambda: toggle)
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool,
    )
    Base.metadata.create_all(engine, tables=[
        Company.__table__, User.__table__, Membership.__table__,
        RefreshSession.__table__, SaaSPlan.__table__, CompanySubscription.__table__,
        AdminAuditAction.__table__,
    ])
    with Session(engine) as db:
        db.add(Company(id="company-A", tenant_id="tenant-A", name="A"))
        db.add(SaaSPlan(
            id="plan-consultancy", code="consultancy", name="Consultoria",
            features_json=["consultoria"], limits_json={"data_entries": None},
        ))
        for role in ("owner", "manager", "superAdministrator"):
            db.add(User(id=f"user-{role}", name=role,
                        email=f"{role}@test.invalid", password_hash="unused"))
            db.add(Membership(id=f"membership-{role}", user_id=f"user-{role}",
                              company_id="company-A", role=role))
            db.add(RefreshSession(
                id=f"session-{role}", user_id=f"user-{role}", company_id="company-A",
                token_hash=f"unused-{role}",
                expires_at=datetime.now(timezone.utc) + timedelta(days=1),
            ))
        db.commit()
    app = FastAPI()
    app.include_router(saas_growth.router)

    def override_db():
        with Session(engine) as db:
            yield db

    app.dependency_overrides[get_db] = override_db

    def headers(role):
        token = create_access_token(
            user_id=f"user-{role}", company_id="company-A",
            tenant_id="tenant-A", role=role,
            extra={"session_id": f"session-{role}"},
        )
        return {"Authorization": f"Bearer {token}"}

    with TestClient(app) as client:
        yield client, engine, headers, toggle
    engine.dispose()


@pytest.mark.parametrize("role", ["owner", "manager"])
def test_company_roles_cannot_self_activate_plan_when_gate_on(subscription_api, role):
    client, engine, headers, _toggle = subscription_api
    response = client.post(
        "/saas-growth/subscriptions",
        json={"code": "consultancy", "status": "active"}, headers=headers(role),
    )
    assert response.status_code == 403
    assert response.json()["detail"] == "Alteração de planos exige administrador da plataforma."
    plan = client.post(
        "/saas-growth/plans",
        json={"code": "custom", "name": "Plano não autorizado"}, headers=headers(role),
    )
    assert plan.status_code == 403
    with Session(engine) as db:
        assert db.query(CompanySubscription).count() == 0
        assert db.query(AdminAuditAction).count() == 0
        assert db.query(SaaSPlan).count() == 1


def test_platform_admin_can_activate_and_action_is_audited(subscription_api):
    client, engine, headers, _toggle = subscription_api
    response = client.post(
        "/saas-growth/subscriptions",
        json={"code": "consultancy", "status": "active"},
        headers=headers("superAdministrator"),
    )
    assert response.status_code == 200, response.text
    assert response.json()["plan_code"] == "consultancy"
    assert response.json()["status"] == "active"
    with Session(engine) as db:
        subscription = db.query(CompanySubscription).one()
        assert subscription.company_id == "company-A"
        assert db.query(AdminAuditAction).one().actor_id == "user-superAdministrator"


def test_gate_off_preserves_previous_company_subscription_flow(subscription_api):
    client, engine, headers, toggle = subscription_api
    toggle.atlas_consultancy_plan_gate_enabled = False
    response = client.post(
        "/saas-growth/subscriptions",
        json={"code": "consultancy", "status": "active"}, headers=headers("owner"),
    )
    assert response.status_code == 200, response.text
    with Session(engine) as db:
        assert db.query(CompanySubscription).count() == 1


def test_existing_subscription_cannot_be_upgraded_by_company_owner(subscription_api):
    client, engine, headers, _toggle = subscription_api
    with Session(engine) as db:
        db.add(SaaSPlan(id="plan-basic", code="basic", name="Essencial"))
        db.add(CompanySubscription(
            id="subscription-A", tenant_id="tenant-A", company_id="company-A",
            plan_id="plan-basic", status="active",
        ))
        db.commit()
    response = client.post(
        "/saas-growth/subscriptions",
        json={"code": "consultancy", "status": "active"}, headers=headers("owner"),
    )
    assert response.status_code == 403
    with Session(engine) as db:
        subscription = db.get(CompanySubscription, "subscription-A")
        assert subscription.plan_id == "plan-basic"
        assert subscription.status == "active"
        assert db.query(AdminAuditAction).count() == 0


def test_invalid_or_revoked_session_never_changes_subscription(subscription_api):
    client, engine, headers, _toggle = subscription_api
    assert client.post(
        "/saas-growth/subscriptions",
        json={"code": "consultancy", "status": "active"},
    ).status_code in (401, 403)
    with Session(engine) as db:
        db.get(RefreshSession, "session-superAdministrator").revoked_at = datetime.now(timezone.utc)
        db.commit()
    assert client.post(
        "/saas-growth/subscriptions",
        json={"code": "consultancy", "status": "active"},
        headers=headers("superAdministrator"),
    ).status_code == 401
    with Session(engine) as db:
        assert db.query(CompanySubscription).count() == 0
