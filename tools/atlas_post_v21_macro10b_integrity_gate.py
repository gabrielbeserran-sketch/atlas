from __future__ import annotations

import ast
import csv
import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
CSV_PATH = DOCS / "ATLAS_POS_V21_MACRO10B_INTEGRITY_MATRIX.csv"
JSON_PATH = DOCS / "ATLAS_POS_V21_MACRO10B_INTEGRITY_MATRIX.json"

CANONICAL_INTELLIGENCE_SERVICE = (
    "lib/features/dashboard/data/services/atlas_operational_intelligence_service.dart"
)
INTELLIGENCE_ENDPOINTS = (
    "/livestock/intelligence/operational-summary",
    "/livestock/intelligence/operational-alerts",
)
CORE_FEATURES = {
    "Fazenda": "farm",
    "Rebanho": "herd",
    "Animal": "animal",
    "Reprodução": "animal_reproduction",
    "Sanidade": "animal_health",
    "Nutrição": "nutrition",
    "Piquetes": "paddock",
    "Estoque": "farm_inventory",
    "Financeiro": "farm_finance",
    "Agenda": "farm_agenda",
    "Consultoria": "consultancy_client",
    "Dashboard": "dashboard",
}


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8", errors="ignore")


def python_syntax_errors() -> list[str]:
    errors: list[str] = []
    for base in (ROOT / "backend/app", ROOT / "backend/alembic/versions", ROOT / "tools"):
        for path in base.rglob("*.py"):
            if "__pycache__" in path.parts:
                continue
            try:
                ast.parse(path.read_text(encoding="utf-8", errors="ignore"))
            except SyntaxError as exc:
                errors.append(f"{path.relative_to(ROOT)}:{exc.lineno}:{exc.msg}")
    return errors


def intelligence_direct_call_violations() -> list[str]:
    violations: list[str] = []
    for path in (ROOT / "lib").rglob("*.dart"):
        rel = str(path.relative_to(ROOT)).replace("\\", "/")
        text = path.read_text(encoding="utf-8", errors="ignore")
        if rel == CANONICAL_INTELLIGENCE_SERVICE:
            continue
        for endpoint in INTELLIGENCE_ENDPOINTS:
            if endpoint in text:
                violations.append(f"{rel} chama diretamente {endpoint}")
    return violations


def core_matrix() -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for label, folder in CORE_FEATURES.items():
        base = ROOT / "lib/features" / folder
        dart_files = list(base.rglob("*.dart")) if base.exists() else []
        screens = [p for p in dart_files if "/presentation/screens/" in str(p).replace("\\", "/")]
        services = [p for p in dart_files if "/services/" in str(p).replace("\\", "/")]
        remote_files = []
        local_cache_files = []
        for p in services:
            text = p.read_text(encoding="utf-8", errors="ignore")
            if "AtlasEnterpriseApiClient" in text or "AtlasHttpClient" in text or ".request(" in text or ".requestList(" in text:
                remote_files.append(p)
            if "SharedPreferences" in text or "shared_preferences" in text:
                local_cache_files.append(p)
        rows.append(
            {
                "module": label,
                "feature_folder": folder,
                "dart_files": len(dart_files),
                "screens": len(screens),
                "services": len(services),
                "remote_service_files": len(remote_files),
                "local_cache_service_files": len(local_cache_files),
                "status": "present" if dart_files and screens else "review",
            }
        )
    return rows


def backend_route_metrics() -> dict[str, object]:
    route_pattern = re.compile(r"@router\.(get|post|put|patch|delete)\(")
    total = 0
    by_router: Counter[str] = Counter()
    for path in (ROOT / "backend/app/routers").glob("*.py"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        count = len(route_pattern.findall(text))
        if count:
            by_router[path.stem] = count
            total += count
    return {"route_count": total, "routers_with_routes": len(by_router), "by_router": dict(sorted(by_router.items()))}


def run_full_audit() -> tuple[bool, str]:
    proc = subprocess.run(
        [sys.executable, "scripts/quality/atlas_full_project_audit.py"],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        encoding="utf-8",
        errors="replace",
    )
    return proc.returncode == 0, proc.stdout[-8000:]


def write_matrix(rows: list[dict[str, object]], payload: dict[str, object]) -> None:
    DOCS.mkdir(parents=True, exist_ok=True)
    with CSV_PATH.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    JSON_PATH.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []

    py_errors = python_syntax_errors()
    errors.extend(f"sintaxe Python: {item}" for item in py_errors)

    livestock = read("backend/app/routers/livestock.py")
    model = read("lib/features/dashboard/domain/models/atlas_operational_intelligence_data.dart")
    service = read(CANONICAL_INTELLIGENCE_SERVICE)
    dashboard = read("lib/features/dashboard/presentation/screens/dashboard_screen.dart")
    alert_center = read("lib/features/dashboard/presentation/screens/operational_alert_center_screen.dart")
    consultancy = read("lib/features/consultancy_client/presentation/screens/atlas_client_consultancy_center_screen.dart")

    required = {
        "backend_contract_10b": '"contract_version": "10B"' in livestock,
        "backend_position": '"position": index + 1' in livestock,
        "frontend_priority_fallback": "map['position'] ?? map['priority']" in model,
        "farm_context_guard": "summaryFarmId != farmId || alertsFarmId != farmId" in service,
        "contract_guard": "summaryContract != alertsContract" in service,
        "dashboard_canonical_source": "AtlasOperationalIntelligenceService" in dashboard,
        "alert_center_canonical_source": "AtlasOperationalIntelligenceService" in alert_center,
        "consultancy_canonical_source": "AtlasOperationalIntelligenceService" in consultancy,
        "readiness_10b": "/intelligence/deployment-readiness" in livestock,
    }
    for name, ok in required.items():
        if not ok:
            errors.append(f"contrato ausente: {name}")

    direct_violations = intelligence_direct_call_violations()
    errors.extend(direct_violations)

    matrix = core_matrix()
    for row in matrix:
        if row["status"] != "present":
            errors.append(f"módulo essencial sem tela/estrutura: {row['module']}")
        if int(row["local_cache_service_files"]) and not int(row["remote_service_files"]):
            warnings.append(
                f"{row['module']}: possui serviço local/cache sem autoridade remota no mesmo diretório; "
                "mantido para auditoria detalhada do 10C/10D, sem afirmar regressão automática."
            )

    full_ok, full_output = run_full_audit()
    if not full_ok:
        errors.append("atlas_full_project_audit.py reprovou")

    routes = backend_route_metrics()
    payload = {
        "macro": "10B",
        "status": "FAIL" if errors else "OK",
        "canonical_operational_intelligence": {
            "service": CANONICAL_INTELLIGENCE_SERVICE,
            "endpoints": list(INTELLIGENCE_ENDPOINTS),
            "direct_call_violations": direct_violations,
        },
        "backend": routes,
        "core_modules": matrix,
        "errors": errors,
        "warnings": warnings,
        "full_project_audit_tail": full_output,
    }
    write_matrix(matrix, payload)

    for name, ok in required.items():
        print(("[OK] " if ok else "[ERRO] ") + name)
    print(f"[OK] Matriz essencial: {len(matrix)} módulos auditados.")
    print(f"[OK] Rotas backend detectadas: {routes['route_count']}.")
    print(f"[OK] Chamadas diretas fora da fonte canônica: {len(direct_violations)}.")
    print(f"[OK] Auditoria global existente: {'APROVADA' if full_ok else 'REPROVADA'}.")
    if warnings:
        print(f"[AVISO] {len(warnings)} ponto(s) mantido(s) como dívida explícita, sem falso bloqueio.")
    if errors:
        for error in errors:
            print(f"[ERRO] {error}")
        print("ATLAS POS-V21 MACROPACOTE 10B: REPROVADO")
        return 1
    print("ATLAS POS-V21 MACROPACOTE 10B: APROVADO")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
