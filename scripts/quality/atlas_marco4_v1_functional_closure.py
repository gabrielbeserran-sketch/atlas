from __future__ import annotations

import csv
import json
from dataclasses import dataclass, asdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


@dataclass(frozen=True)
class Contract:
    module: str
    layer: str
    path: str
    required_markers: tuple[str, ...] = ()
    forbidden_markers: tuple[str, ...] = ()
    disposition: str = "v1_remote"
    note: str = ""


CONTRACTS: tuple[Contract, ...] = (
    Contract("Fazendas", "service", "lib/features/farm/data/services/farm_storage_service.dart", ("/farms",), disposition="v1_remote_cache"),
    Contract("Detalhes da Fazenda", "screen", "lib/features/farm/presentation/screens/farm_detail_screen.dart", forbidden_markers=("atlas_predictive_scenario_storage_service.dart", "predictive/domain/models/atlas_predictive_scenario.dart")),
    Contract("Rebanho", "service", "lib/features/herd/data/services/herd_storage_service.dart", ("/farms",), disposition="v1_remote_cache"),
    Contract("Animais", "cache", "lib/features/animal/data/services/animal_storage_service.dart", ("AnimalEnterpriseService", "/livestock/lots"), disposition="v1_remote_cache"),
    Contract("Animais", "remote", "lib/features/animal/data/services/animal_enterprise_service.dart", ("/livestock/animals", "POST", "PATCH", "DELETE")),
    Contract("Central do Animal", "screen", "lib/features/animal/presentation/screens/animal_detail_screen.dart", ("AnimalPhotoGalleryScreen", "AnimalDocumentListScreen")),
    Contract("Agenda", "service", "lib/features/farm_agenda/data/services/farm_agenda_storage_service.dart", ("/operations/tasks", "PATCH", "cancelled", "_fetchRemoteTasks"), disposition="v1_remote_cache"),
    Contract("Financeiro", "service", "lib/features/farm_finance/data/services/farm_finance_storage_service.dart", ("/livestock/finance/v2", "PATCH", "DELETE"), disposition="v1_remote_cache"),
    Contract("Estoque", "service", "lib/features/farm_inventory/data/services/farm_inventory_storage_service.dart", ("/livestock/inventory/products/v2", "/movements/v2", "PATCH", "DELETE"), disposition="v1_remote_cache"),
    Contract("Piquetes", "service", "lib/features/paddock/data/services/paddock_storage_service.dart", ("/livestock/paddocks", "PATCH", "DELETE")),
    Contract("Nutrição", "service", "lib/features/nutrition/data/services/nutrition_storage_service.dart", ("/livestock/nutrition/plans", "PATCH", "DELETE"), disposition="v1_remote_cache"),
    Contract("Reprodução", "backend", "backend/app/routers/livestock.py", ("/animals/{animal_id}/reproduction", "reproduction_event", "expected_date")),
    Contract("Sanidade", "backend", "backend/app/routers/livestock.py", ("/health", "health_event", "health_event_reversal")),
    Contract("Pesagens", "backend", "backend/app/routers/livestock.py", ("/weights",)),
    Contract("Genealogia", "backend", "backend/app/routers/animals.py", ("genealogy",)),
    Contract("Movimentações", "backend", "backend/app/routers/livestock.py", ("movement",)),
    Contract(
        "Fotos",
        "attachment",
        "lib/features/animal_photo/data/services/animal_photo_storage_service.dart",
        ("AnimalMediaRemoteService", "_remote.list", "_remote.create", "atlas_animal_photos_cache_"),
        disposition="v1_remote_cache",
        note="Backend animal-media é autoridade; cache local é subordinado.",
    ),
    Contract(
        "Documentos",
        "attachment",
        "lib/features/animal_document/data/services/animal_document_storage_service.dart",
        ("AnimalMediaRemoteService", "_remote.list", "_remote.create", "atlas_animal_documents_cache_"),
        disposition="v1_remote_cache",
        note="Backend animal-media é autoridade; cache local é subordinado.",
    ),
    Contract(
        "Documentos",
        "platform",
        "lib/features/animal_document/presentation/screens/animal_document_list_screen.dart",
        ("AtlasExternalOpenService.open",),
        forbidden_markers=("Process.start('cmd'",),
        disposition="v1_android",
        note="Abertura multiplataforma; Android usa FileProvider.",
    ),
    Contract(
        "Fotos",
        "platform",
        "lib/features/animal_photo/presentation/screens/animal_photo_form_screen.dart",
        ("ImageSource.gallery", "ImageSource.camera", "retrieveLostData"),
        forbidden_markers=("Caminho da imagem",),
        disposition="v1_android",
        note="Android usa seletor de mídia/câmera; caminho manual foi removido.",
    ),
)

REQUIRED_TESTS = (
    "backend/tests/test_core_livestock_validation.py",
    "backend/tests/test_animal_genealogy.py",
    "backend/tests/test_animal_timeline_history.py",
    "backend/tests/test_farm_scope_regression.py",
    "backend/tests/test_marco2_management_crud.py",
    "backend/tests/test_marco3_agenda_integrations.py",
)

EXPECTED_PRODUCTION_BLOCKERS: set[str] = set()

EXPECTED_ANDROID_BLOCKERS: set[str] = set()


def main() -> int:
    rows: list[dict[str, object]] = []
    unexpected_errors: list[str] = []
    production_blockers: set[str] = set()
    android_blockers: set[str] = set()

    for contract in CONTRACTS:
        path = ROOT / contract.path
        exists = path.exists()
        text = path.read_text(encoding="utf-8", errors="ignore") if exists else ""
        missing = [marker for marker in contract.required_markers if marker not in text]
        forbidden = [marker for marker in contract.forbidden_markers if marker in text]
        ok = exists and not missing and not forbidden

        if contract.disposition == "marco5_production_blocker" and ok:
            production_blockers.add(contract.path)
        elif contract.disposition == "marco6_android_blocker" and ok:
            android_blockers.add(contract.path)
        elif not ok:
            unexpected_errors.append(
                f"{contract.module}/{contract.layer}: {contract.path}; "
                f"exists={exists}; missing={missing}; forbidden={forbidden}"
            )

        rows.append({
            **asdict(contract),
            "exists": exists,
            "missing_markers": " | ".join(missing),
            "forbidden_markers_found": " | ".join(forbidden),
            "contract_ok": ok,
        })

    missing_tests = [item for item in REQUIRED_TESTS if not (ROOT / item).exists()]
    if missing_tests:
        unexpected_errors.extend(f"Teste obrigatório ausente: {item}" for item in missing_tests)

    if production_blockers != EXPECTED_PRODUCTION_BLOCKERS:
        unexpected_errors.append(
            "Conjunto de bloqueadores de produção de anexos divergiu do esperado: "
            f"{sorted(production_blockers)}"
        )
    if android_blockers != EXPECTED_ANDROID_BLOCKERS:
        unexpected_errors.append(
            "Conjunto de bloqueadores Android divergiu do esperado: "
            f"{sorted(android_blockers)}"
        )

    report = {
        "contract_count": len(CONTRACTS),
        "unexpected_contract_errors": unexpected_errors,
        "required_regression_tests": list(REQUIRED_TESTS),
        "missing_regression_tests": missing_tests,
        "marco5_production_blockers": sorted(production_blockers),
        "marco6_android_blockers": sorted(android_blockers),
        "marco4d_status": "closed_with_explicit_downstream_blockers" if not unexpected_errors else "failed",
        "decision": (
            "Os fluxos operacionais V1 auditados mantêm autoridade remota/cache controlado. "
            "Fotos e Documentos possuem autoridade remota desde o Marco 5 e a experiência Android "
            "foi substituída por Photo Picker/câmera/FileProvider no Marco 6. Não restam bloqueadores "
            "de produção ou Android dentro deste contrato V1."
        ),
    }

    (ROOT / "ATLAS_MARCO4D_FECHAMENTO_FUNCIONAL.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    with (ROOT / "ATLAS_MARCO4D_MATRIZ_V1.csv").open("w", encoding="utf-8-sig", newline="") as handle:
        fieldnames = list(rows[0].keys()) if rows else ["module"]
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(json.dumps(report, ensure_ascii=False, indent=2))
    if unexpected_errors:
        print("ATLAS MARCO 4D V1 FUNCTIONAL CLOSURE: FAIL")
        return 1
    print("ATLAS MARCO 4D V1 FUNCTIONAL CLOSURE: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
