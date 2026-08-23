from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

paths = {
    "shell": ROOT / "lib/core/navigation/atlas_home_shell.dart",
    "policy": ROOT / "lib/core/navigation/atlas_product_surface_policy.dart",
    "model": ROOT / "lib/features/dr_beserra/domain/models/dr_beserra_command.dart",
    "language": ROOT / "lib/features/dr_beserra/domain/services/dr_beserra_language_service.dart",
    "gateway": ROOT / "lib/features/dr_beserra/data/services/dr_beserra_command_gateway.dart",
    "screen": ROOT / "lib/features/dr_beserra/presentation/screens/dr_beserra_screen.dart",
    "agenda": ROOT / "lib/features/farm_agenda/data/services/farm_agenda_storage_service.dart",
    "handling": ROOT / "lib/features/farm_handling/data/services/farm_handling_enterprise_service.dart",
    "health": ROOT / "lib/features/animal_health/data/services/animal_health_storage_service.dart",
    "reproduction": ROOT / "lib/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart",
}

errors = []
texts = {}
for name, path in paths.items():
    if not path.exists():
        errors.append(f"arquivo ausente: {path.relative_to(ROOT)}")
    else:
        texts[name] = path.read_text(encoding="utf-8", errors="ignore")

def check(name, condition):
    if not condition:
        errors.append(name)

shell=texts.get("shell","")
policy=texts.get("policy","")
model=texts.get("model","")
language=texts.get("language","")
gateway=texts.get("gateway","")
screen=texts.get("screen","")
agenda=texts.get("agenda","")
handling=texts.get("handling","")
health=texts.get("health","")
reproduction=texts.get("reproduction","")

# Product/navigation.
check("Dr. Beserra não está no menu oficial", "label: 'Dr. Beserra'" in shell)
check("Dr. Beserra não está em Hoje", re.search(
    r"label: 'Dr\. Beserra'.*?group: AtlasNavigationGroup\.today",
    shell,
    re.S,
) is not None)
check("Dr. Beserra não exige fazenda ativa", "'Dr. Beserra'," in shell)
check("Dr. Beserra não abre embedded", "DrBeserraScreen(" in shell and "embedded: true" in shell)
check("Dr. Beserra não está na política de superfície", "'Dr. Beserra'" in policy)

# Language/vocabulary.
check("parser conversacional ausente", "class DrBeserraLanguageService" in language)
for phrase in (
    "trabaio de hoje",
    "o que e pra fazer hoje",
    "terminei",
    "acabei",
    "vacin",
    "vermifug",
    "iatf",
    "brete",
):
    check(f"vocabulário simples ausente: {phrase}", phrase in language)
check("normalização de acentos ausente", "'ç': 'c'" in language and "'ã': 'a'" in language)

# Safe command boundary.
check("gateway seguro ausente", "class DrBeserraCommandGateway" in gateway)
check("Agenda oficial não é usada", "FarmAgendaStorageService" in gateway)
check("consulta oficial da Agenda ausente", "_agenda.loadTasks(" in gateway)
check("conclusão oficial da Agenda ausente", "_agenda.updateTask(" in gateway)
check("conclusão não exige confirmação explícita", "confirmTaskCompletion(" in gateway)
check("confirmação não relê servidor", "final tasks = await _agenda.loadTasks" in gateway)
check("confirmação não verifica persistência", "if (!updated.isCompleted)" in gateway)
check("gateway escreve direto por HTTP", "AtlasHttpClient" not in gateway and "_http." not in gateway)
check("gateway escreve direto no banco", "AtlasLocalDatabase" not in gateway and "SharedPreferences" not in gateway)
check(
    "gateway ganhou escrita sem fronteira explícita",
    "confirmOperation(" in gateway or (
        "AnimalHealthStorageService" not in gateway
        and "AnimalReproductionStorageService" not in gateway
        and "FarmHandlingEnterpriseService" not in gateway
    ),
)
check("gateway exclui dados", "deleteRecord(" not in gateway and "cancelTask(" not in gateway)

# Official service contracts remain intact.
check("Agenda perdeu verificação pós-write", "Confirma persistência por uma segunda leitura" in agenda)
check("Manejo perdeu endpoint batch oficial", "'/livestock/handling/batch'" in handling)
check("Sanidade perdeu POST oficial", "'/livestock/health'" in health and "createRecord(" in health)
check("Reprodução perdeu POST oficial", "'/livestock/animals/$animalId/reproduction'" in reproduction and "createRecord(" in reproduction)

# UX safety.
check("tela não informa regra de segurança", "nunca altero um registro sem uma ação permitida" in screen)
check("tela não possui confirmação", "_ConfirmationBar" in screen and "Confirmar" in screen)
check("tela não informa falha sem alteração", "Nenhum registro foi alterado" in screen)
check("erro de conclusão pode fingir alteração", "A tarefa foi mantida como estava" in screen)
check("navegação para módulo oficial ausente", "widget.onNavigateModule(route)" in screen)
check("envio sem tooltip", "tooltip: 'Enviar mensagem'" in screen)

# Package 7A is text-first; microphone capture must not be faked.
check("captura de voz fictícia adicionada", "SpeechToText" not in screen and "speech_to_text" not in screen)

# No development vocabulary/mojibake in new user-facing files.
for name, text in (("screen",screen),("language",language),("gateway",gateway)):
    check(
        f"{name}: vocabulário de desenvolvimento",
        re.search(r"\b(?:Pacote|Marco|Sprint|Etapa)\s*\d+", text, re.I) is None,
    )
    check(
        f"{name}: mojibake",
        not any(token in text for token in ("Ã§","Ã£","Ã©","Ã³","Â")),
    )

if errors:
    print(f"ATLAS POS-V21 PACOTE 7A DR BESERRA: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS POS-V21 PACOTE 7A DR BESERRA: 44/44")
print("Contrato histórico 7A preservado: Agenda exige confirmação")
print("Escrita direta por HTTP/banco: 0")
print("Capacidades posteriores devem possuir fronteira confirmOperation")
