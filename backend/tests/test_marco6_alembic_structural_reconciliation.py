from __future__ import annotations

from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]


def test_reconciler_blocks_unsafe_not_null_backfill() -> None:
    text = (
        BACKEND_ROOT
        / "app"
        / "migrations"
        / "reconciliation.py"
    ).read_text(encoding="utf-8")

    assert "UnsafeSchemaReconciliation" in text
    assert "coluna obrigatoria ausente nao pode" in text
    assert "rows > 0" in text
    assert "column.nullable is False" in text


def test_existing_table_is_synchronized_before_preservation() -> None:
    text = (
        BACKEND_ROOT
        / "app"
        / "migrations"
        / "reconciliation.py"
    ).read_text(encoding="utf-8")

    assert "_sync_existing_table_columns" in text
    assert "_apply_missing_column" in text
    assert "tabela existente preservada" in text


def test_index_creation_requires_existing_columns() -> None:
    text = (
        BACKEND_ROOT
        / "app"
        / "migrations"
        / "reconciliation.py"
    ).read_text(encoding="utf-8")

    assert "_assert_columns_exist" in text
    assert "create_index:" in text
    assert "operacao bloqueada porque depende" in text


def test_foreign_key_creation_requires_both_sides() -> None:
    text = (
        BACKEND_ROOT
        / "app"
        / "migrations"
        / "reconciliation.py"
    ).read_text(encoding="utf-8")

    assert "safe_create_foreign_key" in text
    assert "foreign_key_target:" in text


def test_schema_contract_still_blocks_missing_columns() -> None:
    text = (
        BACKEND_ROOT
        / "scripts"
        / "render_schema_contract_check.py"
    ).read_text(encoding="utf-8")

    assert "coluna ausente:" in text
    assert "ATLAS SCHEMA CONTRACT: FAIL" in text
