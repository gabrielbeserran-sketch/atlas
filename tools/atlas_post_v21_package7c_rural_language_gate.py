from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
language = (
    ROOT
    / "lib/features/dr_beserra/domain/services/dr_beserra_language_service.dart"
).read_text(encoding="utf-8")
model = (
    ROOT
    / "lib/features/dr_beserra/domain/models/dr_beserra_command.dart"
).read_text(encoding="utf-8")
gateway = (
    ROOT
    / "lib/features/dr_beserra/data/services/dr_beserra_command_gateway.dart"
).read_text(encoding="utf-8")
routine = (
    ROOT
    / "lib/features/dr_beserra/domain/services/dr_beserra_daily_routine_service.dart"
).read_text(encoding="utf-8", errors="ignore") if (
    ROOT
    / "lib/features/dr_beserra/domain/services/dr_beserra_daily_routine_service.dart"
).exists() else ""
screen = (
    ROOT
    / "lib/features/dr_beserra/presentation/screens/dr_beserra_screen.dart"
).read_text(encoding="utf-8")
voice = (
    ROOT
    / "lib/features/dr_beserra/data/services/dr_beserra_voice_service.dart"
).read_text(encoding="utf-8")
main = (ROOT / "lib/main.dart").read_text(encoding="utf-8")

errors = []
def check(label, condition):
    if not condition:
        errors.append(label)

# Regression reported in Windows.
check("dart:ui redundante reapareceu", "import 'dart:ui';" not in main)
check(
    "API depreciada localeId reapareceu",
    re.search(
        r"_speech\.listen\(\s*"
        r"onResult\s*:\s*_onResult\s*,\s*"
        r"localeId\s*:",
        voice,
        re.S,
    )
    is None,
)
check("SpeechListenOptions ausente", "listenOptions: SpeechListenOptions(" in voice)
check("pt-BR não preservado nas opções", "localeId: _preferredLocaleId" in voice)

# Rural/contextual vocabulary.
required_phrases = (
    "qual a lida de hoje",
    "lida de amanha",
    "gestacao",
    "pesar",
    "sal mineral",
    "fluxo de caixa",
    "estoque",
    "piquete",
    "indicadores",
    "responsavel veterinario",
    "relatorio",
)
for phrase in required_phrases:
    check(f"vocabulário rural ausente: {phrase}", phrase in language)

required_intents = (
    "tomorrowTasks",
    "openNutrition",
    "openFinance",
    "openInventory",
    "openField",
    "openIntelligence",
    "openReports",
    "openConsulting",
)
for intent in required_intents:
    check(f"intent ausente: {intent}", intent in model and intent in language)

# Official destinations.
for route in (
    "Nutrição",
    "Financeiro",
    "Estoque",
    "Campo",
    "Inteligência",
    "Relatórios",
    "Consultoria",
):
    check(f"rota oficial ausente: {route}", f"routeLabel: '{route}'" in gateway)

# Tomorrow is a real Agenda read, not invented data.
check("amanhã não usa Agenda oficial", "DrBeserraIntent.tomorrowTasks" in gateway)
check("consulta diária não usa Agenda oficial", "_loadFarmTasks(farm)" in gateway)
check(
    "filtro de data oficial ausente",
    "_taskDateKey(task.date) == dayKey" in gateway
    or "_taskDateKey(task.date) == targetKey" in routine,
)

# Safety boundary must remain identical.
check("Agenda oficial deixou de ser a escrita", "FarmAgendaStorageService" in gateway)
check("confirmação deixou de existir", "confirmTaskCompletion(" in gateway)
check("write pós-confirmação ausente", "_agenda.updateTask(" in gateway)
for forbidden in (
    "AtlasHttpClient",
    "SharedPreferences",
):
    check(f"gateway ganhou infraestrutura direta indevida: {forbidden}", forbidden not in gateway)
check(
    "operações posteriores não possuem fronteira explícita",
    "confirmOperation(" in gateway or (
        "AnimalHealthStorageService" not in gateway
        and "AnimalReproductionStorageService" not in gateway
        and "FarmHandlingEnterpriseService" not in gateway
    ),
)
check("voz ganhou escrita de negócio", "FarmAgendaStorageService" not in voice)
check("voz não passa pelo sendText", "sendText(lastVoiceFinal)" in screen)

# User-facing cleanliness.
for name, text in (
    ("language", language),
    ("gateway", gateway),
    ("screen", screen),
    ("voice", voice),
):
    check(
        f"{name}: mojibake",
        not any(token in text for token in ("Ã§", "Ã£", "Ã©", "Ã³", "Â")),
    )
    check(
        f"{name}: vocabulário de desenvolvimento visível",
        re.search(r"\b(?:Pacote|Marco|Sprint|Etapa)\s*\d+", text, re.I)
        is None,
    )

if errors:
    print(f"ATLAS POS-V21 PACOTE 7C: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS POS-V21 PACOTE 7C: 45/45")
print("Linguagem rural/contextual: ampliada")
print("Linguagem 7C não concede escrita por conta própria")
print("Regressões do analyzer reportadas no 7B: bloqueadas")
