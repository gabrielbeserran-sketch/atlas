"""Read-only contract check for the fresh, loopback-only GitHub Actions service.

This does not accept an external database target or run migrations itself.
"""

from __future__ import annotations

import os

from sqlalchemy import inspect, text
from sqlalchemy.engine import make_url
from sqlalchemy.exc import ArgumentError


EXPECTED_HEAD = "20260929_0059"
EXPECTED_INDEX = "ix_pasture_grazing_scope_created_id"
EXPECTED_COLUMNS = ["tenant_id", "company_id", "farm_id", "created_at", "id"]


def validate_ci_target(url: str, *, actions: str, environment: str) -> None:
    """Reject production, alternate ports, socket/query overrides, and local runs."""
    try:
        parsed = make_url(url)
    except ArgumentError as exc:
        raise ValueError("Destino não é o PostgreSQL descartável do CI.") from exc
    if (
        actions != "true"
        or environment != "test"
        or parsed.drivername != "postgresql+psycopg"
        or parsed.host != "127.0.0.1"
        or parsed.port != 5432
        or parsed.username != "atlas_ci_probe"
        or parsed.database != "atlas_ci_probe"
        or not parsed.password
        or parsed.query
    ):
        raise ValueError("Destino não é o PostgreSQL descartável do CI.")


def main() -> None:
    validate_ci_target(
        os.environ.get("ATLAS_DATABASE_URL", ""),
        actions=os.environ.get("GITHUB_ACTIONS", ""),
        environment=os.environ.get("ATLAS_ENV", ""),
    )
    from app.database import build_engine

    engine = build_engine(for_migrations=True)
    try:
        with engine.connect() as connection:
            assert connection.dialect.name == "postgresql"
            assert connection.scalar(text("SELECT version_num FROM alembic_version")) == EXPECTED_HEAD
            inspector = inspect(connection)
            tables = set(inspector.get_table_names())
            assert "atlas_ai_session_messages" in tables
            assert {"amount_per_animal", "animal_count"} <= {
                column["name"] for column in inspector.get_columns("nutrition_events")
            }
            assert "client_operation_id" in {
                column["name"] for column in inspector.get_columns("weight_records")
            }
            indexes = {item["name"]: item for item in inspector.get_indexes("pasture_grazing_bases")}
            assert indexes[EXPECTED_INDEX]["column_names"] == EXPECTED_COLUMNS
            for table in ("weight_records", "pasture_grazing_bases"):
                constraints = inspector.get_unique_constraints(table)
                unique_indexes = [item for item in inspector.get_indexes(table) if item.get("unique")]
                assert any(
                    item["column_names"] == ["company_id", "client_operation_id"]
                    for item in constraints + unique_indexes
                ), table
    finally:
        engine.dispose()
    print("PostgreSQL CI: head 0059, esquema, índice e unicidades aprovados.")


if __name__ == "__main__":
    main()
