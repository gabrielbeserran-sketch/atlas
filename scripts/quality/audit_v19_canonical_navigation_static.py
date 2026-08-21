from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FARM_DETAIL = ROOT / "lib/features/farm/presentation/screens/farm_detail_screen.dart"
DASHBOARD = ROOT / "lib/features/dashboard/presentation/screens/dashboard_screen.dart"
HOME_SHELL = ROOT / "lib/core/navigation/atlas_home_shell.dart"

checks = []

def check(name: str, condition: bool) -> None:
    checks.append((name, condition))

farm = FARM_DETAIL.read_text(encoding="utf-8")
dash = DASHBOARD.read_text(encoding="utf-8")
shell = HOME_SHELL.read_text(encoding="utf-8")

# V19.5: a navegação operacional canônica é a central CRUD real, sem tela-resumo ponte.
for screen in [
    "HealthOverviewScreen(farm: farm)",
    "ReproductionOverviewScreen(farm: farm)",
    "NutritionOverviewScreen(farm: farm)",
    "FarmFinanceListScreen(farm: farm)",
    "FarmInventoryListScreen(farm: farm)",
]:
    check(f"FarmDetail abre central direta {screen}", screen in farm)

check("FarmDetail não usa AtlasLivestockModuleScreen", "AtlasLivestockModuleScreen" not in farm)
check("FarmDetail Rebanho canônico", "HerdOverviewScreen" in farm)
check("FarmDetail animais via API Enterprise", "AnimalEnterpriseService" in farm and "animalService.listAnimals" in farm)
check("FarmDetail lotes usa farmId explícito", "loadGroups(farm.name, farmId: farm.id ?? '')" in farm)
check("FarmDetail financeiro usa farmId explícito", "loadRecords(farm.name, farmId: farm.id ?? '')" in farm)
check("FarmDetail estoque usa farmId explícito", "loadItems(farm.name, farmId: farm.id ?? '')" in farm)
check("FarmDetail agenda usa farmId explícito", "loadTasks(farm.name, farmId: farm.id ?? '')" in farm)

for screen in [
    "const HealthOverviewScreen()",
    "const ReproductionOverviewScreen()",
    "const NutritionOverviewScreen()",
    "const FinanceOverviewScreen()",
    "const InventoryOverviewScreen()",
]:
    check(f"Dashboard fallback direto {screen}", screen in dash)
check("Dashboard não usa AtlasLivestockModuleScreen", "AtlasLivestockModuleScreen" not in dash)

for label in ["Sanidade", "Reprodução", "Nutrição", "Financeiro", "Estoque"]:
    check(f"HomeShell rota direta inclui {label}", f"'{label}'" in shell)
for screen in [
    "HealthOverviewScreen(farm: farm)",
    "ReproductionOverviewScreen(farm: farm)",
    "NutritionOverviewScreen(farm: farm)",
    "FarmFinanceListScreen(farm: farm)",
    "FarmInventoryListScreen(farm: farm)",
]:
    check(f"HomeShell abre central direta {screen}", screen in shell)
check("HomeShell mantém módulos operacionais no workspace", "_handleRouteSelection" in shell and "setState(() => selectedIndex = index)" in shell)
check("HomeShell não usa AtlasLivestockModuleScreen", "AtlasLivestockModuleScreen" not in shell)

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(f"[{'OK' if ok else 'FAIL'}] {name}")
print(f"\nV19 canonical navigation: {len(checks)-len(failed)}/{len(checks)}")
if failed:
    raise SystemExit(1)
