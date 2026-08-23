from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

files = {
    "config": ROOT / "backend/app/config.py",
    "models": ROOT / "backend/app/models/legacy.py",
    "migration": ROOT / "backend/alembic/versions/20260822_0042_monthly_bulletins.py",
    "provider": ROOT / "backend/app/services/whatsapp_provider.py",
    "webhook": ROOT / "backend/app/services/whatsapp_webhook.py",
    "bulletins": ROOT / "backend/app/services/monthly_bulletins.py",
    "scheduler": ROOT / "backend/app/services/bulletin_scheduler.py",
    "router": ROOT / "backend/app/routers/bulletins.py",
    "main": ROOT / "backend/app/main.py",
    "screen": ROOT / "lib/features/consultancy_client/presentation/screens/atlas_client_consultancy_center_screen.dart",
    "widget": ROOT / "lib/features/consultancy_client/presentation/widgets/atlas_monthly_bulletins_card.dart",
    "dart_service": ROOT / "lib/features/consultancy_client/data/services/atlas_monthly_bulletin_service.dart",
    "dart_model": ROOT / "lib/features/consultancy_client/domain/models/atlas_monthly_bulletin_data.dart",
    "workflow": ROOT / ".github/workflows/atlas_monthly_bulletins.yml",
}

texts = {}
errors = []
total_checks = 0

for name, path in files.items():
    if not path.exists():
        errors.append(f"Arquivo ausente: {path.relative_to(ROOT)}")
        continue
    texts[name] = path.read_text(encoding="utf-8", errors="ignore")

def check(name, condition):
    global total_checks
    total_checks += 1
    if not condition:
        errors.append(name)

config = texts.get("config", "")
models = texts.get("models", "")
migration = texts.get("migration", "")
provider = texts.get("provider", "")
webhook = texts.get("webhook", "")
bulletins = texts.get("bulletins", "")
scheduler = texts.get("scheduler", "")
router = texts.get("router", "")
main = texts.get("main", "")
screen = texts.get("screen", "")
widget = texts.get("widget", "")
dart_service = texts.get("dart_service", "")
workflow = texts.get("workflow", "")

# Three distinct monthly bulletins.
check(
    "não existem exatamente três tipos de boletim",
    'BULLETIN_TYPES = ("zootechnical", "operations", "financial")'
    in bulletins,
)
for token in (
    "Boletim Zootécnico",
    "Boletim de Operação e Equipe",
    "Boletim Financeiro",
):
    check(f"boletim ausente: {token}", token in bulletins)

# Canonical data only.
for model in (
    "LivestockAnimal",
    "WeightRecord",
    "HealthEvent",
    "ReproductionEvent",
    "NutritionEvent",
    "OperationalTask",
    "FinancialEntry",
):
    check(f"gerador não usa {model}", model in bulletins)
check(
    "financeiro não explica ciclo longo",
    "pecuária é atividade de ciclo longo" in bulletins,
)
check(
    "boletins usam SharedPreferences no backend",
    "SharedPreferences" not in bulletins,
)

# Durable scheduling + idempotent outbox.
check("modelo BulletinSchedule ausente", "class BulletinSchedule(Base)" in models)
check("modelo BulletinDispatch ausente", "class BulletinDispatch(Base)" in models)
check("opt-in persistente ausente", "whatsapp_opt_in_at" in models)
check(
    "dispatch sem idempotência",
    "idempotency_key" in models
    and "uq_bulletin_dispatch_idempotency" in models,
)
check(
    "envio não possui reserva atômica contra duplicação",
    'status="processing"' in bulletins
    and "BulletinDispatch.status.in_(" in bulletins
    and "claim.rowcount" in bulletins,
)
check(
    "envio não recupera processing interrompido",
    'BulletinDispatch.status == "processing"' in bulletins
    and "Tentativa anterior foi interrompida" in bulletins,
)
check(
    "migration não cria duas tabelas",
    'op.create_table(\n        "bulletin_schedules"' in migration
    and 'op.create_table(\n        "bulletin_dispatches"' in migration,
)
check(
    "migration não encadeia 0041",
    'down_revision = "20260821_0041"' in migration,
)

# Scheduler persists and catches up after host sleep.
check(
    "scheduler não consulta next_run_at vencido",
    "BulletinSchedule.next_run_at <= current" in bulletins,
)
check(
    "scheduler não avança somente após aceite",
    'dispatch.status in {"provider_accepted", "delivered", "read"}'
    in bulletins,
)
check(
    "scheduler não roda em background",
    "asyncio.to_thread(run_due_bulletins_once)" in scheduler,
)
check(
    "main não inicia scheduler",
    "asyncio.create_task(bulletin_scheduler_loop())" in main,
)
check(
    "main não cancela scheduler no shutdown",
    "bulletin_task.cancel()" in main,
)
check(
    "cron externo seguro ausente",
    '@router.post("/process-due"' in router
    and "atlas_bulletin_cron_secret" in config
    and "hmac.compare_digest" in router,
)
check(
    "workflow GitHub não acorda o Render",
    'cron: "7 * * * *"' in workflow
    and "/bulletins/process-due" in workflow
    and "ATLAS_BULLETIN_CRON_SECRET" in workflow,
)

# Official WhatsApp provider contract.
check(
    "integração WhatsApp pode ligar sem configuração explícita",
    "atlas_whatsapp_enabled: bool = False" in config,
)
for field in (
    "atlas_whatsapp_access_token",
    "atlas_whatsapp_phone_number_id",
    "atlas_whatsapp_graph_version",
    "atlas_whatsapp_template_zootechnical",
    "atlas_whatsapp_template_operations",
    "atlas_whatsapp_template_financial",
    "atlas_whatsapp_webhook_verify_token",
    "atlas_whatsapp_app_secret",
):
    check(f"configuração ausente: {field}", field in config)
check(
    "provider usa método livre send_text na automação",
    "def send_text(" not in provider,
)
check(
    "provider não exige template",
    '"type": "template"' in provider
    and "template_for" in provider,
)
check(
    "provider não usa endpoint oficial Graph",
    "https://graph.facebook.com/" in provider,
)
check(
    "provider não exige opt-in na agenda",
    "schedule.whatsapp_opt_in_at is None" in bulletins,
)

# Delivery tracking is signed and does not lie about delivery.
check(
    "envio não separa aceite do provedor de entrega",
    'status="provider_accepted"' in bulletins
    and 'status="delivered"' not in bulletins,
)
check(
    "webhook não verifica HMAC SHA-256",
    "hmac.compare_digest" in webhook
    and "hashlib.sha256" in webhook,
)
check(
    "webhook não rastreia delivered/read",
    '"delivered"' in webhook and '"read"' in webhook,
)
check(
    "rota de webhook ausente",
    '"/whatsapp/webhook"' in router,
)
check(
    "webhook não verifica token de desafio",
    "hub_verify_token" in router
    and "atlas_whatsapp_webhook_verify_token" in router,
)

# API/UI.
check(
    "router de boletins não registrado",
    "bulletins.router" in main,
)
check(
    "readiness não comprova schema 0042",
    '@router.get("/readiness")' in router
    and "func.count(BulletinSchedule.id)" in router
    and '"schema_ready": True' in router,
)
for path in (
    '"/provider-status"',
    '"/schedules"',
    '"/preview/{bulletin_type}"',
    '"/dispatches"',
    '"/send-now/{bulletin_type}"',
):
    check(f"rota ausente {path}", path in router)
check(
    "Flutter não usa API oficial dos boletins",
    "'/bulletins/schedules'" in dart_service
    and "'/bulletins/provider-status'" in dart_service
    and "'/bulletins/preview/$bulletinType'" in dart_service,
)
check(
    "Central da Consultoria não inclui boletins",
    "AtlasMonthlyBulletinsCard(farm: widget.farm)" in screen,
)
for label in (
    "Boletins mensais no WhatsApp",
    "WhatsApp do produtor",
    "Produtor autorizou o recebimento",
    "Envio automático mensal",
):
    check(f"UI ausente: {label}", label in widget)
check(
    "UI usa DropdownButtonFormField(value:) depreciado",
    not re.search(
        r"DropdownButtonFormField<[^>]+>\(\s*\n\s*value:",
        widget,
        re.S,
    ),
)

# No mojibake in new package code.
for name in (
    "provider",
    "webhook",
    "bulletins",
    "router",
    "screen",
    "widget",
    "dart_service",
    "dart_model",
):
    text = texts.get(name, "")
    check(
        f"{name}: mojibake",
        not any(
            token in text
            for token in ("Ã§", "Ã£", "Ã©", "Ã³", "Ãª", "Ã¡", "Ã­", "Ãº", "Â")
        ),
    )

if errors:
    print(
        f"ATLAS POST-V21 PACKAGE 5: "
        f"{total_checks-len(errors)}/{total_checks} "
        f"({len(errors)} erro(s))"
    )
    for error in errors:
        print("-", error)
    sys.exit(1)

print(f"ATLAS POST-V21 PACKAGE 5: {total_checks}/{total_checks}")
