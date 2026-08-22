from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
checks = []

def check(name, condition):
    checks.append((name, bool(condition)))

shell = (ROOT/'lib/core/navigation/atlas_home_shell.dart').read_text(encoding='utf-8')
animal = (ROOT/'lib/features/animal/presentation/screens/animal_detail_screen.dart').read_text(encoding='utf-8')

for label, target in {
    'Sanidade':'HealthOverviewScreen(farm: farm, embedded: true)',
    'Reprodução':'ReproductionOverviewScreen(farm: farm, embedded: true)',
    'Nutrição':'NutritionOverviewScreen(farm: farm, embedded: true)',
    'Financeiro':'FarmFinanceListScreen(farm: farm, embedded: true)',
    'Estoque':'FarmInventoryListScreen(farm: farm, embedded: true)',
    'Agenda':'FarmAgendaListScreen(farm: farm, embedded: true)',
}.items():
    check(f'{label} abre direto no shell', target in shell)

for path, action in {
    'animal_health/presentation/screens/health_overview_screen.dart':'Novo evento sanitário',
    'animal_reproduction/presentation/screens/reproduction_overview_screen.dart':'Novo evento reprodutivo',
    'nutrition/presentation/screens/nutrition_overview_screen.dart':'Nova dieta',
    'farm_finance/presentation/screens/farm_finance_list_screen.dart':'Novo lançamento',
    'farm_inventory/presentation/screens/farm_inventory_list_screen.dart':'Novo produto',
    'farm_agenda/presentation/screens/farm_agenda_list_screen.dart':'Novo compromisso',
}.items():
    text=(ROOT/'lib/features'/path).read_text(encoding='utf-8')
    check(f'ação principal {action}', action in text and ('FloatingActionButton.extended' in text or 'AtlasOperationalActionBar(' in text))

check('animal cria sanidade em um fluxo', 'openNewHealthEvent' in animal and 'autoOpenCreate: true' in animal)
check('animal cria reprodução em um fluxo', 'openNewReproductionEvent' in animal)
check('rotina do animal visível', "'Central do animal'" in animal and "'Desempenho'" in animal and "'Arquivos'" in animal)
check('termos de migração ocultados', "'Mais recursos'" not in animal[animal.find('class AnimalHubNavigation'):animal.find('class NavigationModuleRow')])

failed=[name for name, ok in checks if not ok]
print(f'ATLAS V20.6 FLOW GATE: {len(checks)-len(failed)}/{len(checks)}')
for name in failed: print('FAIL:', name)
raise SystemExit(1 if failed else 0)
