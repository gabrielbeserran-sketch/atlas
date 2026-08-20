from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def main() -> int:
    errors = read("backend/app/core/errors.py")
    livestock = read("backend/app/routers/livestock.py")
    authz = read("backend/app/authz.py")

    checks = {
        "exception_handlers_use_keyword_status_code": "JSONResponse(status_code=" in errors,
        "exception_handlers_use_keyword_content": "content={" in errors,
        "legacy_positional_jsonresponse_removed": not any(
            f"JSONResponse({code}," in errors for code in (400, 409, 422, 500, 503)
        ),
        "reproduction_summary_normalizes_timezone": "_v10_utc(e.expected_date) >= now" in livestock,
        "health_alerts_normalize_timezone": "_v10_utc(event.next_date) <= limit" in livestock,
        "inventory_alerts_normalize_timezone": "_v10_utc(p.expiry_date) < now" in livestock,
        "livestock_read_permission_catalogued": '"livestock.read"' in authz,
        "farm_scope_is_company_tenant_aware": (
            "Farm.company_id == principal.company.id" in livestock
            and "Farm.tenant_id == principal.company.tenant_id" in livestock
        ),
        "all_farm_scope_calls_are_db_aware": "_farm_allowed(principal," not in livestock,
        "legacy_android_mainactivity_removed": not (
            ROOT / "android/app/src/main/kotlin/com/example/projeto_atlas/MainActivity.kt"
        ).exists(),
        "legacy_alembic_reconcile_removed": not (ROOT / "backend/alembic/reconcile.py").exists(),
    }

    failed = [name for name, ok in checks.items() if not ok]
    for name, ok in checks.items():
        print(f"[{'OK' if ok else 'FAIL'}] {name}")
    print(f"RESULT: {len(checks) - len(failed)}/{len(checks)} checks passed")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
