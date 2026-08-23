from __future__ import annotations

from datetime import datetime

import hmac
from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    Header,
    HTTPException,
    Query,
    UploadFile,
    status,
)
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..config import get_settings
from ..database import get_db
from ..innovation_models import AtlasIotDevice
from ..models import SecurityCameraEvent
from ..services.whatsapp_provider import MetaWhatsAppProvider
from ..services.security_camera_alerts import (
    attempt_security_alert,
    camera_alert_readiness,
    ingest_security_camera_event,
    update_camera_alert_configuration,
)


router = APIRouter(prefix="/security-camera", tags=["security-camera"])
settings = get_settings()




class SecurityCameraCreateRequest(BaseModel):
    name: str = Field(min_length=2, max_length=180)
    external_id: str = Field(min_length=3, max_length=180)

class SecurityCameraConfigurationRequest(BaseModel):
    recipient_whatsapp: str = ""
    whatsapp_opt_in_confirmed: bool = False
    security_alert_enabled: bool = False
    allowed_event_types: list[str] = Field(
        default_factory=lambda: ["person", "vehicle"],
    )
    cooldown_seconds: int = Field(default=60, ge=10, le=3600)


def _farm_allowed(principal: Principal, farm_id: str) -> None:
    if principal.membership.role in {
        "owner",
        "admin",
        "companyAdministrator",
    }:
        return
    if (
        principal.membership.farm_ids
        and farm_id not in set(principal.membership.farm_ids)
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Fazenda não autorizada.",
        )


def _camera_for_principal(
    db: Session,
    principal: Principal,
    device_id: str,
) -> AtlasIotDevice:
    device = db.get(AtlasIotDevice, device_id)
    if device is None or device.company_id != principal.company.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Câmera não encontrada.",
        )
    _farm_allowed(principal, device.farm_id)
    if device.device_type not in {
        "security_camera",
        "entrance_camera",
        "camera",
    }:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="O dispositivo informado não é uma câmera de segurança.",
        )
    return device


def _event_payload(event: SecurityCameraEvent) -> dict:
    return {
        "id": event.id,
        "farm_id": event.farm_id,
        "device_id": event.device_id,
        "event_external_id": event.event_external_id,
        "event_type": event.event_type,
        "confidence": event.confidence,
        "captured_at": event.captured_at.isoformat(),
        "received_at": event.received_at.isoformat(),
        "alert_status": event.alert_status,
        "provider_message_id": event.provider_message_id,
        "attempt_count": event.attempt_count,
        "sent_at": (
            event.sent_at.isoformat()
            if event.sent_at is not None
            else None
        ),
        "error_message": event.error_message,
    }


@router.get("/deployment-readiness")
def deployment_readiness(
    db: Session = Depends(get_db),
) -> dict:
    try:
        db.scalar(select(func.count(SecurityCameraEvent.id)))
    except SQLAlchemyError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Schema dos alertas da câmera ainda não está disponível.",
        ) from exc

    provider = MetaWhatsAppProvider()
    return {
        "status": "ready",
        "schema_ready": True,
        "iot_ingest_key_configured": bool(
            settings.atlas_iot_ingest_key.strip()
        ),
        "storage_backend": settings.atlas_attachment_backend,
        "whatsapp_security_alert_configured":
            provider.security_alert_configured,
    }


@router.post("/devices", status_code=status.HTTP_201_CREATED)
def create_camera(
    request: SecurityCameraCreateRequest,
    farm_id: str = Query(min_length=1),
    principal: Principal = Depends(require_permission("platform.manage")),
    db: Session = Depends(get_db),
) -> dict:
    _farm_allowed(principal, farm_id)
    external_id = request.external_id.strip()

    existing = db.scalar(
        select(AtlasIotDevice).where(
            AtlasIotDevice.external_id == external_id,
        )
    )
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "Essa identificação de câmera já está em uso. "
                "Use um código único."
            ),
        )

    device = AtlasIotDevice(
        company_id=principal.company.id,
        tenant_id=principal.company.tenant_id,
        farm_id=farm_id,
        name=request.name.strip(),
        device_type="entrance_camera",
        external_id=external_id,
        status="offline",
        configuration_json={
            "security_alert_enabled": False,
            "recipient_whatsapp": "",
            "whatsapp_opt_in_confirmed": False,
            "allowed_event_types": ["person", "vehicle"],
            "security_alert_cooldown_seconds": 60,
        },
    )
    db.add(device)
    db.commit()
    db.refresh(device)
    return camera_alert_readiness(device)


@router.get("/readiness")
def readiness(
    farm_id: str = Query(min_length=1),
    principal: Principal = Depends(require_permission("platform.read")),
    db: Session = Depends(get_db),
) -> dict:
    _farm_allowed(principal, farm_id)
    cameras = list(
        db.scalars(
            select(AtlasIotDevice).where(
                AtlasIotDevice.company_id == principal.company.id,
                AtlasIotDevice.farm_id == farm_id,
                AtlasIotDevice.device_type.in_(
                    ["security_camera", "entrance_camera", "camera"]
                ),
            )
        ).all()
    )
    return {
        "farm_id": farm_id,
        "cameras": [camera_alert_readiness(item) for item in cameras],
    }


@router.get("/events")
def list_events(
    farm_id: str = Query(min_length=1),
    limit: int = Query(default=50, ge=1, le=200),
    principal: Principal = Depends(require_permission("platform.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    _farm_allowed(principal, farm_id)
    items = list(
        db.scalars(
            select(SecurityCameraEvent)
            .where(
                SecurityCameraEvent.company_id == principal.company.id,
                SecurityCameraEvent.farm_id == farm_id,
            )
            .order_by(SecurityCameraEvent.captured_at.desc())
            .limit(limit)
        ).all()
    )
    return [_event_payload(item) for item in items]


@router.patch("/devices/{device_id}/alert-config")
def configure_alerts(
    device_id: str,
    request: SecurityCameraConfigurationRequest,
    principal: Principal = Depends(require_permission("platform.manage")),
    db: Session = Depends(get_db),
) -> dict:
    device = _camera_for_principal(db, principal, device_id)
    updated = update_camera_alert_configuration(
        db,
        device=device,
        recipient_whatsapp=request.recipient_whatsapp,
        whatsapp_opt_in_confirmed=request.whatsapp_opt_in_confirmed,
        security_alert_enabled=request.security_alert_enabled,
        allowed_event_types=request.allowed_event_types,
        cooldown_seconds=request.cooldown_seconds,
    )
    return camera_alert_readiness(updated)


@router.post("/events/{event_id}/retry")
def retry_event(
    event_id: str,
    principal: Principal = Depends(require_permission("platform.manage")),
    db: Session = Depends(get_db),
) -> dict:
    event = db.get(SecurityCameraEvent, event_id)
    if event is None or event.company_id != principal.company.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Evento da câmera não encontrado.",
        )
    _farm_allowed(principal, event.farm_id)

    device = _camera_for_principal(db, principal, event.device_id)
    updated = attempt_security_alert(db, event=event, device=device)
    return _event_payload(updated)


@router.post("/events/ingest", status_code=status.HTTP_201_CREATED)
async def ingest_event(
    device_external_id: str = Form(min_length=1),
    event_external_id: str = Form(min_length=1),
    event_type: str = Form(min_length=1),
    captured_at: datetime | None = Form(default=None),
    confidence: float | None = Form(default=None),
    image: UploadFile = File(...),
    x_atlas_iot_key: str = Header(default=""),
    db: Session = Depends(get_db),
) -> dict:
    expected_key = settings.atlas_iot_ingest_key
    if (
        not expected_key
        or not x_atlas_iot_key
        or not hmac.compare_digest(
            x_atlas_iot_key.encode("utf-8"),
            expected_key.encode("utf-8"),
        )
    ):
        await image.close()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Chave IoT inválida.",
        )

    matching_devices = list(
        db.scalars(
            select(AtlasIotDevice).where(
                AtlasIotDevice.external_id == device_external_id.strip()
            )
        ).all()
    )
    if len(matching_devices) > 1:
        await image.close()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "Identificação de câmera ambígua. "
                "Corrija os cadastros antes de aceitar eventos."
            ),
        )
    device = matching_devices[0] if matching_devices else None
    if device is None:
        await image.close()
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Câmera não cadastrada.",
        )
    if device.device_type not in {
        "security_camera",
        "entrance_camera",
        "camera",
    }:
        await image.close()
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="O dispositivo não está cadastrado como câmera.",
        )

    event = await ingest_security_camera_event(
        db,
        device=device,
        event_external_id=event_external_id,
        event_type=event_type,
        captured_at=captured_at,
        confidence=confidence,
        image=image,
        metadata={
            "ingest_contract": "atlas_security_camera_v1",
        },
    )
    return _event_payload(event)
