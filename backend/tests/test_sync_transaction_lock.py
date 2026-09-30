"""Deterministic lock ordering for single pushes and multi-item batches."""

from types import SimpleNamespace
from unittest.mock import patch

from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from app.schemas import SyncPushRequest
from app.services.sync_transaction_lock import _lock_id, lock_sync_requests


def request(entity: str, key: str) -> SyncPushRequest:
    return SyncPushRequest(
        operation_id=key, idempotency_key=key, tenant_id="tenant-a",
        company_id="company-a", farm_id="farm-a", entity_type="farm_note",
        entity_id=entity, operation_type="update", payload={"value": 1},
        base_version=0,
    )


def test_sqlite_does_not_emit_postgres_advisory_sql():
    engine = create_engine("sqlite://")
    try:
        with Session(engine) as db, patch.object(db, "execute") as execute:
            lock_sync_requests(db, [request("note-a", "key-a")])
            execute.assert_not_called()
    finally:
        engine.dispose()


def test_batch_locks_key_and_entity_in_one_stable_order():
    engine = create_engine("sqlite://")
    try:
        with Session(engine) as db:
            requests = [request("note-b", "key-b"), request("note-a", "key-a")]
            with (
                patch.object(
                    db, "get_bind",
                    return_value=SimpleNamespace(
                        dialect=SimpleNamespace(name="postgresql")
                    ),
                ),
                patch.object(db, "execute") as execute,
            ):
                lock_sync_requests(db, requests)
            actual = [next(iter(call.args[0].compile().params.values()))
                      for call in execute.call_args_list]
            expected = sorted({
                _lock_id("sync-key:key-a"), _lock_id("sync-key:key-b"),
                _lock_id("sync-entity:company-a:farm_note:note-a"),
                _lock_id("sync-entity:company-a:farm_note:note-b"),
            })
            assert actual == expected
            assert all(-(2**63) <= key < 2**63 for key in actual)
    finally:
        engine.dispose()
