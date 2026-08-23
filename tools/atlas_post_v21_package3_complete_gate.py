from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

paths = {
    "shell": ROOT / "lib/core/navigation/atlas_home_shell.dart",
    "field": ROOT / "lib/features/field_operations/presentation/screens/farm_field_center_screen.dart",
    "inventory": ROOT / "lib/features/farm_inventory/presentation/screens/inventory_overview_screen.dart",
    "finance": ROOT / "lib/features/farm_finance/presentation/screens/finance_overview_screen.dart",
    "intelligence": ROOT / "lib/features/atlas_intelligence_center/presentation/screens/atlas_intelligence_center_screen.dart",
    "reports": ROOT / "lib/features/reports/presentation/screens/reports_screen.dart",
    "panel": ROOT / "lib/core/widgets/atlas_module_decision_panel.dart",
}

texts = {}
errors = []

for name, path in paths.items():
    if not path.exists():
        errors.append(f"Arquivo ausente: {path.relative_to(ROOT)}")
        continue
    texts[name] = path.read_text(encoding="utf-8", errors="ignore")

def check(name, condition):
    if not condition:
        errors.append(name)

shell = texts.get("shell", "")
field = texts.get("field", "")
inventory = texts.get("inventory", "")
finance = texts.get("finance", "")
intelligence = texts.get("intelligence", "")
reports = texts.get("reports", "")

# Campo/Pastagens/Operações/Equipe.
check("Campo não abre a Central de Campo", "FarmFieldCenterScreen(farm: farm, embedded: true)" in shell)
check("Campo não está vinculado à fazenda ativa", "'Campo'," in shell[shell.find("farmScopedModules"):])
check("Central de Campo ausente", "class FarmFieldCenterScreen" in field)
check("Campo não usa piquetes oficiais existentes", "PaddockStorageService" in field)
check("Campo não integra operações existentes", "AtlasOperationsRepository" in field)
check("Campo não resume equipe vinculada", "activeTeam" in field)
check("Campo não resume atrasos", "overdueOperations" in field)
check("Campo não resume operações abertas", "openOperationsCount" in field)
check(
    "Campo contém colisão getter/método openOperations",
    "int get openOperations =>" not in field,
)
check("Campo não oferece piquetes", "PaddockListScreen" in field)
check("Campo não oferece centro de operações", "AtlasOperationsCenterScreen" in field)
check("Campo não preserva ferramentas offline", "AtlasFieldOperationsScreen" in field)

# Estoque.
check("Estoque não aceita fazenda ativa", "final FarmData? farm;" in inventory)
check("Estoque não aceita embedded", "final bool embedded;" in inventory)
check("Estoque não carrega usando farmId", "farmId: farm.id ?? ''" in inventory)
check("Estoque não usa painel decisório", "AtlasModuleDecisionPanel(" in inventory)
check("Estoque não detecta sem estoque", "outOfStockCount" in inventory)
check("Estoque não detecta vencidos", "expiredCount" in inventory)
check("Estoque não detecta estoque baixo", "lowStockCount" in inventory)
check("Estoque não abre gestão canônica", "'Gerenciar estoque'" in inventory)
check("Shell ainda pula a Central de Estoque", "InventoryOverviewScreen(farm: farm, embedded: true)" in shell)

# Financeiro.
check("Financeiro não aceita fazenda ativa", "final FarmData? farm;" in finance)
check("Financeiro não aceita embedded", "final bool embedded;" in finance)
check("Financeiro não carrega usando farmId", "farmId: farm.id ?? ''" in finance)
check("Financeiro não usa painel decisório", "AtlasModuleDecisionPanel(" in finance)
check("Financeiro não detecta pendências", "pendingRecords" in finance)
check("Financeiro não detecta vencidos", "overdueRecords" in finance)
check("Financeiro não separa a pagar", "pendingExpenses" in finance)
check("Financeiro não separa a receber", "pendingIncome" in finance)
check(
    "Financeiro voltou a alarmar saldo negativo isolado",
    "saldo negativo isolado não significa falha operacional" in finance,
)
check("Shell ainda pula a Central Financeira", "FinanceOverviewScreen(farm: farm, embedded: true)" in shell)

# Inteligência/Relatórios have distinct roles but direct bridge.
check(
    "Inteligência não mantém conexão funcional com Relatórios",
    "void openReports()" in intelligence
    and "onPressed: openReports" in intelligence
    and "ReportsScreen()" in intelligence,
)
check("Inteligência não abre ReportsScreen", "ReportsScreen()" in intelligence)
check("Relatórios perdeu resumo consolidado", "'Resumo consolidado'" in reports)
check("Relatórios perdeu alertas operacionais", "'Alertas da operação'" in reports)
check("Relatórios perdeu plano de ação", "'Salvar plano de ação'" in reports)

# No new parallel persistence in new/changed centers.
for name in ("field", "inventory", "finance", "intelligence"):
    text = texts.get(name, "")
    check(
        f"{name}: SharedPreferences introduzido diretamente na apresentação",
        "SharedPreferences" not in text,
    )

# Prevent getter/method identifier collisions in presentation centers.
for name in ("field", "inventory", "finance", "intelligence"):
    text = texts.get(name, "")
    getters = set(re.findall(r"\b(?:int|double|bool|String|List<[^>]+>|Set<[^>]+>|[A-Za-z_]\w*\?)\s+get\s+([A-Za-z_]\w*)", text))
    methods = set(re.findall(r"\b(?:Future<[^>]+>|void)\s+([A-Za-z_]\w*)\s*\(", text))
    collisions = sorted(getters & methods)
    check(
        f"{name}: colisão entre getter e método: {', '.join(collisions)}",
        not collisions,
    )

# New code hygiene.
for name in ("field", "inventory", "finance", "intelligence"):
    text = texts.get(name, "")
    check(
        f"{name}: DropdownButtonFormField(value:) depreciado",
        not re.search(
            r"DropdownButtonFormField<[^>]+>\(\s*\n\s*value:",
            text,
            re.S,
        ),
    )
    check(
        f"{name}: mojibake",
        not any(
            token in text
            for token in ("Ã§", "Ã£", "Ã©", "Ã³", "Ãª", "Ã¡", "Ã­", "Ãº", "Â")
        ),
    )

if errors:
    print(f"ATLAS POST-V21 PACKAGE 3 COMPLETE: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS POST-V21 PACKAGE 3 COMPLETE: 43/43")
