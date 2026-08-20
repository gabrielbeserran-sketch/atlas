from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUTHZ = ROOT / "app" / "authz.py"


def source() -> str:
    return AUTHZ.read_text(encoding="utf-8")


def test_tenant_claim_must_match_company() -> None:
    assert 'claims.get("tenant_id") != company.tenant_id' in source()


def test_role_claim_cannot_be_stale() -> None:
    assert "token_role != membership.role" in source()


def test_refresh_session_must_exist_and_be_active() -> None:
    text = source()
    assert "session is None" in text
    assert "session.revoked_at is not None" in text
    assert "Sessão expirada." in text
