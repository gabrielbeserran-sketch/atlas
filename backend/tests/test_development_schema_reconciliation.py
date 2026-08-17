from __future__ import annotations

from sqlalchemy import (
    Boolean,
    Column,
    Integer,
    MetaData,
    String,
    Table,
    create_engine,
    inspect,
    text,
)

from app.database import repair_missing_development_columns


def test_repair_adds_missing_columns_without_losing_rows() -> None:
    engine = create_engine("sqlite+pysqlite:///:memory:")

    with engine.begin() as connection:
        connection.execute(
            text("CREATE TABLE legacy_demo (id INTEGER PRIMARY KEY)")
        )
        connection.execute(
            text("INSERT INTO legacy_demo (id) VALUES (1)")
        )

    metadata = MetaData()
    Table(
        "legacy_demo",
        metadata,
        Column("id", Integer, primary_key=True),
        Column("label", String(120), nullable=False, default=""),
        Column("active", Boolean, nullable=False, default=False),
        Column("optional_code", String(80), nullable=True),
    )

    with engine.begin() as connection:
        repaired = repair_missing_development_columns(
            connection,
            metadata,
        )

    columns = {
        item["name"]
        for item in inspect(engine).get_columns("legacy_demo")
    }
    assert columns == {
        "id",
        "label",
        "active",
        "optional_code",
    }

    with engine.connect() as connection:
        row = connection.execute(
            text(
                "SELECT id, label, active, optional_code "
                "FROM legacy_demo WHERE id = 1"
            )
        ).one()

    assert row.id == 1
    assert row.label == ""
    assert row.active in {0, False}
    assert row.optional_code is None
    assert "legacy_demo.label" in repaired
    assert "legacy_demo.active" in repaired
    assert "legacy_demo.optional_code" in repaired


def test_repair_is_idempotent() -> None:
    engine = create_engine("sqlite+pysqlite:///:memory:")
    metadata = MetaData()

    Table(
        "legacy_demo",
        metadata,
        Column("id", Integer, primary_key=True),
        Column("name", String(120), nullable=False, default=""),
    )

    with engine.begin() as connection:
        connection.execute(
            text("CREATE TABLE legacy_demo (id INTEGER PRIMARY KEY)")
        )

    with engine.begin() as connection:
        first = repair_missing_development_columns(
            connection,
            metadata,
        )
    with engine.begin() as connection:
        second = repair_missing_development_columns(
            connection,
            metadata,
        )

    assert first == ["legacy_demo.name"]
    assert second == []
