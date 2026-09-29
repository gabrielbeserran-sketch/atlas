"""A revisão 0058 preserva quantidades históricas e conversas antigas."""

import importlib.util
from pathlib import Path

import sqlalchemy as sa
from alembic.migration import MigrationContext
from alembic.operations import Operations


def test_additive_repair_preserves_legacy_rows():
    source = (Path(__file__).resolve().parents[1] / "alembic" / "versions"
              / "20260929_0058_schema_contract_repair.py")
    spec = importlib.util.spec_from_file_location("schema_repair", source)
    migration = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(migration)
    engine = sa.create_engine("sqlite:///:memory:")
    metadata = sa.MetaData()
    sa.Table("atlas_ai_sessions", metadata, sa.Column("id", sa.String(80), primary_key=True))
    legacy_messages = sa.Table(
        "atlas_ai_messages", metadata,
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("content", sa.Text()),
    )
    nutrition = sa.Table(
        "nutrition_events", metadata,
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("quantity_per_head", sa.Float()),
    )
    metadata.create_all(engine)
    with engine.begin() as connection:
        connection.execute(nutrition.insert().values(id="old", quantity_per_head=2.5))
        connection.execute(legacy_messages.insert().values(id="old-ai", content="preservado"))
        migration.op = Operations(MigrationContext.configure(connection))
        migration.upgrade()

    inspector = sa.inspect(engine)
    assert "atlas_ai_session_messages" in inspector.get_table_names()
    assert {"amount_per_animal", "animal_count"} <= {
        item["name"] for item in inspector.get_columns("nutrition_events")
    }
    with engine.connect() as connection:
        record = connection.execute(sa.text(
            "SELECT quantity_per_head, amount_per_animal, animal_count "
            "FROM nutrition_events WHERE id='old'"
        )).one()
        assert record == (2.5, 2.5, 0)
        assert connection.execute(sa.select(legacy_messages.c.content)).scalar_one() == "preservado"
