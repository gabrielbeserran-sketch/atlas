from types import SimpleNamespace

import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session

from app.database import Base
from app.models import AuditLog, EntityState, ProcessedOperation, SyncChange
from app.offline_models import SyncConflict
from app.routers import offline_sync, sync
from app.schemas import SyncPushRequest
from app.services.sync_dairy_contract import validate_dairy_push


def principal(farms=None):
    return SimpleNamespace(
        company=SimpleNamespace(id="company-A", tenant_id="tenant-A"),
        membership=SimpleNamespace(farm_ids=farms or [], role="operator"),
        user=SimpleNamespace(id="user-A"),
    )


def daily(**changes):
    values = dict(
        operation_id="op-1", idempotency_key="key-1", tenant_id="tenant-A",
        company_id="company-A", farm_id="farm-A",
        entity_type="dairy_daily_production", entity_id="farm-A:2026-09-30",
        operation_type="create", base_version=0,
        payload={
            "date": "2026-09-30T00:00:00.000", "morning_liters": 120.5,
            "afternoon_liters": 118, "cows_milked": 40, "notes": "ok",
        },
    )
    values.update(changes)
    return SyncPushRequest(**values)


def herd(**changes):
    values = dict(
        entity_type="dairy_herd_snapshot",
        payload={
            "date": "2026-09-30", "eligible_cows": 50,
            "lactating_cows": 40, "dry_cows": 10,
            "pregnancies_monitored": 8, "pregnancy_losses": 1,
        },
    )
    values.update(changes)
    return daily(**values)


@pytest.fixture
def db():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(
        engine,
        tables=[
            AuditLog.__table__, EntityState.__table__, ProcessedOperation.__table__,
            SyncChange.__table__, SyncConflict.__table__,
        ],
    )
    with Session(engine) as session:
        yield session
    engine.dispose()


@pytest.mark.parametrize("operation", [
    daily(farm_id=None),
    daily(entity_id="farm-B:2026-09-30"),
    daily(entity_id="farm-A:2026-02-30"),
    daily(operation_type="replace"),
    daily(payload={"date": "2026-09-29", "morning_liters": 1, "afternoon_liters": 2, "cows_milked": 1}),
    daily(payload={"date": "2026-09-30", "morning_liters": float("inf"), "afternoon_liters": 2, "cows_milked": 1}),
    daily(payload={"date": "2026-09-30", "morning_liters": 1e308, "afternoon_liters": 1e308, "cows_milked": 1}),
    daily(payload={"date": "2026-09-30", "morning_liters": 1, "afternoon_liters": 2, "cows_milked": True}),
    daily(operation_type="delete", payload={"date": "2026-09-30"}),
    herd(payload={"date": "2026-09-30", "eligible_cows": 2, "lactating_cows": 2, "dry_cows": 1}),
    herd(payload={"date": "2026-09-30", "eligible_cows": 2, "lactating_cows": 1, "dry_cows": 1, "pregnancies_monitored": 0, "pregnancy_losses": 1}),
    herd(payload={"date": "2026-09-30", "eligible_cows": 2.5, "lactating_cows": 1, "dry_cows": 1}),
])
def test_invalid_dairy_requests_are_rejected_before_database_write(operation, db):
    assert validate_dairy_push(operation)
    single = sync.push(operation, principal=principal(), db=db)
    batch = offline_sync.push_batch(
        offline_sync.BatchPushRequest(operations=[operation]),
        principal=principal(), db=db,
    )
    assert single.accepted is False and single.conflict is False
    assert single.remote_payload == {}
    assert batch["rejected"] == 1 and batch["results"][0]["retryable"] is False
    assert db.scalars(select(EntityState)).all() == []
    assert db.scalars(select(SyncChange)).all() == []


@pytest.mark.parametrize("factory", [daily, herd])
def test_valid_dairy_create_replay_conflict_and_delete(factory, db):
    first = factory()
    created = sync.push(first, principal=principal(["farm-A"]), db=db)
    replay = sync.push(first, principal=principal(["farm-A"]), db=db)
    stale = factory(operation_id="op-stale", idempotency_key="key-stale")
    conflict = offline_sync.push_batch(
        offline_sync.BatchPushRequest(operations=[stale]),
        principal=principal(["farm-A"]), db=db,
    )
    removed = factory(
        operation_id="op-delete", idempotency_key="key-delete",
        operation_type="delete", payload={}, base_version=1,
    )
    deletion = offline_sync.push_batch(
        offline_sync.BatchPushRequest(operations=[removed]),
        principal=principal(["farm-A"]), db=db,
    )
    state = db.scalar(select(EntityState))
    assert created.accepted and created.remote_version == 1
    assert replay.accepted and replay.remote_version == 1
    assert conflict["conflicts"] == 1
    assert deletion["accepted"] == 1
    assert state.deleted and state.version == 2
    assert len(db.scalars(select(SyncChange)).all()) == 2


def test_other_entities_are_unchanged_and_cross_farm_is_denied(db):
    legacy = daily(entity_type="farm_note", entity_id="arbitrary", payload={"x": 1})
    assert sync.push(legacy, principal=principal(), db=db).accepted
    with pytest.raises(HTTPException) as error:
        sync.push(daily(), principal=principal(["farm-B"]), db=db)
    assert error.value.status_code == 403
    denied = offline_sync.push_batch(
        offline_sync.BatchPushRequest(operations=[daily()]),
        principal=principal(["farm-B"]), db=db,
    )
    assert denied["rejected"] == 1


def test_conflict_resolution_cannot_merge_invalid_dairy_payload(db):
    conflict = SyncConflict(
        tenant_id="tenant-A", company_id="company-A", farm_id="farm-A",
        user_id="user-A", device_id="device-A", operation_id="op-conflict",
        entity_type="dairy_daily_production", entity_id="farm-A:2026-09-30",
        local_version=0, remote_version=0, local_payload={}, remote_payload={},
    )
    db.add(conflict)
    db.commit()
    with pytest.raises(HTTPException) as error:
        offline_sync.resolve_conflict(
            conflict.id,
            offline_sync.ConflictResolutionRequest(
                resolution="merge", merged_payload={"date": "2026-09-30"},
            ),
            principal=principal(["farm-A"]), db=db,
        )
    assert error.value.status_code == 422
    assert db.scalars(select(EntityState)).all() == []
