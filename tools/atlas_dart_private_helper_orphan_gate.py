from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
TARGETS = [
    ROOT / "lib/features/dr_beserra/data/services/dr_beserra_command_gateway.dart",
    ROOT / "lib/features/dr_beserra/domain/services/dr_beserra_daily_routine_service.dart",
    ROOT / "lib/features/dr_beserra/domain/services/dr_beserra_language_service.dart",
    ROOT / "lib/features/dr_beserra/domain/services/dr_beserra_operation_parser.dart",
    ROOT / "lib/features/dr_beserra/data/services/dr_beserra_voice_service.dart",
    ROOT / "lib/features/dr_beserra/data/services/dr_beserra_contextual_intelligence_service.dart",
]

errors = []

for path in TARGETS:
    if not path.exists():
        errors.append(f"arquivo ausente: {path.relative_to(ROOT)}")
        continue

    text = path.read_text(encoding="utf-8", errors="ignore")

    # Private instance methods. We count identifier references, not only calls,
    # because Dart legitimately uses methods as callbacks/tear-offs:
    # sort(_compare), onResult: _onResult, onStatus: _onStatus.
    declarations = re.findall(
        r"(?m)^\s{2}(?:Future<[^>]+>|Future<void>|Future|String|bool|int\??|"
        r"DateTime\??|List<[^>]+>|Map<[^>]+>|void|[A-Z][A-Za-z0-9_<>, ?]+)"
        r"\s+(_[A-Za-z0-9_]+)\s*\(",
        text,
    )

    for name in sorted(set(declarations)):
        occurrences = len(re.findall(rf"\b{re.escape(name)}\b", text))
        if occurrences < 2:
            errors.append(
                f"{path.relative_to(ROOT)}: helper privado órfão {name} "
                f"({occurrences} ocorrência)"
            )

gateway = (
    ROOT
    / "lib/features/dr_beserra/data/services/dr_beserra_command_gateway.dart"
).read_text(encoding="utf-8", errors="ignore")

for legacy in ("_taskDateKey", "_dateKey"):
    if re.search(rf"\b{re.escape(legacy)}\b", gateway):
        errors.append(
            f"dr_beserra_command_gateway.dart: helper legado {legacy} reapareceu"
        )

if errors:
    print(f"ATLAS DART PRIVATE HELPER ORPHAN: FAIL ({len(errors)})")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS DART PRIVATE HELPER ORPHAN: APROVADO")
print("Helpers privados órfãos nos serviços do Dr. Beserra: 0")
print("Regressões _taskDateKey/_dateKey do gateway: BLOQUEADAS")
