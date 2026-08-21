from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
shell = (ROOT / "lib/core/navigation/atlas_home_shell.dart").read_text(encoding="utf-8")
animal = (ROOT / "lib/features/animal/presentation/screens/animal_detail_screen.dart").read_text(encoding="utf-8")

checks = {
    "operational_routes_stay_in_shell": "_openDirectOperationalRoute" not in shell,
    "health_workspace": "HealthOverviewScreen(farm: farm)" in shell,
    "reproduction_workspace": "ReproductionOverviewScreen(farm: farm)" in shell,
    "nutrition_workspace": "NutritionOverviewScreen(farm: farm)" in shell,
    "finance_workspace": "FarmFinanceListScreen(farm: farm)" in shell,
    "inventory_workspace": "FarmInventoryListScreen(farm: farm)" in shell,
    "advanced_group": "'Mais recursos'" in shell,
    "admin_group": "'Administração'" in shell,
    "animal_quick_actions": "'Ações rápidas'" in animal,
    "animal_weight_action": "'Nova pesagem'" in animal,
    "animal_health_action": "AnimalHubSection.healthEnterprise" in animal,
    "animal_reproduction_action": "AnimalHubSection.reproductionEnterprise" in animal,
    "timeline_ui_is_history": "label: 'Timeline'" not in animal,
    "health_plus_removed": "label: 'Sanidade+'" not in animal,
    "reproduction_plus_removed": "label: 'Reprodução+'" not in animal,
    "weight_plus_removed": "label: 'Pesagens+'" not in animal,
}

forbidden = re.compile(r"\b(Pacote|Fase|Sprint|Marco)\s+\d+\b", re.I)
visible_hits = []
for path in (ROOT / "lib").rglob("*.dart"):
    if "/presentation/" not in str(path).replace("\\", "/"):
        continue
    text = path.read_text(encoding="utf-8", errors="ignore")
    if forbidden.search(text):
        visible_hits.append(str(path.relative_to(ROOT)))
checks["no_development_terms_in_presentation"] = not visible_hits

failed = [name for name, ok in checks.items() if not ok]
print(f"ATLAS V20 UX FOUNDATION: {len(checks)-len(failed)}/{len(checks)}")
if visible_hits:
    print("Development terms still visible in:", *visible_hits, sep="\n- ")
if failed:
    print("FAIL:", ", ".join(failed))
    sys.exit(1)
print("ATLAS V20 UX FOUNDATION: OK")
