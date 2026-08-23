from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

source_path = (
    ROOT
    / "lib/features/animal/presentation/screens/animal_detail_screen.dart"
)
test_path = (
    ROOT
    / "test/features/animal/"
    "animal_central_timeline_production_resilience_test.dart"
)

source = source_path.read_text(encoding="utf-8", errors="ignore")
test = test_path.read_text(encoding="utf-8", errors="ignore")

checks = {
    "label técnico estável":
        "static const String _enterpriseTimelineLoadLabel =" in source
        and "'Timeline Enterprise';" in source,
    "serviço Enterprise oficial":
        "enterpriseTimelineService.loadTimeline(animal.id)" in source,
    "callsite usa label técnico compartilhado":
        "label: _enterpriseTimelineLoadLabel" in source,
    "sem timeout local de 6 segundos":
        "Duration(seconds: 6)" not in source,
    "sem timeout local de 8 segundos":
        "Duration(seconds: 8)" not in source,
    "sem wrapper loader.timeout":
        "return await loader().timeout(" not in source,
    "sem timeout direto na Timeline":
        "enterpriseTimelineService.loadTimeline(animal.id).timeout("
        not in source,
    "cliente oficial aguardado diretamente":
        "return await loader();" in source,
    "fallback declarado":
        "required List<T> fallback" in source,
    "fallback imutável preservado":
        "List<T>.unmodifiable(fallback)" in source,
    "teste verifica serviço oficial":
        "enterpriseTimelineService.loadTimeline(animal.id)" in test,
    "teste verifica label técnico":
        "label: _enterpriseTimelineLoadLabel" in test,
    "teste verifica ausência de timeout":
        "enterpriseTimelineService.loadTimeline(animal.id).timeout(" in test,
    "teste declara independência de log/interface":
        "contrato da Timeline não depende de texto de log ou interface"
        in test,
    "teste não exige texto específico do debugPrint":
        "ATLAS Animal Central [$_enterpriseTimelineLoadLabel]" not in test,
}

failed = [name for name, ok in checks.items() if not ok]

if failed:
    print(
        f"ATLAS POS-V21 PACKAGE 6C TIMELINE CONTRACT: "
        f"FAIL ({len(failed)} erro(s))"
    )
    for item in failed:
        print("-", item)
    sys.exit(1)

print(
    f"ATLAS POS-V21 PACKAGE 6C TIMELINE CONTRACT: "
    f"{len(checks)}/{len(checks)}"
)
