from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

files = {
    "command": ROOT / "lib/features/dr_beserra/domain/models/dr_beserra_command.dart",
    "routine_model": ROOT / "lib/features/dr_beserra/domain/models/dr_beserra_daily_routine.dart",
    "routine": ROOT / "lib/features/dr_beserra/domain/services/dr_beserra_daily_routine_service.dart",
    "language": ROOT / "lib/features/dr_beserra/domain/services/dr_beserra_language_service.dart",
    "gateway": ROOT / "lib/features/dr_beserra/data/services/dr_beserra_command_gateway.dart",
    "screen": ROOT / "lib/features/dr_beserra/presentation/screens/dr_beserra_screen.dart",
    "voice": ROOT / "lib/features/dr_beserra/data/services/dr_beserra_voice_service.dart",
    "agenda": ROOT / "lib/features/farm_agenda/data/services/farm_agenda_storage_service.dart",
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
routine_model = texts.get("routine_model", "")
routine = texts.get("routine", "")
language = texts.get("language", "")
gateway = texts.get("gateway", "")
screen = texts.get("screen", "")
voice = texts.get("voice", "")
agenda = texts.get("agenda", "")

# Daily routine source is Agenda, never a parallel store.
check("serviço de rotina ausente", "class DrBeserraDailyRoutineService" in routine)
check("rotina não usa FarmAgendaData", "FarmAgendaData" in routine)
check("rotina ganhou armazenamento próprio", "SharedPreferences" not in routine)
check("rotina ganhou HTTP próprio", "AtlasHttpClient" not in routine)
check("gateway não usa Agenda oficial", "_agenda.loadTasks(" in gateway)

# New intents.
for intent in ("overdueTasks", "priorityTasksToday"):
    check(f"intent ausente: {intent}", intent in command and intent in language)
check("falta hoje não mapeada", "o que falta fazer hoje" in language)
check("atraso não mapeado", "o que ficou atrasado" in language)
check("prioridade não mapeada", "qual a prioridade" in language)

# Priority is deterministic.
check("prioridade não considera atraso", "overdue || priority.contains('urgent')" in routine)
check("prioridade alta ausente", "priority.contains('alta')" in routine)
check("rotina não ordena prioridade", "_priorityScore" in routine and "_compare" in routine)
check("rotina parece chamar IA externa", "openai" not in routine.lower() and "gemini" not in routine.lower())

# Natural completion phrases must not require an exact full-title match.
check("correspondência semântica de tarefa ausente", "bool _taskMatchesSubject(" in gateway)
check("sobreposição de palavras significativas ausente", "titleTokens.intersection(subjectTokens)" in gateway)

# Ownership / reconciliation.
for owner in ("Sanidade", "Reprodução", "Realizar manejo", "Nutrição", "Estoque"):
    check(f"módulo técnico não classificado: {owner}", f"'{owner}'" in routine)
check("atividade técnica pode ser baixa Agenda simples", "if (routineItem.requiresTechnicalRecord)" in gateway)
check("reconciliação pós-write ausente", "_tryCompleteRelatedAgendaTask(" in gateway)
check("relação operação-tarefa ausente", "relatedTaskId" in command and "relatedTaskId" in gateway)
check("UI perde relação operação-tarefa", "relatedTaskId" in screen and "relatedTaskTitle" in screen)

# Critical partial-failure semantics: technical write may succeed while Agenda fails.
check(
    "falha de Agenda após write técnico é escondida",
    "O registro técnico foi confirmado, mas a Agenda não confirmou" in gateway,
)
check(
    "usuário pode repetir manejo após falha parcial",
    "Não repita o manejo. Abra a Agenda" in gateway,
)
check(
    "Agenda relacionada não verifica retorno completed",
    "return updated.isCompleted;" in gateway,
)

# Direct Agenda completion has defensive technical guard too.
direct_start = gateway.find("Future<DrBeserraReply> confirmTaskCompletion")
direct_end = gateway.find("Future<DrBeserraReply> _tasksForDay", direct_start)
direct_block = gateway[direct_start:direct_end] if direct_start >= 0 and direct_end >= 0 else ""
check(
    "confirmTaskCompletion não bloqueia tarefa técnica",
    "routineItem.requiresTechnicalRecord" in direct_block,
)

# Existing safe operation boundaries remain.
for token in (
    "_health.createRecord(",
    "_reproduction.createRecord(",
    "_handling.execute(",
    "confirmOperation(",
):
    check(f"fronteira 7D perdida: {token}", token in gateway)
check("gateway ganhou HTTP direto", "AtlasHttpClient" not in gateway)
check("gateway ganhou storage direto", "SharedPreferences" not in gateway)
check("gateway ganhou banco local", "AtlasLocalDatabase" not in gateway)

# Voice remains transport-only.
for forbidden in (
    "FarmAgendaStorageService",
    "DrBeserraDailyRoutineService",
    "AnimalHealthStorageService",
    "AnimalReproductionStorageService",
    "FarmHandlingEnterpriseService",
):
    check(f"voz ganhou regra de negócio: {forbidden}", forbidden not in voice)
check("voz deixou de entrar por sendText", "sendText(lastVoiceFinal)" in screen)

# Agenda remains official persistence.
check("Agenda perdeu updateTask", "Future<FarmAgendaData> updateTask" in agenda)
check("Agenda perdeu pós-leitura", "Confirma persistência por uma segunda leitura" in agenda)

# UI shortcuts.
check("atalho de atrasos ausente", "O que ficou atrasado?" in screen)
check("atalho de prioridade ausente", "Qual a prioridade hoje?" in screen)

# Production hygiene.
for name, text in texts.items():
    check(
        f"{name}: mojibake",
        not any(token in text for token in ("Ã§", "Ã£", "Ã©", "Ã³", "Â")),
    )
    if name not in ("command", "routine_model"):
        check(
            f"{name}: vocabulário de desenvolvimento visível",
            re.search(r"\b(?:Pacote|Marco|Sprint|Etapa)\s*\d+", text, re.I)
            is None,
        )

if errors:
    print(f"ATLAS POS-V21 PACOTE 7E: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS POS-V21 PACOTE 7E: APROVADO")
print("Fonte da rotina: Agenda oficial")
print("Prioridade: atraso + prioridade cadastrada + horário")
print("Baixa técnica isolada na Agenda: BLOQUEADA")
print("Reconciliação: módulo técnico confirmado -> Agenda confirmada")
print("Nova escrita direta da voz: 0")
