from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

files = {
    "policy": ROOT / "lib/core/navigation/atlas_product_surface_policy.dart",
    "guide": ROOT / "lib/core/widgets/atlas_module_workspace_guide.dart",
    "nutrition": ROOT / "lib/features/nutrition/presentation/screens/nutrition_overview_screen.dart",
    "inventory": ROOT / "lib/features/farm_inventory/presentation/screens/inventory_overview_screen.dart",
    "finance": ROOT / "lib/features/farm_finance/presentation/screens/finance_overview_screen.dart",
}

errors = []
texts = {}
for name, path in files.items():
    if not path.exists():
        errors.append(f"arquivo ausente: {path.relative_to(ROOT)}")
        continue
    texts[name] = path.read_text(encoding="utf-8", errors="ignore")

def check(name, condition):
    if not condition:
        errors.append(name)

policy=texts.get("policy","")
guide=texts.get("guide","")
nutrition=texts.get("nutrition","")
inventory=texts.get("inventory","")
finance=texts.get("finance","")

check("guia operacional compartilhado ausente", "class AtlasModuleWorkspaceGuide" in guide)

for module, text in (
    ("Nutrição", nutrition),
    ("Estoque", inventory),
    ("Financeiro", finance),
):
    check(f"{module}: painel de decisão ausente", "AtlasModuleDecisionPanel(" in text)
    check(f"{module}: barra de ação ausente", "AtlasOperationalActionBar(" in text)
    check(f"{module}: guia de trabalho ausente", f"moduleLabel: '{module}'" in text)
    check(
        f"{module}: política central não utilizada",
        f"moduleWorkflows['{module}']" in text
        and f"specializedCapabilityCountByOwner['{module}']" in text,
    )

check(
    "Nutrição perdeu integração oficial com estoque",
    "inventoryIntegration.deductDailyConsumption" in nutrition
    and "inventoryDeducted" in nutrition,
)
check(
    "Nutrição perdeu alerta de desempenho",
    "belowTargetPlans" in nutrition
    and "plansWithoutObservedPerformance" in nutrition,
)
check(
    "Estoque perdeu alertas críticos",
    "outOfStockCount" in inventory
    and "expiredCount" in inventory
    and "nearExpirationCount" in inventory,
)
check(
    "Financeiro perdeu obrigações futuras",
    "pendingIncome" in finance
    and "pendingExpenses" in finance
    and "overdueRecords" in finance,
)
check(
    "Financeiro voltou a tratar saldo negativo isoladamente",
    "Leia o financeiro dentro do ciclo da pecuária" in finance
    and "saldo negativo isolado" in finance
    and "ciclo produtivo" in finance,
)
check(
    "Financeiro perdeu simulação de decisão",
    "openFinancialSimulation" in finance
    and "Simular decisão" in finance,
)

for name,text in texts.items():
    check(
        f"{name}: vocabulário de desenvolvimento visível",
        not any(token in text for token in ("Pacote 6D-B", "Marco 6D-B", "Etapa 6D-B")),
    )
    check(
        f"{name}: mojibake",
        not any(token in text for token in ("Ã§","Ã£","Ã©","Ã³","Â")),
    )

if errors:
    print(f"ATLAS POS-V21 PACKAGE 6D-B: FAIL ({len(errors)} erro(s))")
    for item in errors:
        print("-", item)
    sys.exit(1)

print("ATLAS POS-V21 PACKAGE 6D-B: 28/28")
