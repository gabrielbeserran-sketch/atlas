from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
source = (
    ROOT / "lib/features/animal/presentation/screens/animal_detail_screen.dart"
).read_text(encoding="utf-8", errors="ignore")
test = (
    ROOT / "test/features/animal/animal_central_navigation_cleanup_test.dart"
).read_text(encoding="utf-8", errors="ignore")

errors = []
start = source.find("class AnimalHubNavigation extends StatelessWidget")
end = source.find("class NavigationModuleRow", start)

if start < 0 or end < 0:
    errors.append("Navegação canônica da Central do Animal não localizada.")
else:
    navigation = source[start:end]
    if navigation.count("value: AnimalHubSection.") != 7:
        errors.append("Central do Animal deve possuir exatamente sete destinos.")
    for label in (
        "'Resumo'",
        "'Histórico'",
        "'Desempenho'",
        "'Sanidade'",
        "'Reprodução'",
        "'Genealogia'",
        "'Arquivos'",
    ):
        if label not in navigation:
            errors.append(f"Destino canônico ausente: {label}")
    for stale in ("'Manejo'", "'Agenda'", "'Pendências'", "'Mais recursos'"):
        if stale in navigation:
            errors.append(f"Destino removido reapareceu: {stale}")

if "sete destinos canônicos" not in test:
    errors.append("Teste não documenta o contrato atual de sete destinos.")

if errors:
    print("ATLAS V21.3 TEST CONTRACT: FAIL")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS V21.3 TEST CONTRACT: OK")
