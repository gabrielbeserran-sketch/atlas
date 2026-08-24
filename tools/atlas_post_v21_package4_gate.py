from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

paths = {
    "shell": ROOT / "lib/core/navigation/atlas_home_shell.dart",
    "screen": ROOT / "lib/features/consultancy_client/presentation/screens/atlas_client_consultancy_center_screen.dart",
    "contact": ROOT / "lib/features/consultancy_client/data/services/atlas_consultancy_contact_service.dart",
    "whatsapp": ROOT / "lib/features/consultancy_client/data/services/atlas_consultancy_whatsapp_service.dart",
    "profile": ROOT / "lib/features/consultancy_client/domain/models/atlas_consultancy_contact_profile.dart",
    "external": ROOT / "lib/core/platform/atlas_external_open_service.dart",
    "legacy_repo": ROOT / "lib/features/consultancy_hub/data/services/atlas_consultancy_repository.dart",
}

texts = {}
errors = []

for name, path in paths.items():
    if not path.exists():
        errors.append(f"Arquivo ausente: {path.relative_to(ROOT)}")
        continue
    texts[name] = path.read_text(encoding="utf-8", errors="ignore")

def check(name, condition):
    if not condition:
        errors.append(name)

shell = texts.get("shell", "")
screen = texts.get("screen", "")
contact = texts.get("contact", "")
whatsapp = texts.get("whatsapp", "")
profile = texts.get("profile", "")
external = texts.get("external", "")

route_start = shell.find("static final List<AtlasRouteDefinition> routes = [")
route_end = shell.find("\n  ];", route_start)
routes = shell[route_start:route_end] if route_start >= 0 and route_end > route_start else ""

check("menu não expõe Consultoria", "label: 'Consultoria'" in routes)
check(
    "Consultoria não está vinculada à fazenda ativa",
    "'Consultoria'," in shell[shell.find("farmScopedModules"):],
)
check(
    "menu não abre a central de consultoria do cliente",
    "AtlasClientConsultancyCenterScreen(" in shell,
)
check(
    "menu usa dashboard administrativo legado",
    "AtlasConsultancyDashboard" not in shell,
)

check(
    "central não identifica veterinário responsável",
    "contact.role" in screen and "contact.displayName" in screen,
)
check(
    "central não possui Falar no WhatsApp",
    "'Falar no WhatsApp'" in screen,
)
check(
    "central não possui Solicitar visita",
    "'Solicitar visita'" in screen,
)
check(
    "central não possui Enviar resumo",
    "'Enviar resumo'" in screen,
)
check(
    "central não integra resumo operacional oficial",
    "AtlasOperationalIntelligenceService" in screen,
)
check(
    "central não integra agenda existente",
    "FarmAgendaStorageService" in screen,
)
check(
    "central não oferece relatórios gerenciais",
    "ReportsScreen()" in screen,
)
check(
    "central não preserva revisão humana antes do envio",
    "O Atlas não envia mensagens sem a sua ação" in screen,
)
check(
    "central não possui fallback seguro quando atualização parcial falha",
    "A central continua disponível" in screen
    and "contato oficial da fazenda" in screen,
)

check(
    "perfil não normaliza número",
    "normalizedWhatsappNumber" in profile,
)
check(
    "perfil não valida WhatsApp",
    "hasValidWhatsapp" in profile,
)
check(
    "contato oficial não vem do backend",
    "'/consultancy/contact'" in contact
    and "AtlasHttpClient" in contact,
)
check(
    "contato do veterinário voltou a ficar hardcoded",
    re.search(r"whatsappNumber:\s*'\d{10,15}'", contact) is None
    and "Gabriel Beserra do Nascimento" not in contact,
)
check(
    "resolver remoto não tem contrato por fazenda",
    "loadForFarm(" in contact
    and "String farmId" in contact
    and "queryParameters: {'farm_id': farmId}" in contact,
)

check(
    "WhatsApp não usa wa.me",
    "'wa.me'" in whatsapp,
)
check(
    "WhatsApp não usa HTTPS",
    "Uri.https(" in whatsapp,
)
check(
    "WhatsApp não codifica mensagem via Uri",
    "{'text': cleanMessage}" in whatsapp,
)
check(
    "WhatsApp não usa abertura externa consolidada",
    "AtlasExternalOpenService.open" in whatsapp,
)
check(
    "serviço externo não suporta HTTPS",
    "uri.scheme == 'https'" in external,
)

# The new client flow may not import or depend on the legacy seeded local CRM.
check(
    "central do cliente importa repositório local legado",
    "consultancy_hub" not in screen
    and "AtlasConsultancyRepository" not in screen,
)
for name in ("screen", "contact", "whatsapp", "profile"):
    text = texts.get(name, "")
    check(
        f"{name}: SharedPreferences introduzido",
        "SharedPreferences" not in text,
    )
    check(
        f"{name}: mojibake detectado",
        not any(
            token in text
            for token in ("Ã§", "Ã£", "Ã©", "Ã³", "Ãª", "Ã¡", "Ã­", "Ãº", "Â")
        ),
    )
    check(
        f"{name}: DropdownButtonFormField(value:) depreciado",
        not re.search(
            r"DropdownButtonFormField<[^>]+>\(\s*\n\s*value:",
            text,
            re.S,
        ),
    )

# Prevent a future "fake WhatsApp" implementation that only displays a phone.
check(
    "botão de WhatsApp não está conectado ao serviço",
    "whatsAppService.openConversation(" in screen,
)

if errors:
    print(f"ATLAS POST-V21 PACKAGE 4: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS POST-V21 PACKAGE 4: 36/36")
