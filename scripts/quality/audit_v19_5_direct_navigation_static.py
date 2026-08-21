from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SHELL = ROOT / "lib/core/navigation/atlas_home_shell.dart"
FARM = ROOT / "lib/features/farm/presentation/screens/farm_detail_screen.dart"
DASH = ROOT / "lib/features/dashboard/presentation/screens/dashboard_screen.dart"
ANIMAL = ROOT / "lib/features/animal/presentation/screens/animal_detail_screen.dart"
SUMMARY = ROOT / "lib/features/livestock_operations/presentation/screens/atlas_livestock_module_screen.dart"

checks = []
def check(name, cond): checks.append((name, bool(cond)))

shell = SHELL.read_text(encoding='utf-8')
farm = FARM.read_text(encoding='utf-8')
dash = DASH.read_text(encoding='utf-8')
animal = ANIMAL.read_text(encoding='utf-8')
summary = SUMMARY.read_text(encoding='utf-8')

# Nenhuma porta de navegação principal pode cair na antiga tela-resumo ponte.
for name, text in [('HomeShell', shell), ('FarmDetail', farm), ('Dashboard', dash)]:
    check(f'{name} sem tela-resumo ponte', 'AtlasLivestockModuleScreen' not in text)

# Menu principal: clique deve abrir diretamente a central CRUD farm-scoped.
for label in ['Sanidade', 'Reprodução', 'Nutrição', 'Financeiro', 'Estoque']:
    check(f'Menu direto reconhece {label}', f"'{label}'" in shell)
for target in [
    'HealthOverviewScreen(farm: farm)',
    'ReproductionOverviewScreen(farm: farm)',
    'NutritionOverviewScreen(farm: farm)',
    'FarmFinanceListScreen(farm: farm)',
    'FarmInventoryListScreen(farm: farm)',
]:
    check(f'Menu abre {target}', target in shell)
check('Sidebar desktop usa handler direto', 'onSelected: (index) => _handleRouteSelection(visibleRoutes, index)' in shell)
check('Dashboard via shell preserva destino canônico', '_navigateToLabel' in shell and 'setState(() => selectedIndex = index)' in shell)

# Fazenda: atalhos dos cinco domínios vão direto para a central real.
for target in [
    'HealthOverviewScreen(farm: farm)',
    'ReproductionOverviewScreen(farm: farm)',
    'NutritionOverviewScreen(farm: farm)',
    'FarmFinanceListScreen(farm: farm)',
    'FarmInventoryListScreen(farm: farm)',
]:
    check(f'Fazenda abre {target}', target in farm)

# Dashboard standalone também não empilha a tela-resumo.
for target in [
    'const HealthOverviewScreen()',
    'const ReproductionOverviewScreen()',
    'const NutritionOverviewScreen()',
    'const FinanceOverviewScreen()',
    'const InventoryOverviewScreen()',
]:
    check(f'Dashboard abre {target}', target in dash)

# Central do Animal: os cinco módulos do segundo nível não podem renderizar
# uma seção intermediária "Abrir ..."; o clique navega diretamente.
for section in [
    'AnimalHubSection.healthEnterprise',
    'AnimalHubSection.reproductionEnterprise',
    'AnimalHubSection.weightIntelligence',
    'AnimalHubSection.nutritionEnterprise',
    'AnimalHubSection.executivePanel',
]:
    check(f'Central Animal intercepta {section}', section in animal.split('Future<void> selectSection',1)[1].split('Widget buildSummarySection',1)[0])
for target in [
    'AnimalHealthEnterpriseScreen(',
    'AnimalReproductionEnterpriseScreen(',
    'AnimalWeightIntelligenceScreen(',
    'AnimalNutritionEnterpriseScreen(',
    'AnimalExecutivePanelScreen(',
]:
    check(f'Central Animal abre diretamente {target}', target in animal.split('Future<void> selectSection',1)[1].split('Widget buildSummarySection',1)[0])
check('Central Animal callback usa navegação direta', 'unawaited(selectSection(section))' in animal)

# A antiga tela-resumo pode permanecer como componente técnico/inventário, mas
# não é autoridade de navegação. Seu CRUD continua preservado para compatibilidade.
check('Resumo técnico preserva ações existentes', '_openOperational' in summary and '_ModuleActionBar' in summary)

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(f"[{'OK' if ok else 'FAIL'}] {name}")
print(f"\nV19.5 direct navigation: {len(checks)-len(failed)}/{len(checks)}")
if failed:
    raise SystemExit(1)
