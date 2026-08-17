from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

def read(relative: str) -> str:
    path = ROOT / relative
    return path.read_text(encoding="utf-8", errors="ignore") if path.is_file() else ""

def main() -> int:
    auth = read("backend/app/routers/auth.py")
    authz = read("backend/app/authz.py")
    security = read("backend/app/security.py")
    members = read("backend/app/routers/members.py")
    config = read("backend/app/config.py")
    requirements = read("backend/requirements.txt")
    tests = read("backend/tests/test_marco5c_identity_isolation.py")
    checks = {
        "access_token_contains_session_id": 'extra={"session_id": session.id}' in auth,
        "principal_requires_persisted_session": ("RefreshSession" in authz and "session.revoked_at is not None" in authz and 'claims.get("session_id"' in authz),
        "principal_validates_session_expiry": 'detail="Sessão expirada."' in authz,
        "principal_validates_company_and_tenant": ('company.status != "active"' in authz and 'claims.get("tenant_id") != company.tenant_id' in authz),
        "refresh_rejects_inactive_user": "if user is None or not user.active:" in auth,
        "refresh_rotates_session": ("session.revoked_at = now" in auth and "session.last_used_at = now" in auth),
        "password_reset_revokes_sessions": ("update(RefreshSession)" in auth and "password_reset.completed" in auth),
        "admin_password_reset_revokes_sessions": ("update(RefreshSession)" in members and "user.password_changed_at = now" in members),
        "latest_reset_token_only": ("PasswordResetToken.used_at.is_(None)" in auth and ".values(used_at=now)" in auth),
        "mfa_encrypted_at_rest": ("encrypt_mfa_secret" in auth and "decrypt_mfa_secret" in auth and "Fernet" in security),
        "mfa_key_is_separate_secret": ("atlas_mfa_encryption_key" in config and "ATLAS_MFA_ENCRYPTION_KEY deve ter ao menos 32 caracteres" in config),
        "cryptography_is_explicit_dependency": "cryptography==" in requirements,
        "recovery_code_constant_time": ("hmac.compare_digest" in security and "consume_recovery_code" in security),
        "mfa_challenge_revalidates_tenant": ('claims.get("tenant_id") != company.tenant_id' in auth and 'company.status != "active"' in auth),
        "regression_tests_present": all(marker in tests for marker in (
            "test_logout_revokes_access_token_immediately",
            "test_refresh_rotation_revokes_previous_access_token",
            "test_password_reset_revokes_existing_access_sessions",
            "test_admin_password_reset_revokes_member_access_token",
            "test_mfa_secret_is_encrypted_at_rest_and_challenge_works",
        )),
    }
    errors = [name for name, ok in checks.items() if not ok]
    report = {
        "status": "FAIL" if errors else "OK",
        "checks": checks,
        "errors": errors,
        "security_properties": [
            "logout/revoke/password reset invalidam access token imediatamente",
            "refresh token é rotacionado e sessão anterior é revogada",
            "access token exige sessão persistida ativa",
            "MFA TOTP fica criptografado em repouso",
            "recovery code é comparado em tempo constante e consumido uma vez",
            "challenge MFA revalida usuário, empresa e tenant",
        ],
        "remaining_identity_risks": [
            "rate limit distribuído permanece no Marco 5F",
            "MFA challenge one-time server-side pode ser reforçado em produção de alta criticidade",
            "rotação coordenada da chave de criptografia MFA exigirá procedimento operacional",
        ],
    }
    (ROOT / "ATLAS_MARCO5C_IDENTITY_CONTRACT.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print("\nATLAS MARCO 5C IDENTITY CONTRACT:", "FAIL" if errors else "OK")
    return 1 if errors else 0

if __name__ == "__main__":
    raise SystemExit(main())
