from types import SimpleNamespace

import pytest

from app.routers import offline_sync, sync
from app.schemas import SyncPushRequest


STORED_RESULT = {
    "accepted": True,
    "conflict": False,
    "remote_version": 7,
    "remote_payload": {"private_company_note": "secret"},
    "error": "",
}


class ReplayOnlyDb:
    def __init__(self, processed):
        self.processed = processed
        self.reads = 0

    def get(self, _model, _key):
        self.reads += 1
        return self.processed

    def scalar(self, _query):
        raise AssertionError("A replay must not inspect entity state")

    def add(self, _record):
        raise AssertionError("A replay must not persist records")

    def commit(self):
        raise AssertionError("A replay must not commit")


def offline_push(request, principal, db):
    return offline_sync._process_operation(db, principal, request)


def request(company_id="company-A", operation_id="op-A"):
    return SyncPushRequest(
        operation_id=operation_id,
        idempotency_key="shared-key",
        tenant_id="tenant-A",
        company_id=company_id,
        entity_type="farm_note",
        entity_id="note-A",
        operation_type="create",
        payload={"value": 1},
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
            result_payload=STORED_RESULT,
        )
    )

    response = push(request(), principal(), db)

    assert response.model_dump() == STORED_RESULT
    assert db.reads == 1


@pytest.mark.parametrize("push", [sync.push, offline_push])
def test_claiming_other_company_is_rejected_before_replay_lookup(push):
    db = ReplayOnlyDb(None)

    response = push(request(company_id="company-B"), principal(), db)

    assert response.accepted is False
    assert response.remote_payload == {}
    assert db.reads == 0
