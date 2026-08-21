from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MODULE = ROOT / 'lib/features/livestock_operations/presentation/screens/atlas_livestock_module_screen.dart'
HEALTH = ROOT / 'lib/features/animal_health/presentation/screens/health_overview_screen.dart'
REPRO = ROOT / 'lib/features/animal_reproduction/presentation/screens/reproduction_overview_screen.dart'
NUTRITION = ROOT / 'lib/features/nutrition/presentation/screens/nutrition_overview_screen.dart'
FINANCE = ROOT / 'lib/features/farm_finance/presentation/screens/farm_finance_list_screen.dart'
INVENTORY = ROOT / 'lib/features/farm_inventory/presentation/screens/farm_inventory_list_screen.dart'

checks: list[tuple[str, bool]] = []

def check(name: str, condition: bool) -> None:
    checks.append((name, condition))

module = MODULE.read_text(encoding='utf-8')
health = HEALTH.read_text(encoding='utf-8')
repro = REPRO.read_text(encoding='utf-8')
nutrition = NUTRITION.read_text(encoding='utf-8')
finance = FINANCE.read_text(encoding='utf-8')
inventory = INVENTORY.read_text(encoding='utf-8')

for label in [
    'Novo evento reprodutivo',
    'Novo evento sanitário',
    'Nova dieta',
    'Novo produto',
    'Novo lançamento',
]:
    check(f'Ação de criação exposta: {label}', label in module)

for permission in [
    'reproduction.write',
    'health.write',
    'nutrition.write',
    'inventory.write',
    'finance.write',
]:
    check(f'Criação protegida por {permission}', permission in module)

check('Tela canônica possui barra de ações', '_ActionBar(' in module)
check('Novo registro usa fluxo operacional existente', '_openOperational(create: true)' in module)
check('Gerenciamento usa fluxo operacional existente', '_openOperational(create: false)' in module)
check('Itens abrem gerenciamento', 'onTap: () => _openOperational(create: false)' in module)
check('Após CRUD snapshot oficial recarrega', 'await _load();' in module)

expected_targets = [
    'ReproductionOverviewScreen(',
    'HealthOverviewScreen(',
    'NutritionOverviewScreen(',
    'FarmInventoryListScreen(',
    'FarmFinanceListScreen(',
]
for target in expected_targets:
    check(f'Reutiliza fluxo existente {target[:-1]}', target in module)

for name, text, opener in [
    ('Sanidade', health, 'openNewEvent();'),
    ('Reprodução', repro, 'openNewEvent();'),
    ('Nutrição', nutrition, 'openForm();'),
    ('Financeiro', finance, 'openFinanceForm();'),
    ('Estoque', inventory, 'openItemForm();'),
]:
    check(f'{name} aceita autoOpenCreate', 'autoOpenCreate' in text)
    check(f'{name} aciona criação automática', opener in text)

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(f"[{'OK' if ok else 'FAIL'}] {name}")
print(f"\nV19.2 module CRUD actions: {len(checks)-len(failed)}/{len(checks)}")
if failed:
    raise SystemExit(1)
