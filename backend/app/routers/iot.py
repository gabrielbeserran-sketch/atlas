
from __future__ import annotations

from datetime import datetime, timezone
import hmac

from fastapi import APIRouter, Depends, Header, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..config import get_settings
from ..database import get_db
from ..models import (
    IotAutomationRule,
    IotCommand,
    IotDevice,
    IotGateway,
    IotTelemetry,
    RealtimeEvent,
    new_id,
)
from ..schemas import (
    IotAutomationRuleCreateRequest,
    IotAutomationRuleResponse,
    IotCommandCreateRequest,
    IotCommandResponse,
    IotDeviceCreateRequest,
    IotDeviceResponse,
    IotGatewayCreateRequest,
    IotGatewayResponse,
    IotTelemetryIngestRequest,
    IotTelemetryResponse,
)
from ..services.iot_service import apply_rules
from ..services.realtime_hub import realtime_hub

router = APIRouter(prefix="/iot", tags=["iot"])
settings = get_settings()


def _farm_allowed(principal: Principal, farm_id: str) -> None:
    if principal.membership.role in {"owner", "admin", "companyAdministrator"}:
        return
    if principal.membership.farm_ids and farm_id not in set(principal.membership.farm_ids):
        raise HTTPException(status_code=403, detail="Fazenda não autorizada.")


@router.post("/gateways", response_model=IotGatewayResponse, status_code=201)
def create_gateway(
    payload: IotGatewayCreateRequest,
    principal: Principal = Depends(require_permission("iot.manage")),
    db: Session = Depends(get_db),
) -> IotGateway:
    _farm_allowed(principal, payload.farm_id)
    item = IotGateway(
        id=new_id("iot_gateway"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        status="offline",
        **payload.model_dump(),
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Gateway já cadastrado.") from exc
    db.refresh(item)
    return item


@router.get("/gateways", response_model=list[IotGatewayResponse])
def list_gateways(
    farm_id: str,
    principal: Principal = Depends(require_permission("iot.read")),
    db: Session = Depends(get_db),
) -> list[IotGateway]:
    _farm_allowed(principal, farm_id)
    return list(
        db.scalars(
            select(IotGateway)
            .where(
                IotGateway.company_id == principal.company.id,
                IotGateway.farm_id == farm_id,
            )
            .order_by(IotGateway.name)
        ).all()
    )


@router.post("/devices", response_model=IotDeviceResponse, status_code=201)
def create_device(
    payload: IotDeviceCreateRequest,
    principal: Principal = Depends(require_permission("iot.manage")),
    db: Session = Depends(get_db),
) -> IotDevice:
    _farm_allowed(principal, payload.farm_id)
    if payload.gateway_id:
        gateway = db.get(IotGateway, payload.gateway_id)
        if gateway is None or gateway.company_id != principal.company.id:
            raise HTTPException(status_code=404, detail="Gateway não encontrado.")

    item = IotDevice(
        id=new_id("iot_device"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        status="offline",
        installed_at=datetime.now(timezone.utc),
        **payload.model_dump(),
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Dispositivo já cadastrado.") from exc
    db.refresh(item)
    return item


@router.get("/devices", response_model=list[IotDeviceResponse])
def list_devices(
    farm_id: str,
    device_type: str | None = None,
    status_filter: str | None = Query(default=None, alias="status"),
    principal: Principal = Depends(require_permission("iot.read")),
    db: Session = Depends(get_db),
) -> list[IotDevice]:
    _farm_allowed(principal, farm_id)
    query = select(IotDevice).where(
        IotDevice.company_id == principal.company.id,
        IotDevice.farm_id == farm_id,
    )
    if device_type:
        query = query.where(IotDevice.device_type == device_type)
    if status_filter:
        query = query.where(IotDevice.status == status_filter)
    return list(db.scalars(query.order_by(IotDevice.name)).all())


@router.post("/telemetry/ingest", response_model=IotTelemetryResponse, status_code=201)
async def ingest_telemetry(
    payload: IotTelemetryIngestRequest,
    x_atlas_iot_key: str = Header(default=""),
    db: Session = Depends(get_db),
) -> IotTelemetry:
    expected_key = settings.atlas_iot_ingest_key
    if (
        not expected_key
        or not x_atlas_iot_key
        or not hmac.compare_digest(
            x_atlas_iot_key.encode("utf-8"),
            expected_key.encode("utf-8"),
        )
    ):
        raise HTTPException(status_code=401, detail="Chave IoT inválida.")

    device = db.scalar(
        select(IotDevice).where(
            IotDevice.external_id == payload.device_external_id
        )
    )
    if device is None:
        raise HTTPException(status_code=404, detail="Dispositivo não encontrado.")

    now = datetime.now(timezone.utc)
    item = IotTelemetry(
        id=new_id("iot_telemetry"),
        tenant_id=device.tenant_id,
        company_id=device.company_id,
        farm_id=device.farm_id,
        device_id=device.id,
        metric_key=payload.metric_key,
        value=payload.value,
        unit=payload.unit,
        quality=payload.quality,
        payload=payload.payload,
        recorded_at=payload.recorded_at or now,
        received_at=now,
    )
    db.add(item)

    device.status = "online"
    device.last_seen_at = now
    if payload.battery_percent is not None:
        device.battery_percent = payload.battery_percent
    if payload.signal_strength is not None:
        device.signal_strength = payload.signal_strength

    notifications = apply_rules(db, telemetry=item, device=device)

    event = RealtimeEvent(
        id=new_id("realtime_event"),
        tenant_id=device.tenant_id,
        company_id=device.company_id,
        farm_id=device.farm_id,
        topic="iot.telemetry",
        event_type="telemetry.ingested",
        entity_type="iot_device",
        entity_id=device.id,
        payload={
            "device_id": device.id,
            "device_external_id": device.external_id,
            "metric_key": item.metric_key,
            "value": item.value,
            "unit": item.unit,
            "quality": item.quality,
            "recorded_at": item.recorded_at.isoformat(),
        },
        correlation_id=item.id,
        source="iot_gateway",
    )
    db.add(event)
    db.commit()
    db.refresh(item)

    await realtime_hub.publish(
        f"company:{device.company_id}",
        {
            "id": event.id,
            "topic": event.topic,
            "event_type": event.event_type,
            "farm_id": event.farm_id,
            "entity_type": event.entity_type,
            "entity_id": event.entity_id,
            "payload": event.payload,
            "occurred_at": event.occurred_at.isoformat(),
        },
    )

    for notification in notifications:
        await realtime_hub.publish(
            f"company:{device.company_id}",
            {
                "type": "notification",
                "notification": {
                    "id": notification.id,
                    "category": notification.category,
                    "severity": notification.severity,
                    "title": notification.title,
                    "message": notification.message,
                    "farm_id": notification.farm_id,
                    "payload": notification.payload,
                    "created_at": notification.created_at.isoformat(),
                },
            },
        )

    return item


@router.get("/telemetry", response_model=list[IotTelemetryResponse])
def telemetry(
    device_id: str,
    metric_key: str | None = None,
    limit: int = Query(default=500, ge=1, le=5000),
    principal: Principal = Depends(require_permission("iot.read")),
    db: Session = Depends(get_db),
) -> list[IotTelemetry]:
    device = db.get(IotDevice, device_id)
    if device is None or device.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Dispositivo não encontrado.")
    _farm_allowed(principal, device.farm_id)

    query = select(IotTelemetry).where(IotTelemetry.device_id == device_id)
    if metric_key:
        query = query.where(IotTelemetry.metric_key == metric_key)
    return list(
        db.scalars(
            query.order_by(IotTelemetry.recorded_at.desc()).limit(limit)
        ).all()
    )


@router.post(
    "/devices/{device_id}/commands",
    response_model=IotCommandResponse,
    status_code=201,
)
async def create_command(
    device_id: str,
    payload: IotCommandCreateRequest,
    principal: Principal = Depends(require_permission("iot.command")),
    db: Session = Depends(get_db),
) -> IotCommand:
    device = db.get(IotDevice, device_id)
    if device is None or device.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Dispositivo não encontrado.")
    _farm_allowed(principal, device.farm_id)

    command = IotCommand(
        id=new_id("iot_command"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=device.farm_id,
        device_id=device.id,
        command_type=payload.command_type,
        payload=payload.payload,
        requested_by=principal.user.id,
    )
    db.add(command)
    db.commit()
    db.refresh(command)

    await realtime_hub.publish(
        f"company:{principal.company.id}",
        {
            "type": "iot_command",
            "command": {
                "id": command.id,
                "device_id": device.id,
                "device_external_id": device.external_id,
                "command_type": command.command_type,
                "payload": command.payload,
            },
        },
    )

    return command


@router.get("/devices/{device_id}/commands", response_model=list[IotCommandResponse])
def list_commands(
    device_id: str,
    principal: Principal = Depends(require_permission("iot.read")),
    db: Session = Depends(get_db),
) -> list[IotCommand]:
    device = db.get(IotDevice, device_id)
    if device is None or device.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Dispositivo não encontrado.")
    _farm_allowed(principal, device.farm_id)
    return list(
        db.scalars(
            select(IotCommand)
            .where(IotCommand.device_id == device_id)
            .order_by(IotCommand.requested_at.desc())
        ).all()
    )


@router.post(
    "/automation-rules",
    response_model=IotAutomationRuleResponse,
    status_code=201,
)
def create_automation_rule(
    payload: IotAutomationRuleCreateRequest,
    principal: Principal = Depends(require_permission("iot.manage")),
    db: Session = Depends(get_db),
) -> IotAutomationRule:
    _farm_allowed(principal, payload.farm_id)
    item = IotAutomationRule(
        id=new_id("iot_rule"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.get(
    "/automation-rules",
    response_model=list[IotAutomationRuleResponse],
)
def automation_rules(
    farm_id: str,
    principal: Principal = Depends(require_permission("iot.read")),
    db: Session = Depends(get_db),
) -> list[IotAutomationRule]:
    _farm_allowed(principal, farm_id)
    return list(
        db.scalars(
            select(IotAutomationRule)
            .where(
                IotAutomationRule.company_id == principal.company.id,
                IotAutomationRule.farm_id == farm_id,
            )
            .order_by(IotAutomationRule.name)
        ).all()
    )


@router.get("/dashboard")
def iot_dashboard(
    farm_id: str,
    principal: Principal = Depends(require_permission("iot.read")),
    db: Session = Depends(get_db),
) -> dict:
    _farm_allowed(principal, farm_id)
    devices = list(
        db.scalars(
            select(IotDevice).where(
                IotDevice.company_id == principal.company.id,
                IotDevice.farm_id == farm_id,
            )
        ).all()
    )
    return {
        "farm_id": farm_id,
        "total_devices": len(devices),
        "online_devices": sum(1 for item in devices if item.status == "online"),
        "offline_devices": sum(1 for item in devices if item.status != "online"),
        "low_battery_devices": sum(
            1
            for item in devices
            if item.battery_percent is not None and item.battery_percent <= 20
        ),
        "device_types": {
            device_type: sum(
                1 for item in devices if item.device_type == device_type
            )
            for device_type in sorted({item.device_type for item in devices})
        },
    }
