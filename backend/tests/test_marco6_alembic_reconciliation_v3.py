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


def test_missing_column_helper_uses_original_callback_not_op_add_column() -> None:
    text = _text()
    assert "_apply_missing_column(plan, original_add_column)" in text

    start = text.index("def _apply_missing_column")
    end = text.index("def _column_names_from_index_spec", start)
    helper = text[start:end]

    assert "op.add_column(" not in helper


def test_existing_table_sync_receives_original_add_column() -> None:
    text = _text()
    assert "add_column_fn=original_add_column" in text


def test_batch_alter_table_is_wrapped() -> None:
    text = _text()
    assert "class _SafeBatchOperations" in text
    assert "class _SafeBatchContext" in text
    assert "safe_batch_alter_table" in text
    assert "op.batch_alter_table = safe_batch_alter_table" in text


def test_batch_duplicate_operations_are_guarded() -> None:
    text = _text()
    assert "batch coluna existente preservada" in text
    assert "batch indice existente preservado" in text
    assert "batch foreign key existente" in text
    assert "drop ignorado" in text


def test_alter_column_validates_target_column_first() -> None:
    text = _text()
    assert "def safe_alter_column" in text
    assert 'operation=f"alter_column:{column_name}"' in text


def test_reconciler_static_audit_exists() -> None:
    assert (
        BACKEND_ROOT
        / "scripts"
        / "audit_alembic_reconciler_contract.py"
    ).is_file()
