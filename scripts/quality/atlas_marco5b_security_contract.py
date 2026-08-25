from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def read(relative: str) -> str:
    path = ROOT / relative
    return path.read_text(encoding="utf-8", errors="ignore") if path.is_file() else ""


def main() -> int:
    config = read("backend/app/config.py")
    middleware = read("backend/app/services/security_middleware.py")
    media = read("backend/app/services/animal_media_storage.py")
    backups = read("backend/app/services/backup.py")
    backup_router = read("backend/app/routers/backups.py")
    iot = read("backend/app/routers/iot.py")
    main_source = read("backend/app/main.py")
    prod_env = read("backend/.env.production.example")
    render = read("render.yaml")
    tests = read("backend/tests/test_marco5b_production_security.py")

    checks = {
        "bootstrap_blocked_production_like": "ATLAS_BOOTSTRAP_ENABLED deve ser false" in config,
        "docs_blocked_in_production": "ATLAS_DOCS_ENABLED deve ser false em production" in config,
        "https_public_url_required": "ATLAS_PUBLIC_BASE_URL deve usar https://" in config,
        "local_public_host_blocked_in_production": "ATLAS_PUBLIC_BASE_URL não pode apontar para host local" in config,
        "mfa_encryption_key_strength_required": "ATLAS_MFA_ENCRYPTION_KEY deve ter ao menos 32 caracteres" in config,
        "iot_secret_strength_required": "ATLAS_IOT_INGEST_KEY deve ter ao menos 32 caracteres" in config,
        "cors_https_required": "Todas as origens CORS devem usar https://" in config,
        "forwarded_headers_default_untrusted": "atlas_trust_proxy_headers: bool = False" in config,
        "trusted_proxy_cidrs_required": "ATLAS_TRUSTED_PROXY_CIDRS" in config and "trusted_proxy_cidrs" in middleware,
        "xff_only_from_trusted_peer": "_peer_is_trusted_proxy" in middleware and "resolve_client_ip" in middleware,
        "iot_constant_time_compare": "hmac.compare_digest" in iot,
        "root_does_not_force_docs": "if settings.atlas_docs_enabled:" in main_source,
        "distributed_rate_limit_required": (
            "DistributedRateLimiter" in middleware
            and "Redis.from_url" in middleware
            and "ATLAS_REDIS_URL é obrigatório" in config
            and "if settings.is_production_like" in middleware
        ),
        "remote_media_supabase_ready": (
            'atlas_attachment_backend: Literal["local", "supabase"]' in config
            and 'value: supabase' in render
            and 'settings.atlas_attachment_backend == "supabase"' in media
            and "atlas_supabase_service_role_key" in media
        ),
        "backup_restore_verifiable": (
            "def verify_restore" in backups
            and "_verify_postgres_restore" in backups
            and '@router.post("/{filename}/verify-restore")' in backup_router
            and "backup_restore_verified" in backup_router
        ),
        "production_env_template": (
            "ATLAS_ENV=production" in prod_env
            and "ATLAS_DOCS_ENABLED=false" in prod_env
            and "ATLAS_BOOTSTRAP_ENABLED=false" in prod_env
            and "ATLAS_REDIS_URL=" in prod_env
        ),
        "regression_tests_present": (
            "test_untrusted_peer_cannot_spoof_x_forwarded_for" in tests
            and "test_production_rejects_insecure_configuration" in tests
        ),
    }

    errors = [name for name, ok in checks.items() if not ok]
    report = {
        "status": "FAIL" if errors else "OK",
        "checks": checks,
        "errors": errors,
        "resolved_blockers": [
            "SEC-003", "SEC-004", "SEC-005", "SEC-006", "NET-002",
            "NET-003", "ATT-001", "ATT-002", "BKP-002",
        ],
        "remaining_next": [],
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print("\nATLAS MARCO 5B SECURITY CONTRACT:", "FAIL" if errors else "OK")
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
