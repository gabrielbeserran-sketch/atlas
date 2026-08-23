from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

paths = {
    "draft": ROOT / "lib/features/dr_beserra/domain/models/dr_beserra_operation_draft.dart",
    "parser": ROOT / "lib/features/dr_beserra/domain/services/dr_beserra_operation_parser.dart",
    "gateway": ROOT / "lib/features/dr_beserra/data/services/dr_beserra_command_gateway.dart",
    "screen": ROOT / "lib/features/dr_beserra/presentation/screens/dr_beserra_screen.dart",
    "language": ROOT / "lib/features/dr_beserra/domain/services/dr_beserra_language_service.dart",
    "health": ROOT / "lib/features/animal_health/data/services/animal_health_storage_service.dart",
    "reproduction": ROOT / "lib/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart",
    "handling": ROOT / "lib/features/farm_handling/data/services/farm_handling_enterprise_service.dart",
}

errors = []
texts = {}
for name, path in paths.items():
    if not path.exists():
        errors.append(f"arquivo ausente: {path.relative_to(ROOT)}")
    else:
        texts[name] = path.read_text(encoding="utf-8", errors="ignore")

def check(label, condition):
    if not condition:
        errors.append(label)

draft = texts.get("draft", "")
parser = texts.get("parser", "")
gateway = texts.get("gateway", "")
screen = texts.get("screen", "")
language = texts.get("language", "")
health = texts.get("health", "")
reproduction = texts.get("reproduction", "")
handling = texts.get("handling", "")

# Structured drafts.
check("rascunho operacional ausente", "class DrBeserraOperationDraft" in draft)
for kind in ("health", "reproduction", "handlingLotMovement"):
    check(f"tipo de operação ausente: {kind}", kind in draft)
check("campos obrigatórios não são calculados", "List<String> get missingFields" in draft)
check("rascunho pode ser executado incompleto", "bool get isComplete => missingFields.isEmpty" in draft)

# Parser must never write.
check("parser operacional ausente", "class DrBeserraOperationParser" in parser)
for forbidden in (
    "AnimalHealthStorageService",
    "AnimalReproductionStorageService",
    "FarmHandlingEnterpriseService",
    "AtlasHttpClient",
    "SharedPreferences",
):
    check(f"parser ganhou escrita indevida: {forbidden}", forbidden not in parser)

# Required fields for each supported write.
for token in (
    "'brinco'",
    "'produto'",
    "'dose'",
    "'responsável'",
    "'resultado do diagnóstico'",
    "'primeiro brinco'",
    "'último brinco'",
    "'lote de destino'",
):
    check(f"campo obrigatório não protegido: {token}", token in draft)

# Safe boundary: interpret builds draft, confirmOperation performs writes.
check("interpret não usa parser operacional", "_operationParser.parse(" in gateway)
check("operação completa não exige confirmação", "confirmationOperation: operation" in gateway)
check("fronteira confirmOperation ausente", "Future<DrBeserraReply> confirmOperation(" in gateway)
check(
    "operação incompleta pode chegar à escrita",
    "if (!operation.isComplete)" in gateway,
)

# Official services only.
check("Sanidade oficial não utilizada", "_health.createRecord(" in gateway)
check("Reprodução oficial não utilizada", "_reproduction.createRecord(" in gateway)
check("Manejo batch oficial não utilizado", "_handling.execute(" in gateway)
check("gateway ganhou AtlasHttpClient direto", "AtlasHttpClient" not in gateway)
check("gateway ganhou SharedPreferences direto", "SharedPreferences" not in gateway)
check("gateway ganhou banco local direto", "AtlasLocalDatabase" not in gateway)

# Server confirmation after writes.
check(
    "Sanidade sem confirmação pós-write",
    "if (!created.synced || created.id.trim().isEmpty)" in gateway,
)
check(
    "Reprodução sem confirmação pós-write",
    gateway.count("if (!created.synced || created.id.trim().isEmpty)") >= 2,
)
check(
    "Manejo não confere quantidade afetada",
    "result.affectedCount != selected.length" in gateway,
)
check(
    "Manejo não exige handlingId",
    "result.handlingId.trim().isEmpty" in gateway,
)

# Resolve IDs from official farm data instead of inventing them.
check("animais não são consultados oficialmente", "_animals.listAnimals(" in gateway)
check("lotes não são consultados oficialmente", "_herd.listGroups(" in gateway)
check("brinco não exige correspondência única", "if (matches.length > 1)" in gateway)
check("lote não exige correspondência segura", "Encontrei mais de um lote parecido" in gateway)
check("ID animal parece inventado", "new_id" not in gateway and "random" not in gateway.lower())

# Batch handling is the efficient bulk operation requested.
check("intervalo de brincos ausente", "_tagInsideRange(" in gateway)
check("ação batch não é lot_movement", "'action': 'lot_movement'" in gateway)
check("lista batch de animal_ids ausente", "'animal_ids': selected.map" in gateway)
check("destino oficial ausente", "'to_lot_id': destination.id" in gateway)

# UI confirmation.
check("UI não armazena operação pendente", "confirmationOperation" in screen)
check("UI não chama confirmação do gateway", "gateway.confirmOperation(" in screen)
check("UI não possui barra de confirmação", "_ConfirmationBar" in screen)
check(
    "falha pode ser apresentada como sucesso",
    "Não consegui confirmar a operação no servidor" in screen,
)

# Language routing must classify "mover" as handling before generic herd.
check("mover não classifica como manejo", "'mover'" in language)
handling_pos = language.find("intent: DrBeserraIntent.openHandling")
herd_pos = language.find("intent: DrBeserraIntent.openHerd")
check(
    "Manejo perdeu precedência sobre Rebanho",
    handling_pos >= 0 and herd_pos >= 0 and handling_pos < herd_pos,
)

# Existing official service contracts remain unchanged.
check("endpoint sanitário oficial desapareceu", "'/livestock/health'" in health)
check(
    "endpoint reprodutivo oficial desapareceu",
    "'/livestock/animals/$animalId/reproduction'" in reproduction,
)
check("endpoint batch oficial desapareceu", "'/livestock/handling/batch'" in handling)

# No destructive operations through conversation in 7D.
for forbidden in (
    "_health.deleteRecord(",
    "_reproduction.deleteRecord(",
    "_animals.deleteAnimal(",
    "sale_or_exit",
):
    check(f"7D ganhou operação destrutiva: {forbidden}", forbidden not in gateway)

# Voice still does not own business writes.
voice = (
    ROOT
    / "lib/features/dr_beserra/data/services/dr_beserra_voice_service.dart"
).read_text(encoding="utf-8", errors="ignore")
for forbidden in (
    "AnimalHealthStorageService",
    "AnimalReproductionStorageService",
    "FarmHandlingEnterpriseService",
    "FarmAgendaStorageService",
):
    check(f"voz ganhou escrita de negócio: {forbidden}", forbidden not in voice)

# Production hygiene.
for name, text in (
    ("draft", draft),
    ("parser", parser),
    ("gateway", gateway),
    ("screen", screen),
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
    print(f"ATLAS POS-V21 PACOTE 7D: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS POS-V21 PACOTE 7D: APROVADO")
print("Sanidade: rascunho -> confirmação -> serviço oficial -> verificação")
print("Reprodução: rascunho -> confirmação -> serviço oficial -> verificação")
print("Manejo: intervalo -> confirmação -> batch oficial -> affected_count")
print("Escritas destrutivas conversacionais: 0")
