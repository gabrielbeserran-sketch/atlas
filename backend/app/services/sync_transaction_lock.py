"""Serialize writes to one sync entity and one global idempotency key.

PostgreSQL advisory locks last until the request transaction commits. SQLite
tests remain on their existing single-writer contract; PostgreSQL CI exercises
the concurrent multi-connection behavior.
"""

from __future__ import annotations

from hashlib import blake2b
from typing import Iterable

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..schemas import SyncPushRequest


def _lock_id(value: str) -> int:
    return int.from_bytes(
        blake2b(value.encode("utf-8"), digest_size=8).digest(),
        byteorder="big", signed=True,
    )


def _entity_lock_id(company_id: str, entity_type: str, entity_id: str) -> int:
    return _lock_id(f"sync-entity:{company_id}:{entity_type}:{entity_id}")


def _acquire(db: Session, keys: set[int]) -> None:
    if not isinstance(db, Session) or db.get_bind().dialect.name != "postgresql":
        return
    for key in sorted(keys):
        db.execute(select(func.pg_advisory_xact_lock(key)))


def lock_sync_requests(db: Session, requests: Iterable[SyncPushRequest]) -> None:
    """Acquire all locks in one order, including across multi-item batches."""
    keys: set[int] = set()
    for request in requests:
        keys.add(_lock_id(f"sync-key:{request.idempotency_key}"))
        keys.add(_entity_lock_id(
            request.company_id, request.entity_type, request.entity_id,
        ))
    _acquire(db, keys)


def lock_sync_entity(
    db: Session, company_id: str, entity_type: str, entity_id: str,
) -> None:
    """Use the same entity lock when a human resolves a sync conflict."""
    _acquire(db, {_entity_lock_id(company_id, entity_type, entity_id)})
