from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
path = (
    ROOT
    / "lib/features/dr_beserra/domain/services/"
    "dr_beserra_language_service.dart"
)
text = path.read_text(encoding="utf-8", errors="ignore")

errors = []

def check(label, condition):
    if not condition:
        errors.append(label)

required_roots = {
    "Sanidade": ("'vacin'", "'vermifug'", "'medic'", "'tratament'"),
    "Reprodução": ("'insemin'", "'gestacao'", "'hormon'", "'reproduc'"),
    "Nutrição": ("'nutric'", "'suplement'", "'cocho'", "'consumo'"),
    "Manejo": ("'pesag'", "'moviment'", "'brete'", "'apartac'"),
}
for module, roots in required_roots.items():
    for root in roots:
        check(f"{module}: raiz semântica ausente {root}", root in text)

# Specific technical domains must be evaluated before generic herd words.
herd_pos = text.find("intent: DrBeserraIntent.openHerd")
for intent in (
    "openHealth",
    "openReproduction",
    "openNutrition",
    "openFinance",
    "openInventory",
    "openField",
    "openHandling",
):
    pos = text.find(f"intent: DrBeserraIntent.{intent}")
    check(f"{intent}: branch ausente", pos >= 0)
    check(
        f"{intent}: perdeu precedência sobre Rebanho",
        pos >= 0 and herd_pos >= 0 and pos < herd_pos,
    )

for generic in ("'gado'", "'animal'", "'animais'", "'boi'", "'vaca'"):
    check(f"token genérico de Rebanho ausente {generic}", generic in text)

# Prevent the exact regression reported by Windows:
# inflected technical verbs must be covered by roots.
check("vermifugar não está coberto por raiz", "'vermifug'" in text)
check("vacinar não está coberto por raiz", "'vacin'" in text)
check("inseminação não está coberta por raiz", "'insemin'" in text)
check("pesagem não está coberta por raiz", "'pesag'" in text)

if errors:
    print(f"ATLAS 7C INTENT COLLISION: FAIL ({len(errors)})")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS 7C INTENT COLLISION: APROVADO")
print("Domínios específicos antes de Rebanho: OK")
print("Raízes morfológicas críticas: OK")
print("Regressão 'vermifugar o gado -> Rebanho': BLOQUEADA")
