from __future__ import annotations

from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]


def test_alembic_env_installs_reconciliation_guards() -> None:
    text = (BACKEND_ROOT / "alembic" / "env.py").read_text(
        encoding="utf-8"
    )
    assert "install_reconciliation_guards" in text
    assert "with install_reconciliation_guards():" in text


def test_reconciliation_covers_destructive_duplicate_risks() -> None:
    text = (BACKEND_ROOT / "alembic" / "reconcile.py").read_text(
        encoding="utf-8"
    )
    assert "safe_create_table" in text
    assert "safe_create_index" in text
    assert "safe_add_column" in text
    assert "safe_create_unique_constraint" in text


def test_startup_checks_schema_after_alembic() -> None:
    text = (BACKEND_ROOT / "scripts" / "render_start.sh").read_text(
        encoding="utf-8"
    )
    assert "python -m alembic upgrade head" in text
    assert "python -m scripts.render_post_migration_check" in text
    assert "python -m scripts.render_schema_contract_check" in text

    alembic_pos = text.index("python -m alembic upgrade head")
    head_pos = text.index("python -m scripts.render_post_migration_check")
    schema_pos = text.index("python -m scripts.render_schema_contract_check")

    assert alembic_pos < head_pos < schema_pos


def test_schema_contract_is_blocking_for_missing_tables_and_columns() -> None:
    text = (
        BACKEND_ROOT / "scripts" / "render_schema_contract_check.py"
    ).read_text(encoding="utf-8")
    assert "tabela ausente:" in text
    assert "coluna ausente:" in text
    assert "ATLAS SCHEMA CONTRACT: FAIL" in text
