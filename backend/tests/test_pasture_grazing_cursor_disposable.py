"""Paginação de pastejo isolada; nunca usa atlas_test.db."""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.authz import get_principal
from app.database import Base, get_db
from app.models import Company, Farm, Membership, PastureGrazingBasis, RefreshSession, User
from app.routers import livestock
from app.security import create_access_token


def test_cursor_resists_concurrent_insert_and_keeps_scope():
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool,
    )
    Base.metadata.create_all(
        engine, tables=[Company.__table__, Farm.__table__, User.__table__,
                        PastureGrazingBasis.__table__],
    )
    origin = datetime(2026, 1, 1, tzinfo=timezone.utc)

    def record(number, farm="farm-A", company="company-A"):
        return PastureGrazingBasis(
            id=f"server-{number}-{company}", tenant_id=f"tenant-{company}",
            company_id=company, farm_id=farm,
            client_operation_id=f"operation-{number}-{company}",
            effective_area_ha=20, grazing_animals=30,
            unique_area_confirmed=True, recorded_at=origin,
            created_at=origin + timedelta(seconds=number), created_by="user-A",
        )

    with Session(engine) as db:
        db.add_all([
            Company(id="company-A", tenant_id="tenant-company-A", name="A"),
            Company(id="company-B", tenant_id="tenant-company-B", name="B"),
            Farm(id="farm-A", tenant_id="tenant-company-A", company_id="company-A", name="A"),
            Farm(id="farm-B", tenant_id="tenant-company-B", company_id="company-B", name="B"),
            User(id="user-A", name="A", email="a@test.invalid", password_hash="unused"),
            *[record(i) for i in (1, 2, 3)],
            record(9, farm="farm-B", company="company-B"),
        ])
        db.commit()

    current = {"permissions": {"nutrition.read"}}
    app = FastAPI()
    app.include_router(livestock.router, prefix="/api/v1")

    def override_db():
        with Session(engine) as db:
            yield db

    def principal():
        return SimpleNamespace(
            company=SimpleNamespace(id="company-A", tenant_id="tenant-company-A"),
            membership=SimpleNamespace(farm_ids=["farm-A"]),
            permissions=current["permissions"],
        )

    app.dependency_overrides[get_db] = override_db
    app.dependency_overrides[get_principal] = principal
    base = "/api/v1/livestock/farms/farm-A/grazing-basis"
    with TestClient(app) as client:
        first = client.get(f"{base}/cursor", params={"limit": 2})
        assert first.status_code == 200, first.text
        assert [item["client_operation_id"] for item in first.json()] == [
            "operation-3-company-A", "operation-2-company-A",
        ]
        with Session(engine) as db:
            db.add(record(4))
            db.commit()
        after = first.json()[-1]
        second = client.get(f"{base}/cursor", params={
            "limit": 2, "after_created_at": after["created_at"],
            "after_id": after["id"],
        })
        assert second.status_code == 200, second.text
        assert [item["client_operation_id"] for item in second.json()] == [
            "operation-1-company-A",
        ]
        assert client.get(f"{base}/cursor", params={"limit": 2}).json()[0][
            "client_operation_id"
        ] == "operation-4-company-A"
        with Session(engine) as db:
            tied = record(5)
            tied.id = "server-2z-company-A"
            tied.created_at = origin + timedelta(seconds=2)
            db.add(tied)
            db.commit()
        page = client.get(f"{base}/cursor", params={
            "limit": 2, "after_created_at": after["created_at"],
            "after_id": "server-2z-company-A",
        })
        assert page.status_code == 200, page.text
        assert page.json()[0]["id"] == after["id"]
        assert client.get(base, params={"limit": 1}).status_code == 200
        assert client.get(f"{base}/cursor", params={"after_id": "server-1"}).status_code == 422
        assert client.get(f"{base}/cursor", params={
            "after_id": after["id"], "after_created_at": "2026-01-01T00:00:00",
        }).status_code == 422
        assert client.get(base.replace("farm-A", "farm-B") + "/cursor").status_code == 404
        current["permissions"] = set()
        assert client.get(f"{base}/cursor").status_code == 403
    engine.dispose()


def test_cursor_requires_live_jwt_membership_and_farm_scope():
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool,
    )
    Base.metadata.create_all(
        engine, tables=[Company.__table__, Farm.__table__, User.__table__,
                        Membership.__table__, RefreshSession.__table__,
                        PastureGrazingBasis.__table__],
    )
    with Session(engine) as db:
        db.add_all([
            Company(id="company-A", tenant_id="tenant-A", name="A"),
            Company(id="company-B", tenant_id="tenant-B", name="B"),
            Farm(id="farm-A", tenant_id="tenant-A", company_id="company-A", name="A"),
            Farm(id="farm-B", tenant_id="tenant-B", company_id="company-B", name="B"),
            User(id="user-A", name="A", email="a@test.invalid", password_hash="unused"),
            Membership(id="member-A", user_id="user-A", company_id="company-A",
                       role="operator", farm_ids=["farm-A"]),
            RefreshSession(id="session-A", user_id="user-A", company_id="company-A",
                           token_hash="unused", expires_at=datetime.now(timezone.utc)
                           + timedelta(days=1)),
        ])
        db.commit()
    app = FastAPI()
    app.include_router(livestock.router, prefix="/api/v1")

    def override_db():
        with Session(engine) as db:
            yield db

    app.dependency_overrides[get_db] = override_db
    token = create_access_token(
        user_id="user-A", company_id="company-A", tenant_id="tenant-A",
        role="operator", extra={"session_id": "session-A"},
    )
    headers = {"Authorization": f"Bearer {token}"}
    base = "/api/v1/livestock/farms"
    with TestClient(app) as client:
        assert client.get(f"{base}/farm-A/grazing-basis/cursor").status_code == 403
        assert client.get(f"{base}/farm-A/grazing-basis/cursor", headers=headers).status_code == 200
        assert client.get(f"{base}/farm-B/grazing-basis/cursor", headers=headers).status_code == 404
        with Session(engine) as db:
            member = db.get(Membership, "member-A")
            member.active = False
            db.commit()
        assert client.get(f"{base}/farm-A/grazing-basis/cursor", headers=headers).status_code in {401, 403}
    engine.dispose()
