from __future__ import annotations

from typing import Literal

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, Response, status
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from ..authz import Principal, require_farm_scope, require_permission
from ..config import get_settings
from ..database import get_db
from ..models import BulletinDispatch, BulletinSchedule, Farm
from ..services.monthly_bulletins import (
    BULLETIN_LABELS,
    BulletinConfigurationError,
    attempt_dispatch,
    ensure_default_schedules,
    generate_bulletin,
    get_or_create_dispatch,
    previous_month_period,
    process_due_schedules,
    update_schedule,
)
from ..services.whatsapp_provider import MetaWhatsAppProvider
from ..services.whatsapp_webhook import apply_status_webhook, verify_signature


router = APIRouter(prefix="/bulletins", tags=["bulletins"])
settings = get_settings()
BulletinType = Literal["zootechnical", "operations", "financial"]


class BulletinScheduleUpdateRequest(BaseModel):
    recipient_whatsapp: str | None = None
    whatsapp_opt_in_confirmed: bool | None = None
    enabled: bool | None = None
    day_of_month: int | None = Field(default=None, ge=1, le=28)
    hour: int | None = Field(default=None, ge=0, le=23)
    minute: int | None = Field(default=None, ge=0, le=59)
    timezone_name: str | None = None


def _farm_for_principal(
    db: Session,
    principal: Principal,
    farm_id: str,
) -> Farm:
    farm = db.scalar(
        select(Farm).where(
            Farm.id == farm_id,
            Farm.company_id == principal.company.id,
            Farm.tenant_id == principal.company.tenant_id,
            Farm.active.is_(True),
        )
    )
    if farm is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Fazenda ativa não encontrada.",
        )
    require_farm_scope(principal, farm.id)
    return farm


def _schedule_payload(schedule: BulletinSchedule) -> dict:
    return {
        "id": schedule.id,
        "farm_id": schedule.farm_id,
        "bulletin_type": schedule.bulletin_type,
        "label": BULLETIN_LABELS.get(
            schedule.bulletin_type,
            schedule.bulletin_type,
        ),
        "recipient_whatsapp": schedule.recipient_whatsapp,
        "whatsapp_opt_in_confirmed": schedule.whatsapp_opt_in_at is not None,
        "whatsapp_opt_in_at": (
            schedule.whatsapp_opt_in_at.isoformat()
            if schedule.whatsapp_opt_in_at is not None
            else None
        ),
        "enabled": schedule.enabled,
        "day_of_month": schedule.day_of_month,
        "hour": schedule.hour,
        "minute": schedule.minute,
        "timezone_name": schedule.timezone_name,
        "last_run_at": (
            schedule.last_run_at.isoformat()
            if schedule.last_run_at is not None
            else None
        ),
        "next_run_at": (
            schedule.next_run_at.isoformat()
            if schedule.next_run_at is not None
            else None
        ),
    }


def _dispatch_payload(dispatch: BulletinDispatch) -> dict:
    return {
        "id": dispatch.id,
        "farm_id": dispatch.farm_id,
        "bulletin_type": dispatch.bulletin_type,
        "label": BULLETIN_LABELS.get(
            dispatch.bulletin_type,
            dispatch.bulletin_type,
        ),
        "recipient_whatsapp": dispatch.recipient_whatsapp,
        "period_start": dispatch.period_start.isoformat(),
        "period_end": dispatch.period_end.isoformat(),
        "content": dispatch.content,
        "status": dispatch.status,
        "provider": dispatch.provider,
        "provider_message_id": dispatch.provider_message_id,
        "attempt_count": dispatch.attempt_count,
        "scheduled_for": (
            dispatch.scheduled_for.isoformat()
            if dispatch.scheduled_for is not None
            else None
        ),
        "sent_at": (
            dispatch.sent_at.isoformat()
            if dispatch.sent_at is not None
            else None
        ),
        "error_message": dispatch.error_message,
        "created_at": dispatch.created_at.isoformat(),
    }




@router.get("/whatsapp/webhook", include_in_schema=False)
def verify_whatsapp_webhook(
    hub_mode: str = Query(alias="hub.mode"),
    hub_verify_token: str = Query(alias="hub.verify_token"),
    hub_challenge: str = Query(alias="hub.challenge"),
) -> Response:
    if (
        hub_mode != "subscribe"
        or not settings.atlas_whatsapp_webhook_verify_token.strip()
        or hub_verify_token
        != settings.atlas_whatsapp_webhook_verify_token.strip()
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Verificação do webhook recusada.",
        )
    return Response(content=hub_challenge, media_type="text/plain")


@router.post("/whatsapp/webhook", include_in_schema=False)
async def receive_whatsapp_webhook(
    request: Request,
    db: Session = Depends(get_db),
) -> dict:
    raw = await request.body()
    signature = request.headers.get("X-Hub-Signature-256", "")
    if not verify_signature(raw, signature):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Assinatura do webhook inválida.",
        )

    try:
        payload = await request.json()
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payload de webhook inválido.",
        ) from exc
    if not isinstance(payload, dict):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payload de webhook inválido.",
        )
    return apply_status_webhook(db, payload)






@router.post("/process-due", include_in_schema=False)
def process_due_from_cron(
    x_atlas_bulletin_cron: str = Header(default=""),
    db: Session = Depends(get_db),
) -> dict:
    expected = settings.atlas_bulletin_cron_secret.strip()
    if not expected:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Cron externo dos boletins não configurado.",
        )

    import hmac

    if not hmac.compare_digest(
        x_atlas_bulletin_cron.strip(),
        expected,
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Segredo do cron inválido.",
        )

    return process_due_schedules(db)


@router.get("/readiness")
def bulletin_readiness(
    db: Session = Depends(get_db),
) -> dict:
    try:
        db.scalar(select(func.count(BulletinSchedule.id)))
    except SQLAlchemyError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Schema dos boletins ainda não está disponível.",
        ) from exc

    provider = MetaWhatsAppProvider()
    return {
        "status": "ready",
        "schema_ready": True,
        "scheduler_enabled": settings.atlas_bulletin_scheduler_enabled,
        "whatsapp_configured": provider.configured,
    }


@router.get("/provider-status")
def provider_status(
    principal: Principal = Depends(require_permission("reports.read")),
) -> dict:
    provider = MetaWhatsAppProvider()
    return {
        "provider": "meta_cloud",
        "automatic_delivery_enabled": provider.configured,
        "scheduler_enabled": settings.atlas_bulletin_scheduler_enabled,
        "configuration_required": not provider.configured,
        "delivery_tracking_enabled": bool(
            provider.configured
            and settings.atlas_whatsapp_webhook_verify_token.strip()
            and settings.atlas_whatsapp_app_secret.strip()
        ),
    }


@router.get("/schedules")
def list_schedules(
    farm_id: str = Query(min_length=1),
    principal: Principal = Depends(require_permission("reports.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    farm = _farm_for_principal(db, principal, farm_id)
    schedules = ensure_default_schedules(
        db,
        tenant_id=farm.tenant_id,
        company_id=farm.company_id,
        farm_id=farm.id,
    )
    return [_schedule_payload(item) for item in schedules]


@router.patch("/schedules/{bulletin_type}")
def patch_schedule(
    bulletin_type: BulletinType,
    request: BulletinScheduleUpdateRequest,
    farm_id: str = Query(min_length=1),
    principal: Principal = Depends(require_permission("farms.update")),
    db: Session = Depends(get_db),
) -> dict:
    farm = _farm_for_principal(db, principal, farm_id)
    ensure_default_schedules(
        db,
        tenant_id=farm.tenant_id,
        company_id=farm.company_id,
        farm_id=farm.id,
    )
    schedule = db.scalar(
        select(BulletinSchedule).where(
            BulletinSchedule.company_id == farm.company_id,
            BulletinSchedule.farm_id == farm.id,
            BulletinSchedule.bulletin_type == bulletin_type,
        )
    )
    if schedule is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Agenda do boletim não encontrada.",
        )

    try:
        updated = update_schedule(
            db,
            schedule,
            recipient_whatsapp=request.recipient_whatsapp,
            whatsapp_opt_in_confirmed=request.whatsapp_opt_in_confirmed,
            enabled=request.enabled,
            day_of_month=request.day_of_month,
            hour=request.hour,
            minute=request.minute,
            timezone_name=request.timezone_name,
        )
    except BulletinConfigurationError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(exc),
        ) from exc
    return _schedule_payload(updated)


@router.get("/preview/{bulletin_type}")
def preview_bulletin(
    bulletin_type: BulletinType,
    farm_id: str = Query(min_length=1),
    principal: Principal = Depends(require_permission("reports.read")),
    db: Session = Depends(get_db),
) -> dict:
    farm = _farm_for_principal(db, principal, farm_id)
    start, end = previous_month_period()
    try:
        content = generate_bulletin(
            db,
            company_id=farm.company_id,
            farm_id=farm.id,
            bulletin_type=bulletin_type,
            period_start=start,
            period_end=end,
        )
    except BulletinConfigurationError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(exc),
        ) from exc

    return {
        "farm_id": farm.id,
        "bulletin_type": bulletin_type,
        "label": BULLETIN_LABELS[bulletin_type],
        "period_start": start.isoformat(),
        "period_end": end.isoformat(),
        "content": content,
    }


@router.get("/dispatches")
def list_dispatches(
    farm_id: str = Query(min_length=1),
    limit: int = Query(default=20, ge=1, le=100),
    principal: Principal = Depends(require_permission("reports.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    farm = _farm_for_principal(db, principal, farm_id)
    items = list(
        db.scalars(
            select(BulletinDispatch)
            .where(
                BulletinDispatch.company_id == farm.company_id,
                BulletinDispatch.farm_id == farm.id,
            )
            .order_by(BulletinDispatch.created_at.desc())
            .limit(limit)
        ).all()
    )
    return [_dispatch_payload(item) for item in items]


@router.post("/send-now/{bulletin_type}")
def send_now(
    bulletin_type: BulletinType,
    farm_id: str = Query(min_length=1),
    principal: Principal = Depends(require_permission("automation.execute")),
    db: Session = Depends(get_db),
) -> dict:
    farm = _farm_for_principal(db, principal, farm_id)
    schedules = ensure_default_schedules(
        db,
        tenant_id=farm.tenant_id,
        company_id=farm.company_id,
        farm_id=farm.id,
    )
    schedule = next(
        item
        for item in schedules
        if item.bulletin_type == bulletin_type
    )
    if not schedule.recipient_whatsapp:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Configure o WhatsApp do produtor antes de enviar.",
        )
    if schedule.whatsapp_opt_in_at is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Confirme o opt-in do produtor antes do envio.",
        )

    start, end = previous_month_period(
        timezone_name=schedule.timezone_name,
    )
    dispatch = get_or_create_dispatch(
        db,
        schedule=schedule,
        period_start=start,
        period_end=end,
    )
    dispatch = attempt_dispatch(db, dispatch)
    return _dispatch_payload(dispatch)
