"""Índice de cursor em base descartável; não toca atlas_test.db."""

import importlib.util
from datetime import datetime, timedelta
from pathlib import Path

import sqlalchemy as sa
from alembic.migration import MigrationContext
from alembic.operations import Operations

from app.models import PastureGrazingBasis


VERSIONS = Path(__file__).resolve().parents[1] / "alembic" / "versions"


def migration(filename: str):
    spec = importlib.util.spec_from_file_location(filename, VERSIONS / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_cursor_index_upgrade_plan_and_downgrade_preserve_rows():
    create_table = migration("20260926_0057_pasture_grazing_basis.py")
    add_index = migration("20260929_0059_grazing_cursor_index.py")
    engine = sa.create_engine("sqlite:///:memory:")
    metadata = sa.MetaData()
    for name in ("companies", "farms", "users"):
        sa.Table(name, metadata, sa.Column("id", sa.String(80), primary_key=True))
    metadata.create_all(engine)

    with engine.begin() as connection:
        operations = Operations(MigrationContext.configure(connection))
        create_table.op = operations
        create_table.upgrade()
        table = sa.Table("pasture_grazing_bases", sa.MetaData(), autoload_with=connection)
        origin = datetime(2026, 1, 1)
        connection.execute(table.insert(), [
            {
                "id": f"server-{i}", "tenant_id": "t", "company_id": "c",
                "farm_id": "f", "client_operation_id": f"operation-{i}",
                "effective_area_ha": 20, "grazing_animals": 30,
                "unique_area_confirmed": True, "recorded_at": origin,
                "created_at": origin + timedelta(seconds=i), "created_by": "u",
            }
            for i in range(5)
        ])
        add_index.op = operations
        add_index.upgrade()

    inspector = sa.inspect(engine)
    composite = next(index for index in inspector.get_indexes("pasture_grazing_bases")
                     if index["name"] == add_index.INDEX)
    assert composite["column_names"] == add_index.COLUMNS
    assert any(index.name == add_index.INDEX for index in PastureGrazingBasis.__table__.indexes)
    with engine.connect() as connection:
        query = (
            "SELECT id FROM pasture_grazing_bases "
            "WHERE tenant_id='t' AND company_id='c' AND farm_id='f' "
            "ORDER BY created_at DESC, id DESC LIMIT 3"
        )
        plan = connection.exec_driver_sql("EXPLAIN QUERY PLAN " + query).all()
        assert any(add_index.INDEX in str(row) for row in plan)
        assert all("TEMP B-TREE" not in str(row) for row in plan)
        assert connection.exec_driver_sql(query).scalars().all() == [
            "server-4", "server-3", "server-2",
        ]
    with engine.begin() as connection:
        add_index.op = Operations(MigrationContext.configure(connection))
        add_index.downgrade()
        assert connection.exec_driver_sql(
            "SELECT COUNT(*) FROM pasture_grazing_bases"
        ).scalar_one() == 5
    assert add_index.INDEX not in {
        item["name"] for item in sa.inspect(engine).get_indexes("pasture_grazing_bases")
    }
    engine.dispose()
