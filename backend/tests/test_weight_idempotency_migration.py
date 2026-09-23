from __future__ import annotations

import importlib.util
from pathlib import Path

import pytest
import sqlalchemy as sa
from alembic.migration import MigrationContext
from alembic.operations import Operations
from sqlalchemy.exc import IntegrityError


def test_weight_operation_migration_enforces_company_key_uniqueness():
    migration_path = (
        Path(__file__).resolve().parents[1]
        / "alembic"
        / "versions"
        / "20260923_0056_weight_operation_idempotency.py"
    )
    spec = importlib.util.spec_from_file_location("weight_operation_migration", migration_path)
    assert spec is not None and spec.loader is not None
    migration = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(migration)

    engine = sa.create_engine("sqlite:///:memory:")
    metadata = sa.MetaData()
    sa.Table(
        "weight_records",
        metadata,
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("company_id", sa.String(80), nullable=False),
    )
    metadata.create_all(engine)

    with engine.begin() as connection:
        migration.op = Operations(MigrationContext.configure(connection))
        migration.upgrade()

    inspector = sa.inspect(engine)
    assert "client_operation_id" in {
        column["name"] for column in inspector.get_columns("weight_records")
    }
    assert any(
        constraint["name"] == "uq_weight_company_operation"
        for constraint in inspector.get_unique_constraints("weight_records")
    )

    weights = sa.Table("weight_records", sa.MetaData(), autoload_with=engine)
    with engine.begin() as connection:
        connection.execute(
            weights.insert(),
            [
                {"id": "1", "company_id": "company-a", "client_operation_id": "same-key"},
                {"id": "2", "company_id": "company-b", "client_operation_id": "same-key"},
                {"id": "3", "company_id": "company-a", "client_operation_id": None},
            ],
        )
    with pytest.raises(IntegrityError):
        with engine.begin() as connection:
            connection.execute(
                weights.insert().values(
                    id="4", company_id="company-a", client_operation_id="same-key"
                )
            )
