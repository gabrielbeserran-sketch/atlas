from types import SimpleNamespace

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.authz import get_principal
from app.database import Base, get_db
from app.models import AuditLog, EntityState, ProcessedOperation, SyncChange
from app.offline_models import OfflineDevice, SyncConflict
from app.routers import offline_sync, sync


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
