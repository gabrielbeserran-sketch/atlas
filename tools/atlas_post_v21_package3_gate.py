from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

files = {
    "panel": ROOT / "lib/core/widgets/atlas_module_decision_panel.dart",
    "health": ROOT / "lib/features/animal_health/presentation/screens/health_overview_screen.dart",
    "reproduction": ROOT / "lib/features/animal_reproduction/presentation/screens/reproduction_overview_screen.dart",
    "nutrition": ROOT / "lib/features/nutrition/presentation/screens/nutrition_overview_screen.dart",
}

texts = {}
errors = []

for name, path in files.items():
    if not path.exists():
        errors.append(f"Arquivo ausente: {path.relative_to(ROOT)}")
        continue
    texts[name] = path.read_text(encoding="utf-8", errors="ignore")

def check(name, condition):
    if not condition:
        errors.append(name)

check(
    "painel decisório compartilhado ausente",
    "class AtlasModuleDecisionPanel extends StatelessWidget" in texts.get("panel", ""),
)
check(
    "painel não trata normal/atenção/crítico",
    all(
        token in texts.get("panel", "")
        for token in (
            "AtlasModuleAttentionLevel.normal",
            "AtlasModuleAttentionLevel.attention",
            "AtlasModuleAttentionLevel.critical",
        )
    ),
)

for module in ("health", "reproduction", "nutrition"):
    text = texts.get(module, "")
    check(
        f"{module}: painel decisório não integrado",
        "AtlasModuleDecisionPanel(" in text,
    )
    check(
        f"{module}: status do módulo ausente",
        "_moduleStatusTitle" in text and "_decisionItems" in text,
    )
    check(
        f"{module}: refresh operacional ausente",
        "AtlasOperationalActionBar(" in text and "onRefresh: loadData" in text,
    )
    check(
        f"{module}: mojibake detectado",
        not any(
            token in text
            for token in ("Ã§", "Ã£", "Ã©", "Ã³", "Ãª", "Ã¡", "Ã­", "Ãº", "Â")
        ),
    )
    check(
        f"{module}: DropdownButtonFormField(value:) depreciado introduzido",
        not re.search(
            r"DropdownButtonFormField<[^>]+>\(\s*\n\s*value:",
            text,
            re.S,
        ),
    )

health = texts.get("health", "")
check("sanidade não resume quarentena", "quarantineAnimals" in health)
check("sanidade não resume carência", "activeWithdrawalAnimals" in health)
check("sanidade não resume retornos", "scheduledReturns" in health)
check("sanidade sem manejo coletivo", "'Manejo coletivo'" in health)
check(
    "sanidade manejo coletivo não abre motor oficial",
    "FarmHandlingScreen(" in health,
)

repro = texts.get("reproduction", "")
check("reprodução sem taxa de prenhez", "pregnancyRate" in repro)
check("reprodução sem taxa de concepção", "conceptionRate" in repro)
check("reprodução sem inseminações", "inseminations" in repro)
check("reprodução sem manejo coletivo", "'Manejo coletivo'" in repro)
check(
    "reprodução manejo coletivo não abre motor oficial",
    "FarmHandlingScreen(" in repro,
)

nutrition = texts.get("nutrition", "")
check("nutrição sem desempenho vs meta", "belowTargetPlans" in nutrition)
check(
    "nutrição sem status da integração com estoque",
    "pendingInventoryIntegrations" in nutrition,
)
check(
    "nutrição sem indicador de desempenho observado",
    "plansWithoutObservedPerformance" in nutrition,
)
check(
    "nutrição não usa dados canônicos de NutritionPlanData",
    "List<NutritionPlanData> plans" in nutrition,
)

# Package 3 must not create a parallel persistence layer.
for name, text in texts.items():
    if name == "panel":
        continue
    check(
        f"{name}: SharedPreferences paralelo introduzido",
        "SharedPreferences" not in text,
    )

if errors:
    print(f"ATLAS POST-V21 PACKAGE 3: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS POST-V21 PACKAGE 3: 30/30")
