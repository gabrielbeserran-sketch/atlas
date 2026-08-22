from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

def read(path):
    return (ROOT / path).read_text(encoding="utf-8", errors="ignore")

s = {
    "login": read("lib/features/authentication/presentation/screens/login_screen.dart"),
    "dashboard": read("lib/features/dashboard/presentation/screens/dashboard_screen.dart"),
    "farm": read("lib/features/farm/presentation/screens/farm_list_screen.dart"),
    "shell": read("lib/core/navigation/atlas_home_shell.dart"),
    "herd": read("lib/features/herd/presentation/screens/herd_overview_screen.dart"),
    "animal": read("lib/features/animal/presentation/screens/animal_detail_screen.dart"),
    "genealogy": read("lib/features/animal_genealogy/data/services/animal_genealogy_enterprise_service.dart"),
    "weight": read("lib/features/animal_weight/presentation/screens/animal_weight_form_screen.dart"),
    "health": read("lib/features/animal_health/presentation/screens/animal_health_form_screen.dart"),
    "reproduction": read("lib/features/animal_reproduction/presentation/screens/animal_reproduction_form_screen.dart"),
    "agenda": read("lib/features/farm_agenda/presentation/screens/farm_agenda_list_screen.dart"),
    "inventory": read("lib/features/farm_inventory/presentation/screens/farm_inventory_list_screen.dart"),
    "nutrition": read("lib/features/nutrition/presentation/screens/nutrition_overview_screen.dart"),
    "finance": read("lib/features/farm_finance/presentation/screens/farm_finance_list_screen.dart"),
}

checks = [
    ("01 login", all(x in s["login"] for x in ["'E-mail'", "'Senha'", "'Entrar'", "AtlasEnterpriseApiClient.instance.login"])),
    ("02 dashboard", all(x in s["dashboard"] for x in ["farmId", "FarmStorageService", "RefreshIndicator("])),
    ("03 fazendas", "FarmDetailScreen(" in s["farm"] and "'Nova fazenda'" in s["farm"] and "body = const FarmListScreen(embedded: true);" in s["shell"]),
    ("04 troca fazenda", "ValueKey('${selected.label}:${farmId ?? 'none'}')" in s["shell"]),
    ("05 gate fazenda/rebanho", "selected.label == 'Rebanho'" in s["shell"] and "farmScopedModules" in s["shell"]),
    ("06 rebanho", all(x in s["herd"] for x in ["'Novo animal'", "'Novo lote'", "AnimalDetailScreen("])),
    ("07 central animal", all(x in s["animal"] for x in ["'Nova pesagem'", "'Novo evento sanitário'", "'Novo evento reprodutivo'", "'Movimentações'", "'Desempenho'", "'Sanidade'", "'Reprodução'", "'Genealogia'", "'Arquivos'"]) and "'Mais recursos'" not in s["animal"][s["animal"].find("class AnimalHubNavigation"):s["animal"].find("class NavigationModuleRow")]),
    ("08 genealogia", "'/livestock/animals/$animalId/genealogy'" in s["genealogy"] and "'/animals/$animalId/genealogy'" not in s["genealogy"]),
    ("09 pesagem", all(x in s["weight"] for x in ["AtlasFormActions(", "'Salvar pesagem'", "saveWeight"])),
    ("10 sanidade", "AtlasFormActions(" in s["health"] and "Navigator.pop" in s["health"]),
    ("11 reprodução", "AtlasFormActions(" in s["reproduction"] and "Navigator.pop" in s["reproduction"]),
    ("12 agenda", all(x in s["agenda"] for x in ["'Novo compromisso'", "'Lista'", "'Semana'", "'Mês'", "openTaskForm"])),
    ("13 estoque/nutrição", "'Novo produto'" in s["inventory"] and "movement" in s["inventory"].lower() and "'Nova dieta'" in s["nutrition"] and "inventory" in s["nutrition"].lower()),
    ("14 financeiro", "'Novo lançamento'" in s["finance"] and "widget.farm.id" in s["finance"] and "loadRecords" in s["finance"]),
]

failed = [name for name, ok in checks if not ok]
print(f"ATLAS V21.6 CRITICAL FLOWS: {len(checks)-len(failed)}/{len(checks)}")
for name in failed:
    print("FAIL:", name)
sys.exit(1 if failed else 0)
