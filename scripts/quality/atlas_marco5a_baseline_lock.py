from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LOCK = ROOT / "ATLAS_MARCO5A_BASELINE_LOCK.json"
REPORT = ROOT / "ATLAS_MARCO5A_BASELINE_LOCK_REPORT.json"

PROTECTED_FILES = [
    "lib/features/farm/data/services/farm_storage_service.dart",
    "lib/features/herd/data/services/herd_storage_service.dart",
    "lib/features/animal/data/services/animal_storage_service.dart",
    "lib/features/animal/data/services/animal_enterprise_service.dart",
    "lib/features/farm_agenda/data/services/farm_agenda_storage_service.dart",
    "lib/features/farm_finance/data/services/farm_finance_storage_service.dart",
    "lib/features/farm_inventory/data/services/farm_inventory_storage_service.dart",
    "lib/features/paddock/data/services/paddock_storage_service.dart",
    "lib/features/nutrition/data/services/nutrition_storage_service.dart",
    "backend/tests/test_core_livestock_validation.py",
    "backend/tests/test_animal_genealogy.py",
    "backend/tests/test_animal_timeline_history.py",
    "backend/tests/test_farm_scope_regression.py",
    "backend/tests/test_marco2_management_crud.py",
    "backend/tests/test_marco3_agenda_integrations.py",
]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def current_hashes() -> tuple[dict[str, str], list[str]]:
    hashes: dict[str, str] = {}
    errors: list[str] = []
    for relative in PROTECTED_FILES:
        path = ROOT / relative
        if not path.is_file():
            errors.append(f"arquivo protegido ausente: {relative}")
            continue
        hashes[relative] = sha256(path)
    return hashes, errors


def promote_local_baseline() -> int:
    hashes, errors = current_hashes()
    if errors:
        print("ATLAS MARCO 5A BASELINE PROMOTION: FAIL")
        for error in errors:
            print(f" - {error}")
        return 1

    previous: dict[str, object] = {}
    if LOCK.is_file():
        try:
            previous = json.loads(LOCK.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, OSError):
            previous = {}

    data = {
        "schema_version": 2,
        "baseline": "Marco 4E aprovado + correção v8e + baseline local homologada",
        "baseline_origin": "local_full_quality_gate",
        "promoted_at_utc": datetime.now(timezone.utc).isoformat(),
        "purpose": (
            "Impedir regressão silenciosa dos fluxos V1 homologados enquanto "
            "o Marco 5 evolui segurança/produção."
        ),
        "promotion_rule": (
            "Qualquer alteração futura em arquivo protegido exige justificativa "
            "explícita, Quality Gate completo aprovado e promoção intencional."
        ),
        "protected_files": hashes,
        "previous_baseline_origin": previous.get(
            "baseline_origin", "packaged_reference"
        ),
    }
    LOCK.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(
        json.dumps(
            {
                "status": "OK",
                "action": "PROMOTED",
                "baseline_origin": data["baseline_origin"],
                "protected_files_total": len(hashes),
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    print("\nATLAS MARCO 5A BASELINE PROMOTION: OK")
    return 0


def verify() -> int:
    errors: list[str] = []
    if not LOCK.is_file():
        print("ATLAS MARCO 5A BASELINE LOCK: FAIL")
        print(" - ATLAS_MARCO5A_BASELINE_LOCK.json ausente")
        return 1

    data = json.loads(LOCK.read_text(encoding="utf-8"))
    protected = data.get("protected_files", {})
    if not isinstance(protected, dict) or not protected:
        print("ATLAS MARCO 5A BASELINE LOCK: FAIL")
        print(" - lock não possui arquivos protegidos")
        return 1

    for relative, expected in protected.items():
        path = ROOT / relative
        if not path.is_file():
            errors.append(f"arquivo protegido ausente: {relative}")
            continue
        current = sha256(path)
        if current != expected:
            errors.append(
                f"arquivo protegido alterado sem promoção da baseline: {relative}"
            )

    report = {
        "status": "FAIL" if errors else "OK",
        "baseline": data.get("baseline"),
        "baseline_origin": data.get("baseline_origin", "packaged_reference"),
        "protected_files_total": len(protected),
        "errors": errors,
        "rule": data.get("promotion_rule"),
    }
    REPORT.write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print(
        "\nATLAS MARCO 5A BASELINE LOCK:",
        "FAIL" if errors else "OK",
    )
    return 1 if errors else 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--promote-local-approved-baseline",
        action="store_true",
        help=(
            "Regenera intencionalmente o lock a partir da árvore local que "
            "acabou de passar o Full Quality Gate."
        ),
    )
    args = parser.parse_args()
    if args.promote_local_approved_baseline:
        return promote_local_baseline()
    return verify()


if __name__ == "__main__":
    raise SystemExit(main())
