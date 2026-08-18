from __future__ import annotations

from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]


def test_reconciler_lives_under_app_namespace() -> None:
    assert (
        BACKEND_ROOT
        / "app"
        / "migrations"
        / "reconciliation.py"
    ).is_file()


def test_no_local_alembic_reconcile_module_exists() -> None:
    assert not (BACKEND_ROOT / "alembic" / "reconcile.py").exists()


def test_alembic_env_imports_reconciler_from_app_namespace() -> None:
    text = (BACKEND_ROOT / "alembic" / "env.py").read_text(
        encoding="utf-8"
    )
    assert (
        "from app.migrations.reconciliation "
        "import install_reconciliation_guards"
    ) in text
    assert "from alembic.reconcile" not in text


def test_render_import_contract_checks_reconciler() -> None:
    text = (
        BACKEND_ROOT
        / "scripts"
        / "render_import_contract_check.py"
    ).read_text(encoding="utf-8")
    assert '"app.migrations.reconciliation"' in text
