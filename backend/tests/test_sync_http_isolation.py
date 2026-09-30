from types import SimpleNamespace
from datetime import datetime, timedelta, timezone

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.authz import get_principal
from app.database import Base, get_db
from app.models import (
    AuditLog, Company, EntityState, Membership, ProcessedOperation,
    RefreshSession, SyncChange, User,
)
from app.offline_models import OfflineDevice, SyncConflict
from app.routers import offline_sync, sync
from app.security import create_access_token


def principal(company_id="company-A", allowed=None):
    return SimpleNamespace(
        company=SimpleNamespace(id=company_id, tenant_id=f"tenant-{company_id}"),
        membership=SimpleNamespace(farm_ids=allowed or [], role="operator"),
        user=SimpleNamespace(id=f"user-{company_id}"),
        permissions={"sync.read", "sync.manage"},
    )


@pytest.fixture
def api():
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(
        engine,
        tables=[
            AuditLog.__table__, EntityState.__table__, ProcessedOperation.__table__,
            SyncChange.__table__, OfflineDevice.__table__, SyncConflict.__table__,
        ],
    )
    current = {"principal": principal(allowed=["farm-A"])}
    app = FastAPI()
    app.include_router(sync.router, prefix="/api/v1")
    app.include_router(offline_sync.router, prefix="/api/v1")

    def override_db():
        with Session(engine) as db:
            yield db

    app.dependency_overrides[get_db] = override_db
    app.dependency_overrides[get_principal] = lambda: current["principal"]
    with TestClient(app) as client:
        yield client, current, engine
    engine.dispose()


@pytest.fixture
def authenticated_api():
    """JWT e vínculos reais; somente o armazenamento é descartável."""
    engine = create_engine(
        "sqlite://", connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(
        engine,
        tables=[
            Company.__table__, User.__table__, Membership.__table__,
            RefreshSession.__table__, AuditLog.__table__, EntityState.__table__,
            ProcessedOperation.__table__, SyncChange.__table__,
            OfflineDevice.__table__, SyncConflict.__table__,
        ],
    )
    with Session(engine) as db:
        db.add_all([
            Company(id="company-A", tenant_id="tenant-company-A", name="A"),
            Company(id="company-B", tenant_id="tenant-company-B", name="B"),
        ])
        db.add_all([
            User(id=f"user-{name}", name=name, email=f"{name}@test.invalid",
                 password_hash="unused")
            for name in ("a", "viewer", "b")
        ])
        db.add_all([
            Membership(id=f"membership-{name}", user_id=f"user-{name}",
                       company_id=company, role=role, farm_ids=farms)
            for name, company, role, farms in (
                ("a", "company-A", "operator", ["farm-A"]),
                ("viewer", "company-A", "viewer", ["farm-A"]),
                ("b", "company-B", "operator", ["farm-B"]),
            )
        ])
        db.add_all([
            RefreshSession(
                id=f"session-{name}", user_id=f"user-{name}",
                company_id=company, token_hash=f"unused-{name}",
                expires_at=datetime.now(timezone.utc) + timedelta(days=1),
            )
            for name, company in (("a", "company-A"),
                                  ("viewer", "company-A"),
                                  ("b", "company-B"))
        ])
        db.commit()

    app = FastAPI()
    app.include_router(sync.router, prefix="/api/v1")
    app.include_router(offline_sync.router, prefix="/api/v1")

    def override_db():
        with Session(engine) as db:
            yield db

    app.dependency_overrides[get_db] = override_db

    def headers(name, *, tenant=None, role=None, session=None):
        company = "company-B" if name == "b" else "company-A"
        token = create_access_token(
            user_id=f"user-{name}", company_id=company,
            tenant_id=tenant or f"tenant-{company}",
            role=role or ("viewer" if name == "viewer" else "operator"),
            extra={"session_id": session or f"session-{name}"},
        )
        return {"Authorization": f"Bearer {token}"}

    with TestClient(app) as client:
        yield client, engine, headers
    engine.dispose()


def operation(
    *, company_id="company-A", farm_id="farm-A", entity_id="note-A",
    operation_id="op-A", key="key-A", payload=None, base_version=0,
):
    return {
        "operation_id": operation_id,
        "idempotency_key": key,
        "tenant_id": f"tenant-{company_id}",
        "company_id": company_id,
        "farm_id": farm_id,
        "entity_type": "farm_note",
        "entity_id": entity_id,
        "operation_type": "update",
        "payload": payload if payload is not None else {"value": 1},
        "base_version": base_version,
        "device_id": "device-A",
    }


def test_two_companies_cannot_replay_or_pull_each_others_changes(api):
    client, current, _engine = api
    first = client.post("/api/v1/sync/push", json=operation())
    assert first.status_code == 200
    assert first.json()["accepted"] is True
    assert client.post("/api/v1/sync/push", json=operation()).json() == first.json()

    current["principal"] = principal("company-B", ["farm-B"])
    collision = client.post(
        "/api/v1/sync/push",
        json=operation(
            company_id="company-B", farm_id="farm-B", entity_id="note-B",
            operation_id="op-B", key="key-A", payload={"private": "B"},
        ),
    )
    assert collision.status_code == 200
    assert collision.json()["accepted"] is False
    assert collision.json()["remote_payload"] == {}
    assert client.get("/api/v1/sync/pull").json() == []

    new_key = client.post(
        "/api/v1/sync/push",
        json=operation(
            company_id="company-B", farm_id="farm-B", entity_id="note-B",
            operation_id="op-B", key="key-B", payload={"private": "B"},
        ),
    )
    assert new_key.json()["accepted"] is True
    assert [change["entity_id"] for change in client.get("/api/v1/sync/pull").json()] == ["note-B"]

    current["principal"] = principal(allowed=["farm-A"])
    assert [change["entity_id"] for change in client.get("/api/v1/sync/pull").json()] == ["note-A"]
    assert [change["farm_id"] for change in client.get("/api/v1/sync/pull").json()] == ["farm-A"]
    assert [change["tenant_id"] for change in client.get("/api/v1/sync/pull").json()] == ["tenant-company-A"]


def test_batch_pull_and_conflicts_respect_farm_membership(api):
    client, current, _engine = api
    current["principal"] = principal()
    seeded = client.post(
        "/api/v1/offline/push-batch",
        json={"operations": [
            operation(),
            operation(farm_id="farm-B", entity_id="note-B", operation_id="op-B", key="key-B"),
        ]},
    )
    assert seeded.status_code == 200
    assert seeded.json()["accepted"] == 2
    assert all(item["retryable"] is True for item in seeded.json()["results"])

    stale = client.post(
        "/api/v1/offline/push-batch",
        json={"operations": [
            operation(operation_id="op-conflict-A", key="key-conflict-A", payload={"value": 2}),
            operation(
                farm_id="farm-B", entity_id="note-B", operation_id="op-conflict-B",
                key="key-conflict-B", payload={"value": 3},
            ),
        ]},
    )
    assert stale.status_code == 200
    assert stale.json()["conflicts"] == 2
    assert all(item["retryable"] is True for item in stale.json()["results"])
    conflict_b_id = next(
        item["id"] for item in client.get("/api/v1/offline/conflicts").json()
        if item["operation_id"] == "op-conflict-B"
    )

    current["principal"] = principal(allowed=["farm-A"])
    page = client.get("/api/v1/offline/pull-page?limit=1").json()
    assert [item["entity_id"] for item in page["changes"]] == ["note-A"]
    assert [item["farm_id"] for item in page["changes"]] == ["farm-A"]
    assert page["has_more"] is False
    assert [item["entity_id"] for item in client.get("/api/v1/sync/pull").json()] == ["note-A"]
    conflicts = client.get("/api/v1/offline/conflicts").json()
    assert [item["operation_id"] for item in conflicts] == ["op-conflict-A"]
    assert client.get("/api/v1/offline/status").json()["open_conflicts"] == 1

    denied = client.post(
        f"/api/v1/offline/conflicts/{conflict_b_id}/resolve",
        json={"resolution": "keep_local"},
    )
    assert denied.status_code == 404


def test_rejected_batch_operation_is_marked_non_retryable_without_losing_it(api):
    client, _current, engine = api
    batch = client.post(
        "/api/v1/offline/push-batch",
        json={"operations": [
            operation(),
            operation(
                farm_id="farm-B", entity_id="note-B",
                operation_id="op-B", key="key-B",
            ),
        ]},
    )

    assert batch.status_code == 200
    assert batch.json()["accepted"] == 1
    assert batch.json()["rejected"] == 1
    assert batch.json()["results"][0]["retryable"] is True
    assert batch.json()["results"][1]["retryable"] is False
    assert batch.json()["results"][1]["remote_payload"] == {}
    with Session(engine) as db:
        assert [item.farm_id for item in db.query(EntityState).all()] == ["farm-A"]


def test_reused_batch_key_is_permanent_rejection_without_foreign_payload(api):
    client, _current, engine = api
    first = client.post(
        "/api/v1/offline/push-batch",
        json={"operations": [operation(payload={"private": "original"})]},
    )
    assert first.json()["accepted"] == 1

    reused = client.post(
        "/api/v1/offline/push-batch",
        json={"operations": [operation(
            entity_id="note-other", operation_id="op-other", key="key-A",
            payload={"private": "other"},
        )]},
    )

    assert reused.status_code == 200
    assert reused.json()["rejected"] == 1
    assert reused.json()["results"][0]["retryable"] is False
    assert reused.json()["results"][0]["remote_payload"] == {}
    with Session(engine) as db:
        assert [item.entity_id for item in db.query(EntityState).all()] == ["note-A"]


def test_real_jwt_requires_live_session_and_manage_permission(authenticated_api):
    client, engine, headers = authenticated_api
    assert client.get("/api/v1/sync/pull").status_code in (401, 403)
    assert client.get("/api/v1/sync/pull", headers=headers("a", session="missing")).status_code == 401
    assert client.get("/api/v1/sync/pull", headers=headers("a", tenant="wrong")).status_code == 403
    assert client.get("/api/v1/sync/pull", headers=headers("a", role="owner")).status_code == 401

    viewer = headers("viewer")
    assert client.get("/api/v1/sync/pull", headers=viewer).status_code == 200
    assert client.post("/api/v1/sync/push", json=operation(), headers=viewer).status_code == 403
    assert client.post(
        "/api/v1/offline/push-batch", json={"operations": [operation()]},
        headers=viewer,
    ).status_code == 403
    with Session(engine) as db:
        db.get(RefreshSession, "session-a").revoked_at = datetime.now(timezone.utc)
        db.commit()
    assert client.get("/api/v1/sync/pull", headers=headers("a")).status_code == 401
    with Session(engine) as db:
        assert db.query(EntityState).count() == 0


def test_real_jwt_scopes_push_pull_and_batch_to_company_and_farm(authenticated_api):
    client, engine, headers = authenticated_api
    account_a = headers("a")
    account_b = headers("b")
    assert client.post("/api/v1/sync/push", json=operation(), headers=account_a).json()["accepted"]
    assert client.post(
        "/api/v1/sync/push",
        json=operation(farm_id="farm-B", entity_id="other", operation_id="op-other", key="key-other"),
        headers=account_a,
    ).status_code == 403
    batch = client.post(
        "/api/v1/offline/push-batch",
        json={"operations": [
            operation(farm_id="farm-B", entity_id="bad", operation_id="op-bad", key="key-bad"),
            operation(entity_id="good", operation_id="op-good", key="key-good"),
        ]},
        headers=account_a,
    )
    assert batch.status_code == 200
    assert (batch.json()["accepted"], batch.json()["rejected"]) == (1, 1)
    assert batch.json()["results"][0]["retryable"] is False
    assert batch.json()["results"][0]["remote_payload"] == {}

    assert client.post(
        "/api/v1/sync/push",
        json=operation(company_id="company-B", farm_id="farm-B", entity_id="b",
                       operation_id="op-b", key="key-b", payload={"private": "B"}),
        headers=account_b,
    ).json()["accepted"]
    assert [item["entity_id"] for item in client.get(
        "/api/v1/sync/pull", headers=account_a,
    ).json()] == ["note-A", "good"]
    assert [item["entity_id"] for item in client.get(
        "/api/v1/offline/pull-page", headers=account_a,
    ).json()["changes"]] == ["note-A", "good"]
    assert [item["entity_id"] for item in client.get(
        "/api/v1/sync/pull", headers=account_b,
    ).json()] == ["b"]
    assert client.get(
        "/api/v1/offline/pull-page?farm_id=farm-B", headers=account_a,
    ).status_code == 403
    with Session(engine) as db:
        assert db.query(EntityState).count() == 3


def test_real_jwt_conflict_visibility_and_resolution(authenticated_api):
    client, engine, headers = authenticated_api
    account_a = headers("a")
    assert client.post(
        "/api/v1/sync/push", json=operation(), headers=account_a,
    ).json()["accepted"]
    conflict = client.post(
        "/api/v1/offline/push-batch",
        json={"operations": [operation(
            operation_id="op-conflict", key="key-conflict", payload={"value": 2},
        )]},
        headers=account_a,
    )
    assert conflict.json()["conflicts"] == 1
    conflict_id = client.get("/api/v1/offline/conflicts", headers=account_a).json()[0]["id"]
    assert client.get("/api/v1/offline/conflicts", headers=headers("b")).json() == []
    path = f"/api/v1/offline/conflicts/{conflict_id}/resolve"
    assert client.post(path, json={"resolution": "keep_local"}, headers=headers("b")).status_code == 404
    assert client.post(path, json={"resolution": "keep_local"}, headers=headers("viewer")).status_code == 403
    resolved = client.post(path, json={"resolution": "keep_local"}, headers=account_a)
    assert resolved.status_code == 200
    assert resolved.json()["version"] == 2
    with Session(engine) as db:
        assert db.query(EntityState).one().payload == {"value": 2}


def test_stale_conflict_refreshes_remote_snapshot_before_resolution(authenticated_api):
    client, engine, headers = authenticated_api
    account = headers("a")
    assert client.post(
        "/api/v1/sync/push", json=operation(), headers=account,
    ).json()["accepted"]
    conflict = client.post(
        "/api/v1/offline/push-batch", headers=account,
        json={"operations": [operation(
            operation_id="op-stale", key="key-stale", payload={"local": 2},
        )]},
    )
    assert conflict.json()["conflicts"] == 1
    conflict_id = client.get("/api/v1/offline/conflicts", headers=account).json()[0]["id"]
    assert client.post(
        "/api/v1/sync/push", headers=account,
        json=operation(
            operation_id="op-newer", key="key-newer", base_version=1,
            payload={"remote": 3},
        ),
    ).json()["accepted"]

    path = f"/api/v1/offline/conflicts/{conflict_id}/resolve"
    stale = client.post(path, json={"resolution": "keep_local"}, headers=account)
    assert stale.status_code == 409
    assert "revise" in stale.json()["detail"]
    pending = client.get("/api/v1/offline/conflicts", headers=account).json()[0]
    assert pending["status"] == "open"
    assert pending["remote_version"] == 2
    assert pending["remote_payload"] == {"remote": 3}
    with Session(engine) as db:
        assert db.query(EntityState).one().payload == {"remote": 3}
        assert db.query(SyncChange).count() == 2

    confirmed = client.post(path, json={"resolution": "keep_local"}, headers=account)
    assert confirmed.status_code == 200
    assert confirmed.json()["version"] == 3
    assert confirmed.json()["payload"] == {"local": 2}


def test_real_jwt_rechecks_membership_permissions_and_company_status(authenticated_api):
    client, engine, headers = authenticated_api
    account_a = headers("a")
    assert client.get("/api/v1/offline/status", headers=account_a).status_code == 200
    with Session(engine) as db:
        db.get(Membership, "membership-a").permission_overrides = {"sync.manage": "deny"}
        db.commit()
    assert client.post(
        "/api/v1/sync/push", json=operation(), headers=account_a,
    ).status_code == 403
    assert client.get("/api/v1/sync/pull", headers=account_a).status_code == 200
    with Session(engine) as db:
        db.get(Membership, "membership-a").active = False
        db.commit()
    assert client.get("/api/v1/sync/pull", headers=account_a).status_code == 401
    with Session(engine) as db:
        db.get(Membership, "membership-a").active = True
        db.get(Company, "company-A").status = "inactive"
        db.commit()
    assert client.get("/api/v1/sync/pull", headers=account_a).status_code == 401
    assert client.get("/api/v1/sync/pull", headers=headers("b")).status_code == 200
