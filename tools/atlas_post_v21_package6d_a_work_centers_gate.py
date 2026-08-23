from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

files = {
    "policy": ROOT / "lib/core/navigation/atlas_product_surface_policy.dart",
    "guide": ROOT / "lib/core/widgets/atlas_module_workspace_guide.dart",
    "herd": ROOT / "lib/features/herd/presentation/screens/herd_overview_screen.dart",
    "reproduction": ROOT / "lib/features/animal_reproduction/presentation/screens/reproduction_overview_screen.dart",
    "health": ROOT / "lib/features/animal_health/presentation/screens/health_overview_screen.dart",
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

guide=texts.get("guide","")
policy=texts.get("policy","")
herd=texts.get("herd","")
repro=texts.get("reproduction","")
health=texts.get("health","")

check("guia operacional ausente", "class AtlasModuleWorkspaceGuide" in guide)
check("guia ainda fala em Pacote/Marco", "Pacote " not in guide and "Marco " not in guide)
check("política de fluxos ausente", "moduleWorkflows" in policy)
check("Rebanho sem painel de decisão", "AtlasModuleDecisionPanel(" in herd)
check("Rebanho sem guia de trabalho", "moduleLabel: 'Rebanho'" in herd)
check("Rebanho sem prioridade de pesagem", "animalsWithoutWeight" in herd)
check("Reprodução sem painel de decisão", "AtlasModuleDecisionPanel(" in repro)
check("Reprodução sem guia de trabalho", "moduleLabel: 'Reprodução'" in repro)
check("Sanidade sem painel de decisão", "AtlasModuleDecisionPanel(" in health)
check("Sanidade sem guia de trabalho", "moduleLabel: 'Sanidade'" in health)

for name,text in texts.items():
    check(f"{name}: mojibake", not any(x in text for x in ("Ã§","Ã£","Ã©","Â")))
    check(f"{name}: linguagem de produção vazou", not any(x in text for x in ("Pacote 6D","Marco 6D","Etapa 6D")))

if errors:
    print(f"ATLAS POS-V21 PACKAGE 6D-A: FAIL ({len(errors)} erro(s))")
    for item in errors:
        print("-", item)
    sys.exit(1)

print("ATLAS POS-V21 PACKAGE 6D-A: 20/20")
