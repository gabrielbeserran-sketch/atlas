from __future__ import annotations

from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]


def test_diagnostic_never_prints_password_or_hash() -> None:
    text = (
        BACKEND_ROOT / "scripts" / "render_auth_diagnostic.py"
    ).read_text(encoding="utf-8")

    assert "password_match=" in text
    assert "verify_password(" in text
    assert "print(candidate_password)" not in text
    assert "print(user.password_hash)" not in text


def test_reset_requires_active_company_administrator() -> None:
    text = (
        BACKEND_ROOT
        / "scripts"
        / "render_reset_admin_password_once.py"
    ).read_text(encoding="utf-8")

    assert "companyAdministrator" in text
    assert "não possui" in text


def test_reset_unlocks_and_verifies_account() -> None:
    text = (
        BACKEND_ROOT
        / "scripts"
        / "render_reset_admin_password_once.py"
    ).read_text(encoding="utf-8")

    assert "user.active = True" in text
    assert "user.email_verified = True" in text
    assert "user.failed_login_attempts = 0" in text
    assert "user.locked_until = None" in text


def test_reset_verifies_hash_before_commit() -> None:
    text = (
        BACKEND_ROOT
        / "scripts"
        / "render_reset_admin_password_once.py"
    ).read_text(encoding="utf-8")

    assert "verify_password(new_password, user.password_hash)" in text
    assert "post_reset_password_match=true" in text


def test_flags_are_disabled_by_default() -> None:
    config = (BACKEND_ROOT / "app" / "config.py").read_text(
        encoding="utf-8"
    )

    assert "atlas_auth_diagnostic_enabled: bool = False" in config
    assert "atlas_reset_admin_password_once: bool = False" in config
