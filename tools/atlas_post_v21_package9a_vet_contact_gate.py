from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

files = {
    "model": ROOT / "backend/app/models/legacy.py",
    "migration": ROOT / "backend/alembic/versions/20260823_0044_consultancy_contacts.py",
    "router": ROOT / "backend/app/routers/consultancy.py",
    "main": ROOT / "backend/app/main.py",
    "profile": ROOT / "lib/features/consultancy_client/domain/models/atlas_consultancy_contact_profile.dart",
    "service": ROOT / "lib/features/consultancy_client/data/services/atlas_consultancy_contact_service.dart",
    "whatsapp": ROOT / "lib/features/consultancy_client/data/services/atlas_consultancy_whatsapp_service.dart",
    "screen": ROOT / "lib/features/consultancy_client/presentation/screens/atlas_client_consultancy_center_screen.dart",
    "shell": ROOT / "lib/core/navigation/atlas_home_shell.dart",
    "package4_test": ROOT / "test/features/consultancy_client/post_v21_package4_consultancy_contract_test.dart",
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

model = texts.get("model", "")
migration = texts.get("migration", "")
router = texts.get("router", "")
main = texts.get("main", "")
profile = texts.get("profile", "")
service = texts.get("service", "")
whatsapp = texts.get("whatsapp", "")
screen = texts.get("screen", "")
shell = texts.get("shell", "")
package4_test = texts.get("package4_test", "")

check("model ConsultancyContact ausente", "class ConsultancyContact(Base):" in model)
check(
    "contato não é único por empresa/fazenda",
    "uq_consultancy_contact_company_farm" in model
    and "uq_consultancy_contact_company_farm" in migration,
)
check(
    "migration 0044 não encadeia 0043",
    'revision = "20260823_0044"' in migration
    and 'down_revision = "20260823_0043"' in migration,
)
check(
    "router não valida escopo da fazenda",
    "require_farm_scope(principal, farm_id)" in router,
)
check(
    "leitura não exige farms.read",
    'require_permission("farms.read")' in router,
)
check(
    "edição não exige farms.update",
    'require_permission("farms.update")' in router,
)
check(
    "router aceita telefone inválido",
    "10 <= len(whatsapp) <= 15" in router,
)
check(
    "router de consultoria não registrado",
    "consultancy.router" in main,
)
check(
    "readiness de deploy 9A ausente",
    '"/deployment-readiness"' in router and '"schema_ready": True' in router,
)

check(
    "Flutter não lê contato remoto",
    "'/consultancy/contact'" in service,
)
check(
    "Flutter não atualiza contato remoto",
    "'PATCH'" in service and "updateForFarm" in service,
)
check(
    "perfil não bloqueia contato não configurado",
    "configured &&" in profile and "active &&" in profile,
)
check(
    "central perdeu ação WhatsApp",
    "Falar no WhatsApp" in screen,
)
check(
    "central perdeu solicitação de visita",
    "Solicitar visita" in screen,
)
check(
    "central perdeu envio de resumo",
    "Enviar resumo" in screen,
)
check(
    "edição do responsável não é protegida por permissão",
    "canManageContact" in screen
    and "controller.allows('farms.update')" in shell,
)

check(
    "teste legado do Pacote 4 ainda exige contato hardcoded",
    'contact.contains("role: \'Veterinário responsável\'")' not in package4_test
    and "contact.contains(\"'/consultancy/contact'\")" in package4_test
    and "screen.contains('contact.role')" in package4_test,
)

# Prevent personal contact details from returning to executable Flutter.
flutter_contact_files = (profile, service, whatsapp, screen, shell)
for forbidden in (
    "5561993886261",
    "Gabriel Beserra do Nascimento",
):
    check(
        f"contato pessoal voltou a ficar hardcoded no Flutter: {forbidden}",
        all(forbidden not in text for text in flutter_contact_files),
    )

# WhatsApp remains user-initiated, not automatic.
check(
    "WhatsApp direto perdeu revisão do usuário",
    "wa.me" in whatsapp
    and "AtlasExternalOpenService.open" in whatsapp,
)
check(
    "tela passou a afirmar envio automático",
    "O Atlas não envia mensagens sem a sua ação." in screen,
)

for name, text in texts.items():
    check(
        f"{name}: mojibake",
        not any(token in text for token in ("Ã§", "Ã£", "Ã©", "Ã³", "Â")),
    )

if errors:
    print(f"ATLAS POS-V21 PACOTE 9A: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS POS-V21 PACOTE 9A: APROVADO")
print("Contato veterinário: backend oficial por fazenda")
print("WhatsApp hardcoded no Flutter: 0")
print("Edição: farms.update")
print("Abertura do WhatsApp: ação explícita do usuário")
