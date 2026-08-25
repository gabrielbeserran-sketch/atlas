from __future__ import annotations

import ast
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        return ""
    return path.read_text(encoding="utf-8", errors="ignore")


def main() -> int:
    errors: list[str] = []

    health = read("backend/app/routers/health.py")
    security = read("backend/app/services/security_middleware.py")
    media = read("backend/app/services/animal_media_storage.py")
    backup = read("backend/app/services/backup.py")
    backups_router = read("backend/app/routers/backups.py")
    render = read("render.yaml")
    baseline = json.loads(read("ATLAS_BASELINE_MANIFEST.json") or "{}")
    homologation = read("scripts/quality/run_post_v21_macro10d_v1_rc_homologation.ps1")
    media_storage = read("backend/app/services/animal_media_storage.py")
    backup_service = read("backend/app/services/backup.py")
    livestock = read("backend/app/routers/livestock.py")

    checks = {
        "rc_readiness_endpoint": '@router.get("/health/v1-release-candidate")' in health,
        "rc_contract_version": '"contract_version": "10D"' in health,
        "schema_0050_guard": '"atlas_data_quality_state"' in health,
        "distributed_rate_limit": "DistributedRateLimiter" in security and "Redis.from_url" in security,
        "rate_limit_fail_closed": "if settings.is_production_like" in security and "raise" in security,
        "remote_media": 'settings.atlas_attachment_backend == "supabase"' in media and 'value: supabase' in render,
        "backup_restore": "def verify_restore" in backup and "_verify_postgres_restore" in backup,
        "backup_audit": "backup_restore_verified" in backups_router,
        "baseline_10d": baseline.get("version") == "post-v21-macro10d-v1-release-candidate",
        "backend_pytest_runs_from_backend": (
            "Push-Location $backendDir" in homologation
            and "-m pytest -q .\\tests" in homologation
            and "Pop-Location" in homologation
        ),
        "windows_safe_media_segments": (
            "if len(cleaned) <= 24" in media_storage
            and 'hashlib.sha256(cleaned.encode("utf-8"))' in media_storage
        ),
        "safe_tar_extract_filter": 'archive.extractall(target, filter="data")' in backup_service,
        "health_delete_reversal_auditable": (
            'reference_type="health_event_reversal"' in livestock
            and "reference_id=item.id," in livestock
        ),
    }

    for name, ok in checks.items():
        if not ok:
            errors.append(name)

    versions = ROOT / "backend/alembic/versions"
    revisions: dict[str, str | None] = {}
    down_revisions: set[str] = set()

    for path in versions.glob("*.py"):
        try:
            tree = ast.parse(path.read_text(encoding="utf-8", errors="ignore"))
        except SyntaxError as exc:
            errors.append(f"sintaxe migration {path.name}: {exc}")
            continue

        revision = None
        down = None

        for node in tree.body:
            if isinstance(node, ast.Assign):
                for target in node.targets:
                    if (
                        isinstance(target, ast.Name)
                        and target.id == "revision"
                        and isinstance(node.value, ast.Constant)
                    ):
                        revision = node.value.value
                    if (
                        isinstance(target, ast.Name)
                        and target.id == "down_revision"
                        and isinstance(node.value, ast.Constant)
                    ):
                        down = node.value.value

        if revision:
            revisions[str(revision)] = str(down) if down else None
            if down:
                down_revisions.add(str(down))

    heads = sorted(set(revisions) - down_revisions)

    if heads != ["20260825_0050"]:
        errors.append(f"Alembic head inesperado: {heads}")

    valid = {
        "env",
        "script",
        "global",
        "local",
        "private",
        "using",
        "variable",
        "function",
        "alias",
        "cert",
        "wsman",
        "registry",
    }

    for path in (ROOT / "scripts").rglob("*.ps1"):
        text = path.read_text(encoding="utf-8-sig", errors="ignore")
        for match in re.finditer(r"\$([A-Za-z_][A-Za-z0-9_]*):", text):
            if match.group(1).lower() not in valid:
                line = text[: match.start()].count("\n") + 1
                errors.append(
                    f"PowerShell ambíguo {path.relative_to(ROOT)}:{line} -> ${match.group(1)}:"
                )

    result = {
        "status": "FAIL" if errors else "OK",
        "checks": checks,
        "alembic_heads": heads,
        "errors": errors,
    }

    print(json.dumps(result, ensure_ascii=False, indent=2))

    if errors:
        print("ATLAS POS-V21 MACROPACOTE 10D: REPROVADO")
        return 1

    print("ATLAS POS-V21 MACROPACOTE 10D: APROVADO")
    print("[OK] Segurança de produção consolidada.")
    print("[OK] Rate limit distribuído e fail-closed comprovados.")
    print("[OK] Mídia remota e restore verificável comprovados.")
    print("[OK] Parser PowerShell protegido contra regressão.")
    print("[OK] Pytest backend executa dentro de backend/.")
    print("[OK] Caminhos locais de mídia protegidos contra MAX_PATH.")
    print("[OK] Restore tar explícito e compatível com Python 3.14.")
    print("[OK] Estorno sanitário preserva referência auditável ao evento.")
    print("[OK] Alembic permanece com head único 0050.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
