from __future__ import annotations

from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]


def test_startup_runs_admin_provision_after_schema_contract() -> None:
    text = (BACKEND_ROOT / "scripts" / "render_start.sh").read_text(
        encoding="utf-8"
    )

    schema_pos = text.index(
        "python -m scripts.render_schema_contract_check"
    )
    provision_pos = text.index(
        "python -m scripts.render_provision_admin_once"
    )
    uvicorn_pos = text.index("exec python -m uvicorn")

    assert schema_pos < provision_pos < uvicorn_pos


def test_provisioner_is_disabled_by_default() -> None:
    config = (BACKEND_ROOT / "app" / "config.py").read_text(
        encoding="utf-8"
    )
    assert "atlas_provision_admin_once: bool = False" in config


def test_provisioner_does_not_reset_password_after_active_membership() -> None:
    text = (
        BACKEND_ROOT / "scripts" / "render_provision_admin_once.py"
    ).read_text(encoding="utf-8")

    assert "administrador já provisionado" in text
    assert "nenhuma senha alterada" in text


def test_provisioner_marks_email_verified() -> None:
    text = (
        BACKEND_ROOT / "scripts" / "render_provision_admin_once.py"
    ).read_text(encoding="utf-8")

    assert "user.email_verified = True" in text
    assert "email_verified=True" in text


def test_production_bootstrap_rule_remains_intact() -> None:
    config = (BACKEND_ROOT / "app" / "config.py").read_text(
        encoding="utf-8"
    )

    assert (
        "ATLAS_BOOTSTRAP_ENABLED deve ser false em staging/production"
        in config
    )
