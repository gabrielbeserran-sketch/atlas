from __future__ import annotations

from datetime import datetime, timezone
from zoneinfo import ZoneInfo
from pathlib import Path

from fastapi import HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..innovation_models import AtlasIotDevice
from ..models import SecurityCameraEvent, new_id
from .animal_media_storage import read_file_bytes, save_upload
from .whatsapp_provider import (
    MetaWhatsAppProvider,
    WhatsAppProviderError,
)


_ALLOWED_EVENT_TYPES = {"person", "vehicle"}
_EVENT_LABELS = {
    "person": "Pessoa detectada",
    "vehicle": "Veículo detectado",
}


def _digits(value: object) -> str:
    return "".join(ch for ch in str(value or "") if ch.isdigit())


def _camera_configuration(device: AtlasIotDevice) -> dict:
    value = device.configuration_json
    return value if isinstance(value, dict) else {}


def camera_alert_readiness(device: AtlasIotDevice) -> dict:
    config = _camera_configuration(device)
    recipient = _digits(config.get("recipient_whatsapp"))
    allowed = config.get("allowed_event_types", ["person", "vehicle"])
    if not isinstance(allowed, list):
        allowed = ["person", "vehicle"]

    provider = MetaWhatsAppProvider()
    return {
        "device_id": device.id,
        "device_external_id": device.external_id,
        "device_name": device.name,
        "device_type": device.device_type,
        "enabled": config.get("security_alert_enabled") is True,
        "recipient_whatsapp": recipient,
        "whatsapp_opt_in_confirmed":
            config.get("whatsapp_opt_in_confirmed") is True,
        "allowed_event_types": [
            item for item in allowed if item in _ALLOWED_EVENT_TYPES
        ],
        "cooldown_seconds": int(
            config.get("security_alert_cooldown_seconds", 60) or 60
        ),
        "provider_ready": provider.security_alert_configured,
        "ready": bool(
            config.get("security_alert_enabled") is True
            and len(recipient) >= 10
            and config.get("whatsapp_opt_in_confirmed") is True
            and provider.security_alert_configured
        ),
    }


def update_camera_alert_configuration(
    db: Session,
    *,
    device: AtlasIotDevice,
    recipient_whatsapp: str,
    whatsapp_opt_in_confirmed: bool,
    security_alert_enabled: bool,
    allowed_event_types: list[str],
    cooldown_seconds: int,
) -> AtlasIotDevice:
    recipient = _digits(recipient_whatsapp)
    if recipient and not (10 <= len(recipient) <= 15):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="WhatsApp do produtor inválido.",
        )

    normalized_types = sorted(
        {
            item.strip().lower()
            for item in allowed_event_types
            if item.strip().lower() in _ALLOWED_EVENT_TYPES
        }
    )
    if not normalized_types:
        normalized_types = ["person", "vehicle"]

    if cooldown_seconds < 10 or cooldown_seconds > 3600:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Intervalo entre alertas deve ficar entre 10 e 3600 segundos.",
        )

    if security_alert_enabled:
        if not whatsapp_opt_in_confirmed:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=(
                    "Confirme a autorização do produtor antes de ativar "
                    "alertas automáticos no WhatsApp."
                ),
            )
        if not recipient:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Informe o WhatsApp do produtor.",
            )

    current = _camera_configuration(device)
    device.configuration_json = {
        **current,
        "security_alert_enabled": security_alert_enabled,
        "recipient_whatsapp": recipient,
        "whatsapp_opt_in_confirmed": whatsapp_opt_in_confirmed,
        "allowed_event_types": normalized_types,
        "security_alert_cooldown_seconds": cooldown_seconds,
    }
    db.add(device)
    db.commit()
    db.refresh(device)
    return device


async def ingest_security_camera_event(
    db: Session,
    *,
    device: AtlasIotDevice,
    event_external_id: str,
    event_type: str,
    captured_at: datetime | None,
    confidence: float | None,
    image: UploadFile,
    metadata: dict | None = None,
) -> SecurityCameraEvent:
    normalized_event_id = event_external_id.strip()
    if not normalized_event_id:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="event_external_id é obrigatório.",
        )

    normalized_type = event_type.strip().lower()
    if normalized_type not in _ALLOWED_EVENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="event_type deve ser person ou vehicle.",
        )

    if confidence is not None and not 0 <= confidence <= 1:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="confidence deve estar entre 0 e 1.",
        )

    content_type = (image.content_type or "").lower().strip()
    if content_type not in {"image/jpeg", "image/png", "image/webp"}:
        await image.close()
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="O alerta da entrada aceita somente JPEG, PNG ou WebP.",
        )

    existing = db.scalar(
        select(SecurityCameraEvent).where(
            SecurityCameraEvent.device_id == device.id,
            SecurityCameraEvent.event_external_id == normalized_event_id,
        )
    )
    if existing is not None:
        await image.close()
        if existing.alert_status not in {
            "provider_accepted",
            "delivered",
            "read",
        }:
            attempt_security_alert(db, event=existing, device=device)
        return existing

    now = datetime.now(timezone.utc)
    event_captured_at = captured_at or now
    if event_captured_at.tzinfo is None:
        event_captured_at = event_captured_at.replace(tzinfo=timezone.utc)
    else:
        event_captured_at = event_captured_at.astimezone(timezone.utc)

    event = SecurityCameraEvent(
        id=new_id("security_camera_event"),
        tenant_id=device.tenant_id,
        company_id=device.company_id,
        farm_id=device.farm_id,
        device_id=device.id,
        event_external_id=normalized_event_id[:180],
        event_type=normalized_type,
        confidence=confidence,
        captured_at=event_captured_at,
        received_at=now,
        recipient_whatsapp=_digits(
            _camera_configuration(device).get("recipient_whatsapp")
        ),
        alert_status="pending",
        metadata_json=metadata or {},
    )

    suffix = {
        "image/jpeg": ".jpg",
        "image/png": ".png",
        "image/webp": ".webp",
    }[content_type]
    image.filename = f"entrada{suffix}"
    destination = (
        Path("security-camera")
        / device.tenant_id
        / device.company_id
        / device.farm_id
        / device.id
        / f"{event.id}{suffix}"
    )

    file_size, sha256 = await save_upload(image, destination)
    event.storage_key = destination.as_posix()
    event.file_size = file_size
    event.sha256 = sha256

    db.add(event)
    db.commit()
    db.refresh(event)

    attempt_security_alert(db, event=event, device=device)
    return event


def attempt_security_alert(
    db: Session,
    *,
    event: SecurityCameraEvent,
    device: AtlasIotDevice,
) -> SecurityCameraEvent:
    if event.alert_status in {"provider_accepted", "delivered", "read"}:
        return event

    config = _camera_configuration(device)
    allowed = config.get("allowed_event_types", ["person", "vehicle"])
    if not isinstance(allowed, list):
        allowed = ["person", "vehicle"]

    if config.get("security_alert_enabled") is not True:
        event.alert_status = "blocked_configuration"
        event.error_message = "Alertas da câmera estão desativados."
        db.commit()
        return event

    if event.event_type not in set(allowed):
        event.alert_status = "ignored_event_type"
        event.error_message = (
            f"Evento {event.event_type} não está habilitado para alerta."
        )
        db.commit()
        return event

    cooldown_seconds = int(
        config.get("security_alert_cooldown_seconds", 60) or 60
    )
    previous = db.scalar(
        select(SecurityCameraEvent)
        .where(
            SecurityCameraEvent.device_id == device.id,
            SecurityCameraEvent.id != event.id,
            SecurityCameraEvent.event_type == event.event_type,
            SecurityCameraEvent.alert_status.in_(
                ["provider_accepted", "delivered", "read"]
            ),
        )
        .order_by(SecurityCameraEvent.captured_at.desc())
        .limit(1)
    )
    if previous is not None:
        elapsed = (
            event.captured_at - previous.captured_at
        ).total_seconds()
        if 0 <= elapsed < cooldown_seconds:
            event.alert_status = "suppressed_cooldown"
            event.error_message = (
                "Evento registrado, mas o alerta foi suprimido para evitar "
                "mensagens repetidas em sequência."
            )
            db.commit()
            return event

    recipient = _digits(config.get("recipient_whatsapp"))
    if not recipient or config.get("whatsapp_opt_in_confirmed") is not True:
        event.alert_status = "blocked_opt_in"
        event.error_message = (
            "WhatsApp do produtor ou autorização de recebimento ausente."
        )
        db.commit()
        return event

    provider = MetaWhatsAppProvider()
    if not provider.security_alert_configured:
        event.alert_status = "blocked_provider"
        event.error_message = (
            "Template/credenciais do alerta de segurança não configurados."
        )
        db.commit()
        return event

    event.attempt_count += 1
    event.last_attempt_at = datetime.now(timezone.utc)
    event.recipient_whatsapp = recipient

    try:
        image_bytes = read_file_bytes(event.storage_key)
        suffix = Path(event.storage_key).suffix.lower()
        content_type = {
            ".jpg": "image/jpeg",
            ".jpeg": "image/jpeg",
            ".png": "image/png",
            ".webp": "image/webp",
        }.get(suffix, "image/jpeg")

        result = provider.send_security_alert(
            recipient=recipient,
            camera_name=device.name,
            event_label=_EVENT_LABELS[event.event_type],
            captured_at_label=event.captured_at.astimezone(
                ZoneInfo("America/Sao_Paulo")
            ).strftime("%d/%m/%Y %H:%M"),
            image_bytes=image_bytes,
            content_type=content_type,
            filename=f"entrada{suffix or '.jpg'}",
        )
    except (WhatsAppProviderError, HTTPException, OSError) as exc:
        event.alert_status = "failed"
        event.error_message = str(exc)[:2000]
        db.commit()
        db.refresh(event)
        return event

    event.provider_message_id = result.message_id
    event.alert_status = "provider_accepted"
    event.sent_at = datetime.now(timezone.utc)
    event.error_message = ""
    db.commit()
    db.refresh(event)
    return event
