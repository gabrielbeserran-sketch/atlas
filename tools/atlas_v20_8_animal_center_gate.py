from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
animal = (
    ROOT / "lib/features/animal/presentation/screens/animal_detail_screen.dart"
).read_text(encoding="utf-8")

checks = []

def check(name, condition):
    checks.append((name, bool(condition)))

start = animal.find("class AnimalHubNavigation extends StatelessWidget")
end = animal.find("class NavigationModuleRow", start)
navigation = animal[start:end] if start >= 0 and end > start else ""

check("resumo orientado ao trabalho", "'Resumo do animal'" in animal)
check("situação atual visível", "_AnimalCurrentSituation(" in animal)
check("ação nova pesagem", "'Nova pesagem'" in animal and "openNewWeight" in animal)
check("ação sanidade", "'Novo evento sanitário'" in animal and "openNewHealthEvent" in animal)
check("ação reprodução", "'Novo evento reprodutivo'" in animal and "openNewReproductionEvent" in animal)
check("movimentações expostas", "'Movimentações'" in animal and "openMovements" in animal)
check("navegação responsiva", "class _AnimalNavigationButton" in animal and "constraints.maxWidth < 420" in animal)
check("sete destinos canônicos", navigation.count("value: AnimalHubSection.") == 7)

for label in (
    "'Resumo'",
    "'Histórico'",
    "'Desempenho'",
    "'Sanidade'",
    "'Reprodução'",
    "'Genealogia'",
    "'Arquivos'",
):
    check(f"destino {label}", label in navigation)

for stale in (
    "'Manejo'",
    "'Agenda'",
    "'Pendências'",
    "'Mais recursos'",
    "'Análises'",
    "'Pesagens'",
    "'Zootecnia'",
):
    check(f"sem {stale}", stale not in navigation)

check(
    "sanidade direta",
    "AnimalHubSection.healthEnterprise => buildHealthSection()" in animal,
)
check(
    "reprodução direta",
    "AnimalHubSection.reproductionEnterprise => buildReproductionSection()" in animal,
)
check(
    "desempenho direto",
    "AnimalHubSection.zootechnical => buildPerformanceSection()" in animal,
)
check("arquivos consolidados", "Widget buildFilesSection()" in animal)
check("status traduzido", "AtlasUiText.status(animal.status) == 'Ativo'" in animal)
check(
    "situação detalhada traduzida",
    "(label: 'Situação', value: AtlasUiText.status(animal.status))" in animal,
)

bad = ("Ã§", "Ã£", "Ã©", "Ã³", "Ãª", "Ã¡", "Ã­", "Ãº", "Â")
check("central sem mojibake", not any(token in animal for token in bad))

failed = [name for name, ok in checks if not ok]
print(f"ATLAS V20.8 ANIMAL CENTER: {len(checks)-len(failed)}/{len(checks)}")
for name in failed:
    print("FAIL:", name)
raise SystemExit(1 if failed else 0)
