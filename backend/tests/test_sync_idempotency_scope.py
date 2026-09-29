from types import SimpleNamespace

import pytest

from app.routers import offline_sync, sync
from app.schemas import SyncPushRequest, SyncPushResponse
from app.services.sync_idempotency import stored_result


STORED_RESULT = {
    "accepted": True,
    "conflict": False,
    "remote_version": 7,
    "remote_payload": {"private_company_note": "secret"},
    "error": "",
}


class ReplayOnlyDb:
    def __init__(self, processed, state=None):
        self.processed = processed
        self.state = state
        self.reads = 0

    def get(self, _model, _key):
        self.reads += 1
        return self.processed

    def scalar(self, _query):
        return self.state

    def add(self, _record):
        raise AssertionError("A replay must not persist records")

    def commit(self):
        raise AssertionError("A replay must not commit")


def offline_push(request, principal, db):
    return offline_sync._process_operation(db, principal, request)


def request(company_id="company-A", operation_id="op-A", farm_id=None, payload=None):
    return SyncPushRequest(
        operation_id=operation_id,
        idempotency_key="shared-key",
        tenant_id="tenant-A",
        company_id=company_id,
        farm_id=farm_id,
        entity_type="farm_note",
        entity_id="note-A",
        operation_type="create",
        payload=payload if payload is not None else {"value": 1},
        base_version=0,
    )


def principal(company_id="company-A"):
    return SimpleNamespace(
        company=SimpleNamespace(id=company_id, tenant_id="tenant-A"),
        membership=SimpleNamespace(farm_ids=[]),
    )


@pytest.mark.parametrize("push", [sync.push, offline_push])
def test_reused_key_from_other_company_never_replays_private_response(push):
    db = ReplayOnlyDb(
        SimpleNamespace(
            company_id="company-B",
            operation_id="op-B",
            result_payload=STORED_RESULT,
        )
    )

    response = push(request(), principal(), db)

    assert response.accepted is False
    assert response.conflict is False
    assert response.remote_payload == {}
    assert response.remote_version == 0
    assert "secret" not in response.model_dump_json()
    assert db.reads == 1


@pytest.mark.parametrize("push", [sync.push, offline_push])
def test_reused_key_for_another_operation_is_rejected(push):
    db = ReplayOnlyDb(
        SimpleNamespace(
            company_id="company-A",
            operation_id="op-previous",
            result_payload=STORED_RESULT,
        )
    )

    response = push(request(), principal(), db)

    assert response.accepted is False
    assert response.remote_payload == {}
    assert db.reads == 1


@pytest.mark.parametrize("push", [sync.push, offline_push])
def test_exact_replay_preserves_original_result(push):
    db = ReplayOnlyDb(
        SimpleNamespace(
            company_id="company-A",
            operation_id="op-A",
            result_payload=stored_result(request(), SyncPushResponse(**STORED_RESULT)),
        )
    )

    response = push(request(), principal(), db)

    assert response.model_dump() == STORED_RESULT
    assert db.reads == 1


@pytest.mark.parametrize("push", [sync.push, offline_push])
def test_same_key_and_operation_cannot_replay_changed_farm_or_payload(push):
    original = request(farm_id="farm-A")
    db = ReplayOnlyDb(SimpleNamespace(
        company_id="company-A", operation_id="op-A",
        result_payload=stored_result(original, SyncPushResponse(**STORED_RESULT)),
    ))

    different_farm = push(request(farm_id="farm-B"), principal(), db)
    different_payload = push(request(farm_id="farm-A", payload={"value": 2}), principal(), db)

    assert different_farm.accepted is False
    assert different_farm.remote_payload == {}
    assert different_payload.accepted is False
    assert different_payload.remote_payload == {}


@pytest.mark.parametrize("push", [sync.push, offline_push])
def test_legacy_success_replays_only_with_matching_entity_state(push):
    old_result = {**STORED_RESULT, "remote_payload": {"value": 1}}
    db = ReplayOnlyDb(
        SimpleNamespace(
            company_id="company-A", operation_id="op-A",
            result_payload=old_result,
        ),
        state=SimpleNamespace(farm_id="farm-A"),
    )

    replay = push(request(farm_id="farm-A"), principal(), db)
    rejected = push(request(farm_id="farm-B"), principal(), db)

    assert replay.model_dump() == old_result
    assert rejected.accepted is False
    assert rejected.remote_payload == {}


@pytest.mark.parametrize("push", [sync.push, offline_push])
def test_legacy_conflict_cannot_replay_unverifiable_remote_payload(push):
    old_conflict = {
        **STORED_RESULT,
        "accepted": False,
        "conflict": True,
    }
    db = ReplayOnlyDb(
        SimpleNamespace(
            company_id="company-A", operation_id="op-A",
            result_payload=old_conflict,
        ),
        state=SimpleNamespace(farm_id=None),
    )

    response = push(request(), principal(), db)

    assert response.accepted is False
    assert response.conflict is False
    assert response.remote_payload == {}


@pytest.mark.parametrize("push", [sync.push, offline_push])
def test_claiming_other_company_is_rejected_before_replay_lookup(push):
    db = ReplayOnlyDb(None)

    response = push(request(company_id="company-B"), principal(), db)

    assert response.accepted is False
    assert response.remote_payload == {}
    assert db.reads == 0
