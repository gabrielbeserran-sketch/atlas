from pathlib import Path

root = Path(__file__).resolve().parents[2]

http = (root / "lib/core/network/atlas_http_client.dart").read_text(
    encoding="utf-8"
)
store = (
    root
    / "lib/features/enterprise_platform/data/services/"
    / "atlas_enterprise_remote_auth_store.dart"
).read_text(encoding="utf-8")
env = (root / "lib/core/network/atlas_environment.dart").read_text(
    encoding="utf-8"
)
authz = (root / "backend/app/authz.py").read_text(encoding="utf-8")
livestock = (
    root / "backend/app/routers/livestock.py"
).read_text(encoding="utf-8")

checks = {
    "idempotent_retry_only": "_isIdempotentMethod" in http,
    "mutation_not_retried_blindly": (
        "transientRetries > 0 && _isIdempotentMethod(method)" in http
    ),
    "retry_after": "retry-after" in http,
    "backoff": "_waitBeforeRetry" in http,
    "single_flight_refresh": "_refreshInFlight" in http,
    "secure_storage_recovery": "_recoverSecureStorage" in store,
    "no_insecure_token_fallback": (
        "_preferences.setString(_sessionKey" not in store
    ),
    "production_https": "Produção exige API HTTPS." in env,
    "production_timeout_60": "receiveTimeout: Duration(seconds: 60)" in env,
    "network_logs_off": "enableNetworkLogs: false" in env,
    "tenant_check": 'claims.get("tenant_id") != company.tenant_id' in authz,
    "role_claim_check": "token_role != membership.role" in authz,
    "refresh_session_required": "session is None" in authz,
    "revocation_check": "session.revoked_at is not None" in authz,
    "session_expiry_check": "Sessão expirada." in authz,
    "livestock_intelligence_permission_catalogued": (
        '"livestock.read"' in authz
        and '"livestock.read", "herd.read"' in authz
    ),
    "farm_scope_company_tenant_enforced": (
        "Farm.company_id == principal.company.id" in livestock
        and "Farm.tenant_id == principal.company.tenant_id" in livestock
        and "_farm_allowed(principal," not in livestock
    ),
}

for name, ok in checks.items():
    print(f"[{'OK' if ok else 'ERRO'}] {name}")

failed = [name for name, ok in checks.items() if not ok]
if failed:
    raise SystemExit(f"REPROVADO: {failed}")

print(f"APROVADO: {len(checks)}/{len(checks)} verificações")
