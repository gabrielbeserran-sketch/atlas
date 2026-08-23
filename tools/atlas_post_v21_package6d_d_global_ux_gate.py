from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

shell_path = ROOT / "lib/core/navigation/atlas_home_shell.dart"
route_path = ROOT / "lib/core/navigation/atlas_route_definition.dart"
policy_path = ROOT / "lib/core/navigation/atlas_product_surface_policy.dart"
guide_path = ROOT / "lib/core/widgets/atlas_module_workspace_guide.dart"
reports_path = ROOT / "lib/features/reports/presentation/screens/reports_screen.dart"

required_paths = (
    shell_path,
    route_path,
    policy_path,
    guide_path,
    reports_path,
)

errors: list[str] = []
for path in required_paths:
    if not path.exists():
        errors.append(f"arquivo obrigatório ausente: {path.relative_to(ROOT)}")

shell = shell_path.read_text(encoding="utf-8", errors="ignore")
routes = route_path.read_text(encoding="utf-8", errors="ignore")
policy = policy_path.read_text(encoding="utf-8", errors="ignore")
guide = guide_path.read_text(encoding="utf-8", errors="ignore")
reports = reports_path.read_text(encoding="utf-8", errors="ignore")

def check(name: str, condition: bool) -> None:
    if not condition:
        errors.append(name)

# ------------------------------------------------------------------
# 1. Main navigation remains small, grouped and understandable.
# ------------------------------------------------------------------
expected_internal_labels = (
    "Dashboard",
    "Fazendas",
    "Rebanho",
    "Realizar manejo",
    "Sanidade",
    "Reprodução",
    "Nutrição",
    "Financeiro",
    "Estoque",
    "Agenda",
    "Dr. Beserra",
    "Offline",
    "Campo",
    "Inteligência",
    "Relatórios",
    "Consultoria",
)

for label in expected_internal_labels:
    check(
        f"rota principal ausente: {label}",
        f"label: '{label}'" in shell,
    )

for visible in ("Início", "Sem internet", "Análises"):
    check(
        f"nome simples do menu ausente: {visible}",
        f"menuLabel: '{visible}'" in shell,
    )

for group in ("Hoje", "Animais", "Fazenda", "Gestão", "Apoio"):
    check(
        f"grupo de navegação ausente: {group}",
        f"=> '{group}'" in routes,
    )

check(
    "título de grupo do menu voltou a ser caixa alta pequena",
    "group.label.toUpperCase()" not in shell
    and "fontSize: 12" in shell,
)
check(
    "menu principal voltou a expor Mais recursos",
    "Mais recursos" not in shell,
)

# ------------------------------------------------------------------
# 2. Main modules stay inside AtlasHomeShell: no push to another copy.
# ------------------------------------------------------------------
main_screen_classes = (
    "HerdOverviewScreen",
    "HealthOverviewScreen",
    "ReproductionOverviewScreen",
    "NutritionOverviewScreen",
    "FinanceOverviewScreen",
    "InventoryOverviewScreen",
    "FarmAgendaListScreen",
    "DrBeserraScreen",
    "FarmHandlingScreen",
    "FarmFieldCenterScreen",
    "AtlasIntelligenceCenterScreen",
    "ReportsScreen",
    "AtlasClientConsultancyCenterScreen",
)

for path in (ROOT / "lib").rglob("*.dart"):
    text = path.read_text(encoding="utf-8", errors="ignore")
    for class_name in main_screen_classes:
        for match in re.finditer(re.escape(class_name) + r"\s*\(", text):
            before = text[max(0, match.start() - 900):match.start()]
            if "Navigator.push" in before and "MaterialPageRoute" in before:
                errors.append(
                    f"módulo principal empilhado por Navigator.push: "
                    f"{path.relative_to(ROOT)} -> {class_name}"
                )

for label in (
    "Rebanho",
    "Realizar manejo",
    "Agenda",
    "Sanidade",
    "Reprodução",
    "Nutrição",
    "Financeiro",
    "Estoque",
    "Campo",
    "Consultoria",
    "Inteligência",
    "Relatórios",
):
    check(
        f"AtlasHomeShell não controla diretamente {label}",
        f"selected.label == '{label}'" in shell,
    )

check(
    "Campo ainda usa tela legada como builder do menu",
    "AtlasFieldOperationsScreen" not in shell,
)
check(
    "Campo não abre a Central oficial",
    "FarmFieldCenterScreen(farm: farm, embedded: true)" in shell,
)

# ------------------------------------------------------------------
# 3. Reports cannot create a second page header inside the shell.
# ------------------------------------------------------------------
check(
    "Relatórios não possui modo embedded",
    "this.embedded = false" in reports
    and "final bool embedded;" in reports,
)
check(
    "Relatórios não remove AppBar quando embedded",
    "appBar: widget.embedded" in reports
    and "? null" in reports,
)
check(
    "Relatórios perde ações quando embedded",
    "Widget buildEmbeddedActions()" in reports
    and "if (widget.embedded)" in reports,
)
check(
    "Shell não abre Relatórios embedded",
    "ReportsScreen(embedded: true)" in shell,
)

# ------------------------------------------------------------------
# 4. Farm-required empty states must lead to an action.
# ------------------------------------------------------------------
check(
    "estado sem fazenda continua passivo",
    "final VoidCallback onSelectFarm;" in shell
    and "label: const Text('Escolher fazenda')" in shell,
)
check(
    "estado sem fazenda não chama seletor oficial",
    "_AtlasSelectFarmMessage(onSelectFarm: () => _selectFarm(context))"
    in shell,
)

# Tests must validate the current actionable empty-state contract, not the
# obsolete passive constructor removed by 6D-D.
for test_path in (ROOT / "test").rglob("*.dart"):
    test_text = test_path.read_text(encoding="utf-8", errors="ignore")
    check(
        f"teste ainda exige estado passivo sem fazenda: {test_path.relative_to(ROOT)}",
        "const _AtlasSelectFarmMessage()" not in test_text,
    )

# ------------------------------------------------------------------
# 5. Language visible in production screens must stay simple.
# ------------------------------------------------------------------
production_files = [
    "lib/core/navigation/atlas_home_shell.dart",
    "lib/features/dashboard/presentation/screens/dashboard_screen.dart",
    "lib/features/dr_beserra/presentation/screens/dr_beserra_screen.dart",
    "lib/features/farm/presentation/screens/farm_list_screen.dart",
    "lib/features/herd/presentation/screens/herd_overview_screen.dart",
    "lib/features/farm_handling/presentation/screens/farm_handling_screen.dart",
    "lib/features/farm_agenda/presentation/screens/farm_agenda_list_screen.dart",
    "lib/features/animal_health/presentation/screens/health_overview_screen.dart",
    "lib/features/animal_reproduction/presentation/screens/reproduction_overview_screen.dart",
    "lib/features/nutrition/presentation/screens/nutrition_overview_screen.dart",
    "lib/features/farm_finance/presentation/screens/finance_overview_screen.dart",
    "lib/features/farm_inventory/presentation/screens/inventory_overview_screen.dart",
    "lib/core/offline/presentation/atlas_offline_center_screen.dart",
    "lib/features/field_operations/presentation/screens/farm_field_center_screen.dart",
    "lib/features/atlas_intelligence_center/presentation/screens/atlas_intelligence_center_screen.dart",
    "lib/features/reports/presentation/screens/reports_screen.dart",
    "lib/features/consultancy_client/presentation/screens/atlas_client_consultancy_center_screen.dart",
]

visible_string_re = re.compile(r"""(['"])(.{2,100}?)\1""")
for rel in production_files:
    path = ROOT / rel
    check(f"tela de produção ausente: {rel}", path.exists())
    if not path.exists():
        continue
    text = path.read_text(encoding="utf-8", errors="ignore")
    for _, value in visible_string_re.findall(text):
        if re.search(r"\b(?:Pacote|Marco|Sprint|Etapa)\s*\d+", value, re.I):
            errors.append(
                f"vocabulário de desenvolvimento visível: {rel}: {value}"
            )
    check(
        f"Mais recursos reapareceu em {rel}",
        "Mais recursos" not in text,
    )
    if "IconButton(" in text:
        for match in re.finditer(r"IconButton\s*\(", text):
            chunk = text[match.start():match.start() + 650]
            if "tooltip:" not in chunk:
                line = text.count("\n", 0, match.start()) + 1
                errors.append(
                    f"IconButton sem tooltip: {rel}:{line}"
                )

check(
    "guia dos módulos ainda expõe arquitetura técnica",
    "recurso(s) especializado(s)" not in guide
    and "família(s)" not in guide
    and "As ferramentas específicas desta área" in guide,
)

# ------------------------------------------------------------------
# 6. Mojibake is forbidden in production UI. The normalizer itself is allowed
#    to contain broken examples because that is exactly what it repairs.
# ------------------------------------------------------------------
mojibake_tokens = ("Ã§", "Ã£", "Ã©", "Ã³", "Ãª", "Ã¡", "Ã­", "Ãº", "Â")
for path in (ROOT / "lib").rglob("*.dart"):
    if path.name == "atlas_text_normalizer.dart":
        continue
    text = path.read_text(encoding="utf-8", errors="ignore")
    if any(token in text for token in mojibake_tokens):
        errors.append(f"mojibake fora do normalizador: {path.relative_to(ROOT)}")

# ------------------------------------------------------------------
# 7. Product surface policy must keep animal/farm responsibilities separate.
# ------------------------------------------------------------------
for forbidden in ("Agenda", "Pendências", "Financeiro", "Estoque"):
    animal_match = re.search(
        r"animalCenterSections\s*=\s*\{(.*?)\};",
        policy,
        re.S,
    )
    animal_block = animal_match.group(1) if animal_match else ""
    check(
        f"Central do Animal voltou a receber {forbidden}",
        f"'{forbidden}'" not in animal_block,
    )

if errors:
    print(f"ATLAS POS-V21 PACKAGE 6D-D UX: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS POS-V21 PACKAGE 6D-D UX: APROVADO")
print("Rotas principais: 16")
print("Pushes entre módulos principais: 0")
print("IconButtons sem tooltip nas telas principais: 0")
print("Mojibake de produção: 0")
print("Telas intermediárias de Relatórios: 0")
