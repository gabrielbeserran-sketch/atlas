"""Read-only contract check for the fresh, loopback-only GitHub Actions service.

This does not accept an external database target or run migrations itself.
"""

from __future__ import annotations

import os
import sys
from datetime import datetime, timedelta, timezone

from sqlalchemy import inspect, text
from sqlalchemy.engine import make_url
from sqlalchemy.exc import ArgumentError


EXPECTED_HEAD = "20260929_0059"
EXPECTED_INDEX = "ix_pasture_grazing_scope_created_id"
EXPECTED_COLUMNS = ["tenant_id", "company_id", "farm_id", "created_at", "id"]
SEEDED_ROWS = 1000


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


def seed(engine) -> None:
    """Populate only our fresh 0058 service before the 0059 index exists."""
    from app.models import Company, Farm, PastureGrazingBasis, User

    with engine.begin() as connection:
        assert connection.scalar(text("SELECT version_num FROM alembic_version")) == "20260929_0058"
        assert connection.scalar(text("SELECT COUNT(*) FROM pasture_grazing_bases")) == 0
        connection.execute(Company.__table__.insert().values(
            id="ci-company", tenant_id="ci-tenant", name="CI descartável",
        ))
        connection.execute(User.__table__.insert().values(
            id="ci-user", name="Operador CI", email="ci-probe@atlas.invalid",
            password_hash="not-a-login",
        ))
        connection.execute(Farm.__table__.insert().values(
            id="ci-farm", tenant_id="ci-tenant", company_id="ci-company",
            name="Fazenda descartável",
        ))
        start = datetime(2026, 9, 1, tzinfo=timezone.utc)
        connection.execute(PastureGrazingBasis.__table__.insert(), [
            {
                "id": f"ci-grazing-{index:04d}",
                "tenant_id": "ci-tenant",
                "company_id": "ci-company",
                "farm_id": "ci-farm",
                "client_operation_id": f"ci-operation-{index:04d}",
                "effective_area_ha": 20.5,
                "grazing_animals": index % 100 + 1,
                "unique_area_confirmed": True,
                "recorded_at": start + timedelta(minutes=index),
                "created_at": start + timedelta(minutes=index),
                "created_by": "ci-user",
            }
            for index in range(SEEDED_ROWS)
        ])
    print(f"PostgreSQL CI: {SEEDED_ROWS} linhas preexistentes em 0058.")


def verify(engine) -> None:
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
        row_count, animal_sum = connection.execute(text(
            "SELECT COUNT(*), SUM(grazing_animals) FROM pasture_grazing_bases "
            "WHERE tenant_id='ci-tenant' AND company_id='ci-company' AND farm_id='ci-farm'"
        )).one()
        assert row_count == SEEDED_ROWS and animal_sum == 50500
        connection.execute(text("SET LOCAL enable_seqscan = off"))
        plan = "\n".join(row[0] for row in connection.execute(text(
            "EXPLAIN SELECT id FROM pasture_grazing_bases "
            "WHERE tenant_id='ci-tenant' AND company_id='ci-company' AND farm_id='ci-farm' "
            "ORDER BY created_at, id LIMIT 50"
        )))
        assert EXPECTED_INDEX in plan


def main() -> None:
    action = sys.argv[1] if len(sys.argv) == 2 else "verify"
    if action not in {"seed", "verify"}:
        raise ValueError("Ação de prova CI inválida.")
    validate_ci_target(
        os.environ.get("ATLAS_DATABASE_URL", ""),
        actions=os.environ.get("GITHUB_ACTIONS", ""),
        environment=os.environ.get("ATLAS_ENV", ""),
    )
    from app.database import build_engine

    engine = build_engine(for_migrations=True)
    try:
        if action == "seed":
            seed(engine)
        else:
            verify(engine)
    finally:
        engine.dispose()
    if action == "verify":
        print("PostgreSQL CI: 0058→0059 preservou linhas, esquema, índice e unicidades.")


if __name__ == "__main__":
    main()
