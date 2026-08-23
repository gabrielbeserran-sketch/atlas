from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

files = {
    "policy": ROOT / "lib/core/navigation/atlas_product_surface_policy.dart",
    "guide": ROOT / "lib/core/widgets/atlas_module_workspace_guide.dart",
    "role": ROOT / "lib/core/widgets/atlas_module_role_card.dart",
    "field": ROOT / "lib/features/field_operations/presentation/screens/farm_field_center_screen.dart",
    "analysis": ROOT / "lib/features/atlas_intelligence_center/presentation/screens/atlas_intelligence_center_screen.dart",
    "reports": ROOT / "lib/features/reports/presentation/screens/reports_screen.dart",
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

policy = texts.get("policy", "")
guide = texts.get("guide", "")
role = texts.get("role", "")
field = texts.get("field", "")
analysis = texts.get("analysis", "")
reports = texts.get("reports", "")

check("fronteira funcional ausente", "moduleResponsibility" in policy)
check("regra de não substituição ausente", "moduleDoesNotReplace" in policy)
check("componente de papel funcional ausente", "class AtlasModuleRoleCard" in role)
check("guia compartilhado ausente", "class AtlasModuleWorkspaceGuide" in guide)

for module in ("Campo", "Análises", "Relatórios"):
    check(
        f"fluxos de {module} ausentes",
        f"'{module}': [" in policy,
    )
    check(
        f"responsabilidade de {module} ausente",
        f"'{module}':" in policy,
    )

check("Campo perdeu painel de decisão", "AtlasModuleDecisionPanel(" in field)
check("Campo perdeu barra de ações", "AtlasOperationalActionBar(" in field)
check("Campo sem guia de trabalho", "moduleLabel: 'Campo'" in field)
check("Campo sem fronteira de execução", "Campo é onde o trabalho acontece" in field)
check("Campo perdeu piquetes", "openPaddocks" in field)
check("Campo perdeu operações", "openOperations" in field)
check("Campo perdeu ferramentas operacionais", "openFieldTools" in field)

check("Análises sem guia de trabalho", "moduleLabel: 'Análises'" in analysis)
check("Análises sem fronteira interpretativa", "Análises transforma dados em decisão" in analysis)
check("Análises perdeu contexto oficial", "loadContext(farmId)" in analysis)
check("Análises perdeu recomendações", "loadRecommendations(farmId)" in analysis)
check("Análises perdeu simulação", "buildSimulator(context, farm.id)" in analysis)
check("Análises perdeu decisões", "buildDecisions(context, farm.id)" in analysis)
check("Análises perdeu navegação para módulos donos", "widget.onNavigateModule!(area.moduleLabel)" in analysis)
check("Análises perdeu ligação com Relatórios", "ReportsScreen()" in analysis and "onPressed: openReports" in analysis)

check("Relatórios sem guia de trabalho", "moduleLabel: 'Relatórios'" in reports)
check("Relatórios sem fronteira documental", "Relatórios consolida e documenta" in reports)
check("Relatórios perdeu filtro por fazenda", "selectedFarmName" in reports)
check("Relatórios perdeu filtro por período", "selectedPeriod" in reports)
check("Relatórios perdeu PDF", "exportPdfReport()" in reports)
check("Relatórios perdeu Excel", "exportExcelReport()" in reports)
check("Relatórios perdeu ações gerenciais", "openSavedActions" in reports)
check("Relatórios perdeu comparações", "periodComparisonData" in reports)

# Boundary invariants: reports must not become a second simulator/AI center,
# field must not become reporting, and analysis must not create operational facts.
check("Relatórios virou simulador", "buildSimulator(" not in reports)
check("Campo virou exportador de relatórios", "exportPdfReport" not in field and "exportExcelReport" not in field)
check("Análises virou formulário operacional", "FloatingActionButton" not in analysis)

for name, text in texts.items():
    check(
        f"{name}: vocabulário de desenvolvimento visível",
        not any(token in text for token in ("Pacote 6D-C", "Marco 6D-C", "Etapa 6D-C")),
    )
    check(
        f"{name}: mojibake",
        not any(token in text for token in ("Ã§", "Ã£", "Ã©", "Ã³", "Â")),
    )

if errors:
    print(f"ATLAS POS-V21 PACKAGE 6D-C: FAIL ({len(errors)} erro(s))")
    for item in errors:
        print("-", item)
    sys.exit(1)

print("ATLAS POS-V21 PACKAGE 6D-C: 42/42")
print("Campo: execução")
print("Análises: interpretação")
print("Relatórios: consolidação/exportação")
