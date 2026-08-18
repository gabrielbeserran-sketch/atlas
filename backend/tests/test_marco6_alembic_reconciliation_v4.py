from __future__ import annotations

from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]
RECONCILER = (
    BACKEND_ROOT
    / "app"
    / "migrations"
    / "reconciliation.py"
)


def _text() -> str:
    return RECONCILER.read_text(encoding="utf-8")


def test_existing_declarative_indexes_are_filtered() -> None:
    text = _text()
    assert "_filter_existing_table_elements" in text
    assert "isinstance(element, sa.Index)" in text
    assert "objeto declarativo existente preservado" in text


def test_existing_declarative_constraints_are_filtered() -> None:
    text = _text()
    assert "sa.UniqueConstraint" in text
    assert "sa.ForeignKeyConstraint" in text
    assert "sa.CheckConstraint" in text
    assert "sa.PrimaryKeyConstraint" in text


def test_raw_create_index_sql_is_guarded() -> None:
    text = _text()
    assert "def safe_execute" in text
    assert 'upper.startswith("CREATE INDEX ")' in text
    assert 'upper.startswith("CREATE UNIQUE INDEX ")' in text
    assert "raw SQL indice existente preservado" in text


def test_execute_is_restored_after_reconciliation() -> None:
    text = _text()
    assert "original_execute = op.execute" in text
    assert "op.execute = safe_execute" in text
    assert "op.execute = original_execute" in text
