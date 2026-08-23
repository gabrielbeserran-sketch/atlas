from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

files = {
    "command": ROOT / "lib/features/dr_beserra/domain/models/dr_beserra_command.dart",
    "language": ROOT / "lib/features/dr_beserra/domain/services/dr_beserra_language_service.dart",
    "contextual_model": ROOT / "lib/features/dr_beserra/domain/models/dr_beserra_contextual_insight.dart",
    "contextual": ROOT / "lib/features/dr_beserra/data/services/dr_beserra_contextual_intelligence_service.dart",
    "gateway": ROOT / "lib/features/dr_beserra/data/services/dr_beserra_command_gateway.dart",
    "screen": ROOT / "lib/features/dr_beserra/presentation/screens/dr_beserra_screen.dart",
    "voice": ROOT / "lib/features/dr_beserra/data/services/dr_beserra_voice_service.dart",
}

errors = []
texts = {}
for name, path in files.items():
    if not path.exists():
        errors.append(f"arquivo ausente: {path.relative_to(ROOT)}")
    else:
        texts[name] = path.read_text(encoding="utf-8", errors="ignore")

def check(label, condition):
    if not condition:
        errors.append(label)

command = texts.get("command", "")
language = texts.get("language", "")
contextual_model = texts.get("contextual_model", "")
contextual = texts.get("contextual", "")
gateway = texts.get("gateway", "")
screen = texts.get("screen", "")
voice = texts.get("voice", "")

for intent in (
    "contextualAttention",
    "matricesOverview",
    "worstLot",
    "financialPressure",
):
    check(f"intent contextual ausente: {intent}", intent in command and intent in language)
    check(f"gateway não trata {intent}", f"DrBeserraIntent.{intent}" in gateway)

check(
    "modelo de insight contextual ausente",
    "class DrBeserraContextualInsight" in contextual_model,
)
check(
    "serviço contextual ausente",
    "class DrBeserraContextualIntelligenceService" in contextual,
)

# Official read sources.
for source in (
    "FarmAgendaStorageService",
    "FarmFinanceStorageService",
    "FarmInventoryStorageService",
    "NutritionStorageService",
    "AnimalEnterpriseService",
    "AnimalReproductionStorageService",
    "HerdEnterpriseService",
):
    check(f"fonte oficial ausente: {source}", source in contextual)

# This package must be read-only.
for forbidden in (
    "createRecord(",
    "updateRecord(",
    "deleteRecord(",
    "savePlan(",
    "registerMovement(",
    "updateTask(",
    "createAnimal(",
    "updateAnimal(",
    "deleteAnimal(",
):
    check(f"inteligência 7F ganhou escrita: {forbidden}", forbidden not in contextual)

check("contextual ganhou HTTP direto", "AtlasHttpClient" not in contextual)
check("contextual ganhou banco/local storage direto", "SharedPreferences" not in contextual and "AtlasLocalDatabase" not in contextual)

# Data sufficiency / no fabricated conclusions.
check("insight não possui dataSufficient", "dataSufficient" in contextual_model)
check(
    "pior lote não exige dados observados e meta",
    "targetDailyGainKg > 0" in contextual and "observedDailyGainKg > 0" in contextual,
)
check(
    "matrizes são inferidas sem categoria",
    "category.contains('matriz')" in contextual
    and "não vou inferir quais" in contextual,
)
check(
    "resumo contextual omite limite diagnóstico",
    "não são um diagnóstico automático" in contextual,
)
check(
    "matrizes omitem limite veterinário",
    "não um diagnóstico" in contextual and "'veterinário.'" in contextual,
)

# Finance must respect the long cattle cycle; don't equate temporary cash pressure with failure.
check("financeiro não fala em ciclo pecuário", "ciclo pecuário" in contextual)
check(
    "financeiro sentencia saúde do negócio",
    "não classifica o negócio como saudável ou inviável" in contextual,
)
check(
    "financeiro não separa pendente/vencido",
    "Pendente:" in contextual and "Vencido:" in contextual,
)

# Avoid a burst of dozens of reproduction requests.
check(
    "matrizes não possuem batching",
    "_loadReproductionInBatches(" in contextual and "batchSize = 5" in contextual,
)
check(
    "limite de matrizes ausente",
    "maxDetailedAnimals = 40" in contextual,
)

# Source transparency.
check("gateway não mostra fontes", "Fontes:" in gateway)
check(
    "gateway não marca insuficiência",
    "Dados insuficientes para uma conclusão mais forte." in gateway,
)

# Voice remains transport only.
for forbidden in (
    "DrBeserraContextualIntelligenceService",
    "FarmFinanceStorageService",
    "NutritionStorageService",
    "AnimalReproductionStorageService",
):
    check(f"voz ganhou inteligência de negócio: {forbidden}", forbidden not in voice)

# Quick-access prompts.
for phrase in (
    "O que merece atenção hoje?",
    "Como estão as matrizes?",
    "Qual lote está pior?",
    "O que está pesando no financeiro?",
):
    check(f"atalho contextual ausente: {phrase}", phrase in screen)

# Production hygiene.
for name, text in texts.items():
    check(
        f"{name}: mojibake",
        not any(token in text for token in ("Ã§", "Ã£", "Ã©", "Ã³", "Â")),
    )
    if name not in ("command", "contextual_model"):
        check(
            f"{name}: vocabulário de desenvolvimento visível",
            re.search(r"\b(?:Pacote|Marco|Sprint|Etapa)\s*\d+", text, re.I)
            is None,
        )

if errors:
    print(f"ATLAS POS-V21 PACOTE 7F: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS POS-V21 PACOTE 7F: APROVADO")
print("Inteligência contextual: SOMENTE LEITURA")
print("Fontes oficiais: Agenda, Rebanho, Reprodução, Nutrição, Financeiro, Estoque")
print("Conclusões sem dados suficientes: BLOQUEADAS")
print("Escritas novas do 7F: 0")
