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
    concurrency = read("backend/app/services/concurrency.py")
    livestock = read("backend/app/routers/livestock.py")
    backup = read("backend/app/services/backup.py")
    compose = read("docker-compose.yml")

    checks = {
        "inventory_row_lock": "with_for_update()" in livestock,
        "reference_advisory_lock": (
            "advisory_transaction_lock" in livestock
            and "pg_advisory_xact_lock" in concurrency
        ),
        "inventory_reference_idempotency": (
            "InventoryMovement.reference_type == reference_type" in livestock
            and "InventoryMovement.reference_id == reference_id" in livestock
        ),
        "finance_reference_idempotency": (
            "FinancialEntry.reference_type == payload.reference_type" in livestock
            and "FinancialEntry.reference_id == payload.reference_id" in livestock
        ),
        "distributed_rate_limiter": (
            "DistributedRateLimiter" in middleware
            and "Redis.from_url" in middleware
        ),
        "redis_required_production": (
            "ATLAS_REDIS_URL é obrigatório" in config
        ),
        "redis_compose_service": (
            "redis:7-alpine" in compose
            and "ATLAS_REDIS_URL: redis://redis:6379/0" in compose
        ),
        "backup_includes_database_and_attachments": (
            "attachments.tar.gz" in backup
            and "database_sha256" in backup
            and "attachments_sha256" in backup
        ),
        "restore_isolated_verification": (
            "createdb" in backup
            and "pg_restore" in backup
            and "dropdb" in backup
            and "verify_restore" in backup
        ),
    }

    errors = [name for name, ok in checks.items() if not ok]
    report = {
        "status": "FAIL" if errors else "OK",
        "checks": checks,
        "errors": errors,
        "production_blockers_expected_after_marco5": [],
        "deferred_to_marco6": [
            "ATT-003 experiência nativa Android para anexos"
        ],
    }

    (ROOT / "ATLAS_MARCO5_FINAL_CONTRACT.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print(
        "\nATLAS MARCO 5 FINAL CONTRACT:",
        "FAIL" if errors else "OK",
    )
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
