from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

PRODUCTION_FILES = [
    ROOT / "lib/features/farm_handling/presentation/screens/farm_handling_screen.dart",
    ROOT / "lib/features/farm_handling/data/services/farm_handling_enterprise_service.dart",
    ROOT / "lib/features/farm_handling/domain/models/farm_handling_batch_result.dart",
    ROOT / "lib/features/farm_handling/domain/models/farm_handling_draft.dart",
]

errors = []

for path in PRODUCTION_FILES:
    if not path.exists():
        errors.append(f"Arquivo obrigatório ausente: {path.relative_to(ROOT)}")
        continue

    text = path.read_text(encoding="utf-8", errors="ignore")

    for match in re.finditer(
        r"DropdownButtonFormField<[^>]+>\(\s*\n\s*value:",
        text,
        re.S,
    ):
        line = text[:match.start()].count("\n") + 1
        errors.append(
            f"{path.relative_to(ROOT)}:{line}: "
            "DropdownButtonFormField(value:) depreciado; use initialValue:."
        )

    if path.name == "farm_handling_screen.dart":
        if re.search(r"\bString\s+get\s+_selectionLabel\b", text):
            errors.append(
                f"{path.relative_to(ROOT)}: getter privado _selectionLabel sem consumidor."
            )

    for token in ("Ã§", "Ã£", "Ã©", "Ã³", "Ãª", "Ã¡", "Ã­", "Ãº", "Â"):
        if token in text:
            errors.append(
                f"{path.relative_to(ROOT)}: texto corrompido detectado ({token})."
            )
            break

screen = PRODUCTION_FILES[0].read_text(encoding="utf-8", errors="ignore")
initial_value_count = len(
    re.findall(
        r"DropdownButtonFormField<[^>]+>\(\s*\n\s*initialValue:",
        screen,
        re.S,
    )
)
if initial_value_count != 4:
    errors.append(
        "farm_handling_screen.dart deve manter exatamente quatro "
        "DropdownButtonFormField com initialValue: nesta implementação."
    )

if errors:
    print("ATLAS POST-V21 PACKAGE 2 DART HYGIENE: FAIL")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS POST-V21 PACKAGE 2 DART HYGIENE: OK")
