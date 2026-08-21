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

legacy_screens = [
    "HerdListScreen",
    "FarmFinanceListScreen",
    "FarmInventoryListScreen",
    "ReproductionOverviewScreen",
    "HealthOverviewScreen",
    "NutritionOverviewScreen",
]
for screen in legacy_screens:
    check(f"FarmDetail sem rota legada {screen}", screen not in farm)

for module in ["health", "reproduction", "nutrition", "finance", "inventory"]:
    check(
        f"FarmDetail usa módulo canônico {module}",
        f"AtlasLivestockModule.{module}" in farm,
    )

check("FarmDetail Rebanho canônico", "HerdOverviewScreen" in farm)
check("FarmDetail animais via API Enterprise", "AnimalEnterpriseService" in farm and "animalService.listAnimals" in farm)
check("FarmDetail lotes usa farmId explícito", "loadGroups(farm.name, farmId: farm.id ?? '')" in farm)
check("FarmDetail financeiro usa farmId explícito", "loadRecords(farm.name, farmId: farm.id ?? '')" in farm)
check("FarmDetail estoque usa farmId explícito", "loadItems(farm.name, farmId: farm.id ?? '')" in farm)
check("FarmDetail agenda usa farmId explícito", "loadTasks(farm.name, farmId: farm.id ?? '')" in farm)

for module in ["health", "reproduction", "nutrition", "finance", "inventory"]:
    check(
        f"Dashboard fallback canônico {module}",
        f"AtlasLivestockModule.{module}" in dash,
    )

for screen in ["HealthOverviewScreen", "ReproductionOverviewScreen", "NutritionOverviewScreen", "FinanceOverviewScreen", "InventoryOverviewScreen"]:
    check(f"Dashboard sem fallback legado {screen}", screen not in dash)

for module in ["health", "reproduction", "nutrition", "finance", "inventory"]:
    check(
        f"HomeShell módulo oficial {module}",
        f"AtlasLivestockModule.{module}" in shell,
    )

failed = [name for name, ok in checks if not ok]
for name, ok in checks:
    print(f"[{'OK' if ok else 'FAIL'}] {name}")
print(f"\nV19 canonical navigation: {len(checks)-len(failed)}/{len(checks)}")
if failed:
    raise SystemExit(1)
