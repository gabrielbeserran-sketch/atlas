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
    iot = read("backend/app/routers/iot.py")
    main_source = read("backend/app/main.py")
    prod_env = read("backend/.env.production.example")
    tests = read("backend/tests/test_marco5b_production_security.py")

    checks = {
        "bootstrap_blocked_production_like": (
            "ATLAS_BOOTSTRAP_ENABLED deve ser false" in config
        ),
        "docs_blocked_in_production": (
            "ATLAS_DOCS_ENABLED deve ser false em production" in config
        ),
        "https_public_url_required": (
            "ATLAS_PUBLIC_BASE_URL deve usar https://" in config
        ),
        "local_public_host_blocked_in_production": (
            "ATLAS_PUBLIC_BASE_URL não pode apontar para host local" in config
        ),
        "mfa_encryption_key_strength_required": (
            "ATLAS_MFA_ENCRYPTION_KEY deve ter ao menos 32 caracteres" in config
            and "ATLAS_MFA_ENCRYPTION_KEY=" in prod_env
        ),
        "iot_secret_strength_required": (
            "ATLAS_IOT_INGEST_KEY deve ter ao menos 32 caracteres" in config
        ),
        "cors_https_required": (
            "Todas as origens CORS devem usar https://" in config
        ),
        "forwarded_headers_default_untrusted": (
            "atlas_trust_proxy_headers: bool = False" in config
        ),
        "trusted_proxy_cidrs_required": (
            "ATLAS_TRUSTED_PROXY_CIDRS" in config
            and "trusted_proxy_cidrs" in middleware
        ),
        "xff_only_from_trusted_peer": (
            "_peer_is_trusted_proxy" in middleware
            and "resolve_client_ip" in middleware
        ),
        "iot_constant_time_compare": "hmac.compare_digest" in iot,
        "root_does_not_force_docs": (
            'if settings.atlas_docs_enabled:' in main_source
        ),
        "production_redis_required": (
            "ATLAS_REDIS_URL é obrigatório" in config
            and "ATLAS_REDIS_URL=" in prod_env
        ),
        "production_env_template": (
            "ATLAS_ENV=production" in prod_env
            and "ATLAS_DOCS_ENABLED=false" in prod_env
            and "ATLAS_BOOTSTRAP_ENABLED=false" in prod_env
            and "ATLAS_TRUST_PROXY_HEADERS=false" in prod_env
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
            "SEC-003",
            "SEC-004",
            "SEC-005",
            "SEC-006",
            "NET-003",
        ],
        "remaining_next": [
            "NET-002 rate limit compartilhado/distribuído",
            "ATT-001/ATT-002 Fotos e Documentos remotos",
            "BKP-002 restauração homologada",
        ],
    }

    (ROOT / "ATLAS_MARCO5B_SECURITY_CONTRACT.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print(
        "\nATLAS MARCO 5B SECURITY CONTRACT:",
        "FAIL" if errors else "OK",
    )
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
