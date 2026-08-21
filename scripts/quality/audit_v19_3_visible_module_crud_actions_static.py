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

# O botão deve fazer parte do cabeçalho sempre renderizado, e não de uma barra
# separada/condicional que possa desaparecer da interface.
check('Cabeçalho recebe createLabel', 'required this.createLabel' in module)
check('Cabeçalho recebe onCreate', 'required this.onCreate' in module)
check('Botão de criação possui chave estável', "ValueKey('atlas_module_create_button')" in module)
check('Botão de gerenciamento possui chave estável', "ValueKey('atlas_module_manage_button')" in module)
check('Botão de criação é FilledButton visível', 'FilledButton.icon(' in module)
check('Botão de gerenciamento é OutlinedButton visível', 'OutlinedButton.icon(' in module)
check('Botão não é removido por if(canWrite)', 'if (canWrite)\n              FilledButton.icon' not in module)
check('Sem permissão botão permanece visível/desabilitado', 'onCreate: _loading || !canWrite' in module)
check('Cabeçalho recebe canWrite', 'canWrite: canWrite' in module)

for label in [
    'Novo evento reprodutivo',
    'Novo evento sanitário',
    'Nova dieta',
    'Novo produto',
    'Novo lançamento',
]:
    check(f'Rótulo operacional presente: {label}', label in module)

for permission in [
    'reproduction.write',
    'health.write',
    'nutrition.write',
    'inventory.write',
    'finance.write',
]:
    check(f'Permissão preservada: {permission}', permission in module)

check('Criação navega para fluxo existente', '_openOperational(create: true)' in module)
check('Gerenciamento navega para fluxo existente', '_openOperational(create: false)' in module)
check('Retorno recarrega backend', 'await _load();' in module)
check('Item abre gerenciamento existente', 'onTap: () => _openOperational(create: false)' in module)

for target in [
    'ReproductionOverviewScreen(',
    'HealthOverviewScreen(',
    'NutritionOverviewScreen(',
    'FarmInventoryListScreen(',
    'FarmFinanceListScreen(',
]:
    check(f'Reutiliza {target[:-1]}', target in module)

for name, text, opener in [
    ('Sanidade', health, 'openNewEvent();'),
    ('Reprodução', repro, 'openNewEvent();'),
    ('Nutrição', nutrition, 'openForm();'),
    ('Financeiro', finance, 'openFinanceForm();'),
    ('Estoque', inventory, 'openItemForm();'),
]:
    check(f'{name} aceita autoOpenCreate', 'autoOpenCreate' in text)
    check(f'{name} dispara criação automática', opener in text)

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(f"[{'OK' if ok else 'FAIL'}] {name}")
print(f"\nV19.3 visible module CRUD actions: {len(checks)-len(failed)}/{len(checks)}")
if failed:
    raise SystemExit(1)
