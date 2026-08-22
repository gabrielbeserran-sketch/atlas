from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
read = lambda rel: (ROOT / rel).read_text(encoding='utf-8')

herd = read('lib/features/herd/presentation/screens/herd_overview_screen.dart')
health = read('lib/features/animal_health/presentation/screens/health_overview_screen.dart')
repro = read('lib/features/animal_reproduction/presentation/screens/reproduction_overview_screen.dart')
nutrition = read('lib/features/nutrition/presentation/screens/nutrition_overview_screen.dart')
inventory = read('lib/features/farm_inventory/presentation/screens/farm_inventory_list_screen.dart')
finance = read('lib/features/farm_finance/presentation/screens/farm_finance_list_screen.dart')
agenda = read('lib/features/farm_agenda/presentation/screens/farm_agenda_list_screen.dart')
animal = read('lib/features/animal/presentation/screens/animal_detail_screen.dart')
weight = read('lib/features/animal_weight/presentation/screens/animal_weight_list_screen.dart')

checks = {
    'shared_empty_state_herd': 'AtlasEmptyState(' in herd,
    'herd_empty_create_animal': "actionLabel: hasAnimals ? 'Limpar filtros' : 'Novo animal'" in herd,
    'herd_empty_create_lot': "actionLabel: 'Novo lote'" in herd,
    'health_clear_search': "actionLabel: 'Limpar busca'" in health and 'searchController.clear()' in health,
    'reproduction_clear_search': "actionLabel: 'Limpar busca'" in repro and 'searchController.clear()' in repro,
    'nutrition_empty_action': "? 'Limpar filtros'\n                          : 'Nova dieta'" in nutrition,
    'inventory_empty_action': "actionLabel: hasFilter ? 'Limpar filtros' : 'Novo produto'" in inventory,
    'finance_empty_action': "actionLabel: hasFilter ? 'Limpar filtro' : 'Novo lançamento'" in finance,
    'agenda_empty_action': "actionLabel: hasFilter ? 'Limpar filtros' : 'Novo compromisso'" in agenda,
    'animal_primary_access_group': "'Acesso rápido'" in animal,
    'animal_secondary_information_group': "'Mais informações'" in animal,
    'animal_primary_health': "label: 'Sanidade'" in animal,
    'animal_primary_reproduction': "label: 'Reprodução'" in animal,
    'animal_primary_weights': "label: 'Pesagens'" in animal,
    'new_weight_is_direct': 'Future<void> openNewWeight() async' in animal and 'onPressed: openNewWeight' in animal,
    'weight_list_auto_create': 'this.autoOpenCreate = false' in weight and 'await openWeightForm();' in weight,
}

failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(f"[{'OK' if ok else 'FAIL'}] {name}")
print(f"\nATLAS V20.3 OPERATIONAL DISCOVERY: {len(checks)-len(failed)}/{len(checks)}")
if failed:
    print('FAIL:', ', '.join(failed))
    sys.exit(1)
print('ATLAS V20.3 OPERATIONAL DISCOVERY: OK')
