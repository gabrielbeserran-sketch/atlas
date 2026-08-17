from __future__ import annotations

import hashlib

from sqlalchemy import text
from sqlalchemy.orm import Session


def advisory_transaction_lock(db: Session, key: str) -> None:
    """Serializa operações concorrentes relacionadas dentro da transação.

    PostgreSQL usa pg_advisory_xact_lock, liberado automaticamente no commit
    ou rollback. SQLite/testes não precisam dessa primitiva.
    """
    if db.bind is None or db.bind.dialect.name != "postgresql":
        return

    digest = hashlib.sha256(key.encode("utf-8")).digest()
    signed_64 = int.from_bytes(digest[:8], "big", signed=True)

    db.execute(
        text("SELECT pg_advisory_xact_lock(:key)"),
        {"key": signed_64},
    )
