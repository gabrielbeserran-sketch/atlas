from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

policy_path = ROOT / "lib/core/navigation/atlas_product_surface_policy.dart"
analysis_path = (
    ROOT
    / "lib/features/atlas_intelligence_center/presentation/screens/"
    "atlas_intelligence_center_screen.dart"
)
audit_path = ROOT / "docs/ATLAS_POS_V21_PACOTE_6C_CAPABILITY_OWNERSHIP.json"

errors: list[str] = []

for path in (policy_path, analysis_path, audit_path):
    if not path.exists():
        errors.append(f"Arquivo obrigatório ausente: {path.relative_to(ROOT)}")

policy = policy_path.read_text(encoding="utf-8", errors="ignore")
analysis = analysis_path.read_text(encoding="utf-8", errors="ignore")
audit = (
    json.loads(audit_path.read_text(encoding="utf-8"))
    if audit_path.exists()
    else {}
)

def check(name: str, condition: bool) -> None:
    if not condition:
        errors.append(name)

summary = audit.get("summary", {})
items = audit.get("items", [])
owners = summary.get("owners", {})

check("auditoria não cobre 98 componentes", summary.get("components_total") == 98)
check("auditoria não cobre 69 raízes", summary.get("feature_roots_total") == 69)
check("item avançado sem proprietário", all(item.get("owner_6c") for item in items))
check(
    "proprietário fora da taxonomia",
    all(
        item.get("owner_6c")
        in {
            "Rebanho",
            "Reprodução",
            "Sanidade",
            "Nutrição",
            "Estoque",
            "Financeiro",
            "Campo",
            "Análises",
            "Relatórios",
            "Consultoria",
            "Interno",
        }
        for item in items
    ),
)

check(
    "política não possui contagem de famílias",
    "specializedCapabilityCountByOwner" in policy,
)
check("política não possui fluxos do módulo", "moduleWorkflows" in policy)
check(
    "política não preserva recursos internos",
    "internalOnlyCapabilityRoots" in policy,
)

for module in (
    "Rebanho",
    "Reprodução",
    "Sanidade",
    "Nutrição",
    "Estoque",
    "Financeiro",
    "Campo",
):
    check(
        f"fluxos operacionais ausentes: {module}",
        f"'{module}': [" in policy,
    )

check(
    "Análises não usa política central",
    "AtlasProductSurfacePolicy.moduleWorkflows[area.title]" in analysis,
)
check(
    "Análises não mostra organização das ferramentas",
    "specializedCapabilityCountByOwner[area.title]" in analysis,
)
check(
    "Análises perdeu abertura direta do módulo",
    "widget.onNavigateModule!(area.moduleLabel)" in analysis,
)

# The producer-facing UI must not reveal development vocabulary.
visible_strings = re.findall(r"'([^'\n]{2,120})'", analysis)
for value in visible_strings:
    check(
        f"vocabulário de desenvolvimento visível: {value}",
        re.search(r"\b(?:Pacote|Marco|Sprint|Etapa)\s*\d+", value, re.I)
        is None,
    )

# Advanced/local implementation roots never become main menu labels.
menu_match = re.search(
    r"mainMenuLabels\s*=\s*\{(.*?)\};",
    policy,
    re.S,
)
menu_block = menu_match.group(1) if menu_match else ""
for item in items:
    root_name = item.get("feature_root", "").strip()
    if root_name:
        check(
            f"raiz especializada vazou para menu: {root_name}",
            root_name not in menu_block,
        )

if errors:
    print(
        f"ATLAS POS-V21 PACKAGE 6C CAPABILITY OWNERSHIP: "
        f"FAIL ({len(errors)} erro(s))"
    )
    for error in errors:
        print("-", error)
    sys.exit(1)

total = 13 + 7 + len(visible_strings) + len(
    {item.get("feature_root", "") for item in items if item.get("feature_root")}
)
print(f"ATLAS POS-V21 PACKAGE 6C CAPABILITY OWNERSHIP: OK")
print(f"Componentes auditados: {summary.get('components_total')}")
print(f"Raízes classificadas: {summary.get('feature_roots_total')}")
print("Órfãos: 0")
print("Vazamentos para menu: 0")
