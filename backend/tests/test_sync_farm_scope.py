from types import SimpleNamespace

import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from app.database import Base
from app.models import EntityState, SyncChange
from app.offline_models import OfflineDevice, SyncConflict
from app.routers import offline_sync, sync
from app.schemas import SyncPushRequest


def principal(*, allowed=None, company_id="company-A", role="operator"):
    return SimpleNamespace(
        company=SimpleNamespace(id=company_id, tenant_id="tenant-A"),
        membership=SimpleNamespace(farm_ids=allowed or [], role=role),
        user=SimpleNamespace(id="user-A"),
    )


def change(farm_id, number, *, company_id="company-A"):
    return SyncChange(
        company_id=company_id,
        tenant_id="tenant-A",
        farm_id=farm_id,
        entity_type="farm_note",
        entity_id=f"note-{number}",
        version=1,
        payload={"number": number},
        deleted=False,
    )


@pytest.fixture
def db():
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(
        engine,
        tables=[
            SyncChange.__table__, SyncConflict.__table__,
            EntityState.__table__, OfflineDevice.__table__,
        ],
    )
    with Session(engine) as session:
        yield session
    engine.dispose()


def test_both_pulls_restrict_farms_before_pagination(db):
    db.add_all(change("farm-B", index) for index in range(1001))
    db.add_all([change("farm-A", 1001), change(None, 1002)])
    db.commit()

    current = sync.pull(cursor=0, principal=principal(allowed=["farm-A"]), db=db)
    page = offline_sync.pull_page(
        cursor=0, limit=2, farm_id=None,
        principal=principal(allowed=["farm-A"]), db=db,
    )

    assert [item.payload["number"] for item in current] == [1001, 1002]
    assert [item["payload"]["number"] for item in page["changes"]] == [1001, 1002]
    assert page["has_more"] is False
    assert page["next_cursor"] == int(current[-1].cursor)


def test_explicit_farm_filter_and_unrestricted_membership(db):
    db.add_all([change("farm-A", 1), change("farm-B", 2), change(None, 3)])
    db.commit()

    scoped = offline_sync.pull_page(
        cursor=0, limit=10, farm_id="farm-A",
        principal=principal(allowed=["farm-A"]), db=db,
    )
    unrestricted = sync.pull(cursor=0, principal=principal(), db=db)

    assert [item["payload"]["number"] for item in scoped["changes"]] == [1]
    assert [item.payload["number"] for item in unrestricted] == [1, 2, 3]


def test_explicit_unassigned_farm_is_rejected(db):
    with pytest.raises(HTTPException) as error:
        offline_sync.pull_page(
            cursor=0, limit=10, farm_id="farm-B",
            principal=principal(allowed=["farm-A"]), db=db,
        )

    assert error.value.status_code == 403


class ExistingStateDb:
    def __init__(self, state):
        self.state = state

    def get(self, _model, _key):
        return None

    def scalar(self, _query):
        return self.state

    def add(self, _record):
        raise AssertionError("A different farm must not be changed")

    def commit(self):
        raise AssertionError("A different farm must not be committed")


def request(farm_id="farm-A"):
    return SyncPushRequest(
        operation_id="op-A", idempotency_key="key-A",
        tenant_id="tenant-A", company_id="company-A", farm_id=farm_id,
        entity_type="farm_note", entity_id="note-A", operation_type="update",
        payload={"changed": True}, base_version=1,
    )


def offline_push(request, principal, db):
    return offline_sync._process_operation(db, principal, request)


@pytest.mark.parametrize("push", [sync.push, offline_push])
def test_push_never_returns_or_overwrites_another_farms_entity(push):
    state = SimpleNamespace(
        farm_id="farm-B", version=2, payload={"private": "farm-B"},
    )
    db = ExistingStateDb(state)

    response = push(request(), principal(allowed=["farm-A"]), db)

    assert response.accepted is False
    assert response.conflict is False
    assert response.remote_payload == {}
    assert response.remote_version == 0
    assert state.farm_id == "farm-B"
    assert state.payload == {"private": "farm-B"}


def conflict(farm_id, operation_id):
    return SyncConflict(
        id=f"conflict-{operation_id}",
        tenant_id="tenant-A", company_id="company-A", farm_id=farm_id,
        user_id="user-A", device_id="device-A", operation_id=operation_id,
        entity_type="farm_note", entity_id=f"note-{operation_id}",
        local_version=1, remote_version=2,
        local_payload={"private": farm_id},
        remote_payload={"private": farm_id},
        status="open",
    )


def test_conflict_list_hides_other_farms_payloads(db):
    db.add_all([
        conflict("farm-A", "op-A"), conflict("farm-B", "op-B"),
        conflict(None, "op-company"),
    ])
    db.commit()

    listed = offline_sync.list_conflicts(
        status="open", principal=principal(allowed=["farm-A"]), db=db,
    )

    assert {item["operation_id"] for item in listed} == {"op-A", "op-company"}
    assert "farm-B" not in str(listed)


def test_conflict_resolution_cannot_access_other_farm(db):
    db.add(conflict("farm-B", "op-B"))
    db.commit()

    with pytest.raises(HTTPException) as error:
        offline_sync.resolve_conflict(
            "conflict-op-B",
            offline_sync.ConflictResolutionRequest(resolution="keep_local"),
            principal=principal(allowed=["farm-A"]), db=db,
        )

    assert error.value.status_code == 404
    assert db.get(SyncConflict, "conflict-op-B").status == "open"


def test_conflict_resolution_does_not_overwrite_entity_moved_to_another_farm(db):
    db.add(conflict("farm-A", "op-A"))
    db.add(EntityState(
        id="state-A", tenant_id="tenant-A", company_id="company-A",
        farm_id="farm-B", entity_type="farm_note", entity_id="note-op-A",
        version=2, payload={"private": "farm-B"}, deleted=False,
        updated_by="user-B",
    ))
    db.commit()

    with pytest.raises(HTTPException) as error:
        offline_sync.resolve_conflict(
            "conflict-op-A",
            offline_sync.ConflictResolutionRequest(resolution="keep_local"),
            principal=principal(allowed=["farm-A"]), db=db,
        )

    assert error.value.status_code == 409
    assert db.get(EntityState, "state-A").payload == {"private": "farm-B"}
    assert db.get(SyncConflict, "conflict-op-A").status == "open"


def test_offline_status_counts_only_visible_changes_and_conflicts(db):
    db.add_all([
        change("farm-A", 1), change("farm-B", 2),
        conflict("farm-A", "op-A"), conflict("farm-B", "op-B"),
    ])
    db.commit()

    status = offline_sync.offline_status(
        principal=principal(allowed=["farm-A"]), db=db,
    )

    assert status["open_conflicts"] == 1
    assert status["latest_cursor"] == 1
