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


def lock_sync_requests(db: Session, requests: Iterable[SyncPushRequest]) -> None:
    """Acquire all locks in one order, including across multi-item batches."""
    if not isinstance(db, Session) or db.get_bind().dialect.name != "postgresql":
        return
    keys: set[int] = set()
    for request in requests:
        keys.add(_lock_id(f"sync-key:{request.idempotency_key}"))
        keys.add(_lock_id(
            f"sync-entity:{request.company_id}:{request.entity_type}:{request.entity_id}"
        ))
    for key in sorted(keys):
        db.execute(select(func.pg_advisory_xact_lock(key)))
