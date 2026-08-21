from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]

def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding='utf-8')

shell = read('lib/core/navigation/atlas_home_shell.dart')
score = read('lib/features/animal_executive_panel/presentation/screens/animal_executive_panel_screen.dart')
feedback = read('lib/core/widgets/atlas_operational_feedback.dart')
health = read('lib/features/animal_health/presentation/screens/health_overview_screen.dart')
repro = read('lib/features/animal_reproduction/presentation/screens/reproduction_overview_screen.dart')
nutrition = read('lib/features/nutrition/presentation/screens/nutrition_overview_screen.dart')
inventory = read('lib/features/farm_inventory/presentation/screens/farm_inventory_list_screen.dart')
finance = read('lib/features/farm_finance/presentation/screens/farm_finance_list_screen.dart')
agenda = read('lib/features/farm_agenda/presentation/screens/farm_agenda_list_screen.dart')

checks = {
    'score_value_separate_from_level': "child: Text(\n                                        level," in score and "const SizedBox(height: 10)" in score,
    'score_ring_96px': 'width: 96' in score and 'height: 96' in score,
    'score_level_badge': "color: const Color(0xFFEAF3E2)" in score,
    'score_formula_untouched': 'value: score / 100' in score,
    'shared_retry_state': 'class AtlasLoadErrorState' in feedback and "label: const Text('Tentar novamente')" in feedback,
    'health_embedded': 'final bool embedded;' in health and 'appBar: widget.embedded ? null : AppBar(' in health,
    'reproduction_embedded': 'final bool embedded;' in repro and 'appBar: widget.embedded ? null : AppBar(' in repro,
    'nutrition_embedded': 'final bool embedded;' in nutrition and 'appBar: widget.embedded ? null : AppBar(' in nutrition,
    'inventory_embedded': 'final bool embedded;' in inventory and 'appBar: widget.embedded ? null : AppBar(' in inventory,
    'finance_embedded': 'final bool embedded;' in finance and 'appBar: widget.embedded ? null : AppBar(' in finance,
    'agenda_embedded': 'final bool embedded;' in agenda and 'appBar: widget.embedded ? null : AppBar(' in agenda,
    'shell_health_embedded': 'HealthOverviewScreen(farm: farm, embedded: true)' in shell,
    'shell_reproduction_embedded': 'ReproductionOverviewScreen(farm: farm, embedded: true)' in shell,
    'shell_nutrition_embedded': 'NutritionOverviewScreen(farm: farm, embedded: true)' in shell,
    'shell_inventory_embedded': 'FarmInventoryListScreen(farm: farm, embedded: true)' in shell,
    'shell_finance_embedded': 'FarmFinanceListScreen(farm: farm, embedded: true)' in shell,
    'shell_agenda_embedded': 'FarmAgendaListScreen(farm: farm, embedded: true)' in shell,
    'health_retry': 'AtlasLoadErrorState(' in health and 'onRetry: loadData' in health,
    'reproduction_retry': 'AtlasLoadErrorState(' in repro and 'onRetry: loadData' in repro,
    'nutrition_retry': 'AtlasLoadErrorState(' in nutrition and 'onRetry: loadData' in nutrition,
    'inventory_retry': 'AtlasLoadErrorState(' in inventory and 'onRetry: loadItems' in inventory,
    'finance_retry': 'AtlasLoadErrorState(' in finance and 'onRetry: loadRecords' in finance,
    'agenda_retry': 'AtlasLoadErrorState(' in agenda and 'onRetry: loadTasks' in agenda,
}
failed=[name for name,ok in checks.items() if not ok]
for name,ok in checks.items(): print(f"[{'OK' if ok else 'FAIL'}] {name}")
print(f"\nATLAS V20.2 OPERATIONAL CONSISTENCY: {len(checks)-len(failed)}/{len(checks)}")
if failed:
    sys.exit(1)
print('ATLAS V20.2 OPERATIONAL CONSISTENCY: OK')
