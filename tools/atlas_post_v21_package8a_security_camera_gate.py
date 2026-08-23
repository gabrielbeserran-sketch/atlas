from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

paths = {
    "config": ROOT / "backend/app/config.py",
    "model": ROOT / "backend/app/models/legacy.py",
    "migration": ROOT / "backend/alembic/versions/20260823_0043_security_camera_alerts.py",
    "provider": ROOT / "backend/app/services/whatsapp_provider.py",
    "webhook": ROOT / "backend/app/services/whatsapp_webhook.py",
    "alerts": ROOT / "backend/app/services/security_camera_alerts.py",
    "router": ROOT / "backend/app/routers/security_camera.py",
    "main": ROOT / "backend/app/main.py",
    "bulletins": ROOT / "backend/app/services/monthly_bulletins.py",
    "bulletin_router": ROOT / "backend/app/routers/bulletins.py",
    "flutter_service": ROOT / "lib/features/security_camera/data/services/atlas_security_camera_service.dart",
    "flutter_model": ROOT / "lib/features/security_camera/domain/models/atlas_security_camera_data.dart",
    "flutter_widget": ROOT / "lib/features/security_camera/presentation/widgets/atlas_security_camera_card.dart",
    "precision": ROOT / "lib/features/precision_hub/presentation/screens/atlas_precision_hub_screen.dart",
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

config = texts.get("config", "")
model = texts.get("model", "")
migration = texts.get("migration", "")
provider = texts.get("provider", "")
webhook = texts.get("webhook", "")
alerts = texts.get("alerts", "")
router = texts.get("router", "")
main = texts.get("main", "")
bulletins = texts.get("bulletins", "")
bulletin_router = texts.get("bulletin_router", "")
flutter_service = texts.get("flutter_service", "")
flutter_model = texts.get("flutter_model", "")
flutter_widget = texts.get("flutter_widget", "")
precision = texts.get("precision", "")

# The original request for three separate bulletins already exists.
for bulletin_type in ("zootechnical", "operations", "financial"):
    check(
        f"boletim existente foi perdido: {bulletin_type}",
        bulletin_type in bulletins and bulletin_type in bulletin_router,
    )
check(
    "8A duplicou tabela de boletins",
    "bulletin_schedules" not in migration
    and "bulletin_dispatches" not in migration,
)

# Consolidated IoT ownership: never regress to legacy iot_devices.
check(
    "evento de câmera não usa Atlas IoT v2",
    'ForeignKey("atlas_iot_devices_v2.id"' in model,
)
check(
    "migration aponta para IoT legado",
    '["atlas_iot_devices_v2.id"]' in migration
    and '["iot_devices.id"]' not in migration,
)
check(
    "router usa IoT legado",
    "AtlasIotDevice" in router and "IotDevice" not in router.replace("AtlasIotDevice", ""),
)
check(
    "serviço usa IoT legado",
    "AtlasIotDevice" in alerts and "IotDevice" not in alerts.replace("AtlasIotDevice", ""),
)

# Secure ingest.
check("ingest sem chave IoT", "x_atlas_iot_key" in router)
check("ingest não usa compare_digest", "hmac.compare_digest" in router)
check(
    "ingest aceita evento sem identificação",
    "event_external_id" in router and "event_external_id é obrigatório" in alerts,
)
check(
    "ingest aceita qualquer tipo",
    '"person", "vehicle"' in alerts and "event_type deve ser person ou vehicle" in alerts,
)
check(
    "imagem sem validação MIME",
    "image/jpeg" in alerts and "image/png" in alerts and "image/webp" in alerts,
)
check(
    "imagem não usa Storage oficial",
    "save_upload(" in alerts and "read_file_bytes(" in alerts,
)

# Idempotency and anti-spam.
check(
    "evento sem unique device/external",
    "uq_security_camera_event_device_external" in model
    and "uq_security_camera_event_device_external" in migration,
)
check(
    "retry de evento duplicado ausente",
    "if existing is not None" in alerts
    and "attempt_security_alert" in alerts,
)
check(
    "anti-spam de alertas ausente",
    "security_alert_cooldown_seconds" in alerts
    and "suppressed_cooldown" in alerts,
)
check(
    "cooldown sem limite",
    "cooldown_seconds < 10" in alerts
    and "cooldown_seconds > 3600" in alerts,
)

# WhatsApp must use an approved template with image media, not free-form text.
check(
    "template de segurança não configurável",
    "atlas_whatsapp_template_security_alert" in config,
)
check(
    "provider não separa readiness de segurança",
    "security_alert_configured" in provider,
)
check(
    "foto não é enviada como mídia",
    'self._graph_url("media")' in provider
    and '"type": "image"' in provider,
)
check(
    "alerta não usa template",
    "send_security_alert(" in provider
    and '"type": "template"' in provider
    and "atlas_whatsapp_template_security_alert" in provider,
)
check(
    "provider simula confirmação",
    'message_id = first.get("id")' in provider
    and "WhatsApp Business não retornou identificador do alerta" in provider,
)

# Opt-in and config safeguards.
check(
    "config permite habilitar sem opt-in",
    "Confirme a autorização do produtor" in alerts,
)
check(
    "config não valida telefone",
    "WhatsApp do produtor inválido" in alerts,
)
check(
    "eventos ignoram allowed_event_types",
    "ignored_event_type" in alerts,
)
check(
    "provider ausente é tratado como sucesso",
    "blocked_provider" in alerts,
)

# Delivery tracking extended to camera without breaking bulletins.
check(
    "webhook perdeu boletins",
    "BulletinDispatch" in webhook,
)
check(
    "webhook não acompanha câmera",
    "SecurityCameraEvent" in webhook
    and "alert_status" in webhook,
)

# App surface.
for token in (
    "/security-camera/readiness",
    "/security-camera/events",
    "/security-camera/devices",
    "/alert-config",
):
    check(f"Flutter sem contrato {token}", token in flutter_service)
check(
    "Precision Hub não mostra segurança da entrada",
    "AtlasSecurityCameraCard(" in precision,
)
check(
    "card da câmera acoplado ao FarmData",
    "features/farm/domain/models/farm_data.dart" not in flutter_widget
    and "final FarmData farm;" not in flutter_widget,
)
check(
    "Precision Hub não passa identidade primitiva da fazenda",
    "farmId: farm.id," in precision
    and "farmName: farm.name," not in precision,
)
check(
    "UI não explica hardware real",
    "não simula detecção sem hardware" in flutter_widget,
)
check(
    "UI não possui pessoa/veículo",
    "Alertar quando detectar pessoa" in flutter_widget
    and "Alertar quando detectar veículo" in flutter_widget,
)
check(
    "UI não possui opt-in",
    "Produtor autorizou os alertas no WhatsApp" in flutter_widget,
)
check(
    "UI não possui anti-spam",
    "Intervalo mínimo entre alertas iguais" in flutter_widget,
)

# Deployment contract.
check(
    "migration 0043 não encadeia 0042",
    'down_revision = "20260822_0042"' in migration,
)
check(
    "router não registrado",
    "security_camera.router" in main,
)
check(
    "readiness de deploy ausente",
    "deployment-readiness" in router
    and "schema_ready" in router,
)

# No camera credentials are stored in Flutter or returned by readiness.
for forbidden in (
    "rtsp_password",
    "camera_password",
    "ATLAS_IOT_INGEST_KEY",
    "atlas_iot_ingest_key",
):
    check(
        f"segredo exposto no Flutter: {forbidden}",
        forbidden not in flutter_service
        and forbidden not in flutter_widget
        and forbidden not in flutter_model,
    )

# Production hygiene.
for name, text in texts.items():
    check(
        f"{name}: mojibake",
        not any(token in text for token in ("Ã§", "Ã£", "Ã©", "Ã³", "Â")),
    )

if errors:
    print(f"ATLAS POS-V21 PACOTE 8A CAMERA: FAIL ({len(errors)} erro(s))")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("ATLAS POS-V21 PACOTE 8A CAMERA: APROVADO")
print("Boletins existentes reutilizados: zootécnico, operação/equipe, financeiro")
print("IoT oficial: AtlasIotDevice v2 / Precision Hub")
print("Evento: pessoa/veículo + foto + idempotência + anti-spam")
print("WhatsApp: template oficial com cabeçalho de imagem")
print("Envio fictício quando provider ausente: 0")
