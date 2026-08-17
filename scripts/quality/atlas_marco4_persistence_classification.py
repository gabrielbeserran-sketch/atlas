from __future__ import annotations

import csv
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIB = ROOT / "lib"
MATRIX = ROOT / "ATLAS_MARCO4_ROUTE_SCREEN_MATRIX.json"

REMOTE_TOKENS = (
    "AtlasHttpClient",
    "AtlasEnterpriseApiClient",
    "EnterpriseService",
    ".send(",
    ".request(",
    "requestList(",
    "/livestock/",
    "/operations/",
)

DEVICE_ATTACHMENT_FILES = {
    "lib/features/animal_photo/data/services/animal_photo_storage_service.dart",
    "lib/features/animal_document/data/services/animal_document_storage_service.dart",
}


def feature_root(path: Path) -> Path | None:
    parts = path.parts
    if len(parts) >= 3 and parts[0] == "lib" and parts[1] == "features":
        return ROOT / "lib" / "features" / parts[2]
    return None


def feature_has_remote(path: Path) -> bool:
    root = feature_root(path)
    if root is None or not root.exists():
        return False
    for dart in root.rglob("*.dart"):
        text = dart.read_text(encoding="utf-8", errors="ignore")
        if any(token in text for token in REMOTE_TOKENS):
            return True
    return False


def classify_preferences(rel: str) -> tuple[str, str, bool]:
    path = ROOT / rel
    text = path.read_text(encoding="utf-8", errors="ignore")
    low = rel.lower()

    if any(token in text for token in REMOTE_TOKENS) or feature_has_remote(Path(rel)):
        return (
            "remote_cache",
            "SharedPreferences funciona como snapshot/cache; a feature possui autoridade remota.",
            False,
        )
    if rel in DEVICE_ATTACHMENT_FILES:
        return (
            "device_attachment_pending_object_storage",
            "Metadados/anexo permanecem no dispositivo; requer object storage remoto antes da produção multi-dispositivo.",
            True,
        )
    if any(token in low for token in ("preference", "attention_preferences", "alert_state")):
        return ("device_preference", "Preferência/estado visual do dispositivo.", False)
    if any(token in low for token in ("history", "event_log")):
        return ("local_history_cache", "Histórico/cache derivado local; não é cadastro pecuário oficial.", False)
    if any(token in low for token in ("offline", "sync_repository", "foundation", "version_repository")):
        return ("offline_runtime", "Infraestrutura local de contingência/sincronização.", False)
    if "/core/operational_intelligence/" in f"/{low}":
        return (
            "advanced_local_planning",
            "Planejamento/inteligência operacional avançada ainda local; não deve ser tratado como fonte oficial V1.",
            False,
        )
    return (
        "advanced_local_feature",
        "Feature avançada mantém dados locais; classificada para evolução posterior, sem confusão com os módulos oficiais V1.",
        False,
    )


def classify_unconsumed_route(route: str) -> tuple[str, str]:
    method, path = route.split(" ", 1)
    if path.startswith("/auth/"):
        return ("marco5_security", "Endpoint de segurança/autenticação a homologar no Marco 5.")
    if path.startswith("/livestock/"):
        return ("backend_capability", "Capacidade backend pecuária não exigida pela UI atual; preservada para API/automação.")
    if path.startswith("/operations/"):
        return ("backend_capability", "Capacidade operacional backend para automação/exportação/ações internas.")
    if path.startswith(("/admin", "/billing", "/commercial", "/business", "/release", "/publication")):
        return ("admin_or_business_api", "API administrativa/comercial, não dependente da UI pecuária principal.")
    if path.startswith(("/automation", "/data-platform", "/analytics", "/ai", "/atlas-ai", "/atlas-brain", "/atlas-vision")):
        return ("platform_api", "API de plataforma/IA/automação com consumo externo ou futuro permitido.")
    return ("advanced_backend_api", "Endpoint de domínio avançado sem consumidor Flutter obrigatório na V1.")


def main() -> int:
    data = json.loads(MATRIX.read_text(encoding="utf-8"))
    pref_rows = []
    blocking = []
    for rel in data["shared_preferences_files"]:
        category, reason, is_blocking = classify_preferences(rel)
        row = {"file": rel, "category": category, "reason": reason, "blocking_before_production": is_blocking}
        pref_rows.append(row)
        if is_blocking:
            blocking.append(rel)

    route_rows = []
    for route in data["routes_without_obvious_consumer"]:
        category, reason = classify_unconsumed_route(route)
        route_rows.append({"route": route, "category": category, "reason": reason})

    counts: dict[str, int] = {}
    for row in pref_rows:
        counts[row["category"]] = counts.get(row["category"], 0) + 1
    route_counts: dict[str, int] = {}
    for row in route_rows:
        route_counts[row["category"]] = route_counts.get(row["category"], 0) + 1

    report = {
        "shared_preferences_total": len(pref_rows),
        "shared_preferences_categories": counts,
        "production_attachment_blockers": blocking,
        "routes_without_ui_consumer_total": len(route_rows),
        "route_categories": route_counts,
        "notes": [
            "Rota sem consumidor Flutter não é automaticamente órfã; o backend também atende automações, integrações, admin e API.",
            "SharedPreferences em remote_cache é contingência; não é autoridade quando conectado.",
            "Fotos e documentos exigem object storage remoto antes de homologação multi-dispositivo/produção.",
        ],
    }
    (ROOT / "ATLAS_MARCO4_PERSISTENCIA_CLASSIFICADA.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    with (ROOT / "ATLAS_MARCO4_PERSISTENCIA.csv").open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["file", "category", "reason", "blocking_before_production"])
        writer.writeheader()
        writer.writerows(pref_rows)

    with (ROOT / "ATLAS_MARCO4_ROTAS_SEM_UI_CLASSIFICADAS.csv").open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["route", "category", "reason"])
        writer.writeheader()
        writer.writerows(route_rows)

    print(json.dumps(report, ensure_ascii=False, indent=2))
    print("\nATLAS MARCO 4 CLASSIFICATION: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
