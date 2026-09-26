import importlib.util
from datetime import datetime
from pathlib import Path

import pytest
import sqlalchemy as sa
from alembic.migration import MigrationContext
from alembic.operations import Operations


def test_additive_migration_uniqueness_and_downgrade():
    source = Path(__file__).resolve().parents[1] / "alembic/versions/20260926_0057_pasture_grazing_basis.py"
    spec = importlib.util.spec_from_file_location("grazing_migration", source)
    migration = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(migration)
    engine = sa.create_engine("sqlite:///:memory:")
    metadata = sa.MetaData()
    for name in ("companies", "farms", "users"):
        sa.Table(name, metadata, sa.Column("id", sa.String(80), primary_key=True))
    metadata.create_all(engine)
    with engine.begin() as connection:
        connection.execute(metadata.tables["farms"].insert().values(id="preserved"))
        migration.op = Operations(MigrationContext.configure(connection))
        migration.upgrade()
    table = sa.Table("pasture_grazing_bases", sa.MetaData(), autoload_with=engine)
    values = dict(tenant_id="t", company_id="c", farm_id="preserved", client_operation_id="operation",
                  effective_area_ha=20.5, grazing_animals=30, unique_area_confirmed=True,
                  recorded_at=datetime(2026, 9, 26),
                  created_at=datetime(2026, 9, 26), created_by="u")
    with engine.begin() as connection:
        connection.execute(table.insert().values(id="one", **values))
    with pytest.raises(sa.exc.IntegrityError):
        with engine.begin() as connection:
            connection.execute(table.insert().values(id="two", **values))
    with engine.begin() as connection:
        connection.execute(table.insert().values(id="three", **{**values, "company_id": "other"}))
        migration.op = Operations(MigrationContext.configure(connection))
        migration.downgrade()
        assert connection.scalar(sa.select(metadata.tables["farms"].c.id)) == "preserved"
    assert "pasture_grazing_bases" not in sa.inspect(engine).get_table_names()
