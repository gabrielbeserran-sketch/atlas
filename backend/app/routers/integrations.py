
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..database import get_db
from ..models import (
    ApiUsageRecord,
    IntegrationConnection,
    IntegrationProvider,
    IntegrationSyncJob,
    OutboundWebhook,
    PartnerApplication,
    WebhookDelivery,
    new_id,
)
from ..schemas import (
    ApiUsageRecordCreateRequest,
    IntegrationConnectionCreateRequest,
    IntegrationProviderCreateRequest,
    IntegrationSyncJobCreateRequest,
    OutboundWebhookCreateRequest,
    PartnerApplicationCreateRequest,
)
from ..services.integration_platform_service import (
    complete_sync_job,
    create_partner_credentials,
    encode_credentials,
    integration_dashboard,
    queue_event_for_webhooks,
)

router = APIRouter(prefix="/integrations", tags=["integrations-ecosystem"])


def _farm_allowed(principal: Principal, farm_id: str | None) -> None:
    if farm_id is None or principal.membership.role in {
        "owner",
        "admin",
        "companyAdministrator",
    }:
        return
    if farm_id not in set(principal.membership.farm_ids or []):
        raise HTTPException(status_code=403, detail="Fazenda não autorizada.")


@router.post("/providers", status_code=201)
def create_provider(
    payload: IntegrationProviderCreateRequest,
    principal: Principal = Depends(require_permission("integrations.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = IntegrationProvider(
        id=new_id("integration_provider"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Código do provedor duplicado.") from exc
    return {"id": item.id}


@router.get("/providers")
def providers(
    principal: Principal = Depends(require_permission("integrations.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    items = db.scalars(
        select(IntegrationProvider)
        .where(
            IntegrationProvider.company_id == principal.company.id,
            IntegrationProvider.active.is_(True),
        )
        .order_by(IntegrationProvider.category, IntegrationProvider.name)
    ).all()
    return [
        {
            "id": item.id,
            "code": item.code,
            "name": item.name,
            "category": item.category,
            "auth_type": item.auth_type,
            "capabilities": item.capabilities,
        }
        for item in items
    ]


@router.post("/connections", status_code=201)
def create_connection(
    payload: IntegrationConnectionCreateRequest,
    principal: Principal = Depends(require_permission("integrations.manage")),
    db: Session = Depends(get_db),
) -> dict:
    _farm_allowed(principal, payload.farm_id)

    provider = db.get(IntegrationProvider, payload.provider_id)
    if provider is None or provider.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Provedor não encontrado.")

    item = IntegrationConnection(
        id=new_id("integration_connection"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=payload.farm_id,
        provider_id=payload.provider_id,
        name=payload.name,
        status="inactive",
        credentials_encrypted=encode_credentials(payload.credentials),
        configuration=payload.configuration,
        scopes=payload.scopes,
        created_by=principal.user.id,
    )
    db.add(item)
    db.commit()
    return {"id": item.id, "status": item.status}


@router.get("/connections")
def connections(
    farm_id: str | None = None,
    principal: Principal = Depends(require_permission("integrations.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    _farm_allowed(principal, farm_id)
    query = select(IntegrationConnection).where(
        IntegrationConnection.company_id == principal.company.id
    )
    if farm_id:
        query = query.where(IntegrationConnection.farm_id == farm_id)
    items = db.scalars(
        query.order_by(IntegrationConnection.name)
    ).all()
    return [
        {
            "id": item.id,
            "provider_id": item.provider_id,
            "farm_id": item.farm_id,
            "name": item.name,
            "status": item.status,
            "scopes": item.scopes,
            "last_sync_at": item.last_sync_at,
            "last_error": item.last_error,
        }
        for item in items
    ]


@router.post("/sync-jobs", status_code=201)
def create_sync_job(
    payload: IntegrationSyncJobCreateRequest,
    principal: Principal = Depends(require_permission("integrations.execute")),
    db: Session = Depends(get_db),
) -> dict:
    connection = db.get(IntegrationConnection, payload.connection_id)
    if connection is None or connection.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Conexão não encontrada.")

    item = IntegrationSyncJob(
        id=new_id("integration_job"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        connection_id=connection.id,
        job_type=payload.job_type,
        direction=payload.direction,
        status="queued",
        payload=payload.payload,
        result={},
    )
    db.add(item)
    db.commit()
    return {"id": item.id, "status": item.status}


@router.patch("/sync-jobs/{job_id}/complete")
def finish_sync_job(
    job_id: str,
    processed: int = 0,
    failed: int = 0,
    result: dict | None = None,
    principal: Principal = Depends(require_permission("integrations.execute")),
    db: Session = Depends(get_db),
) -> dict:
    item = db.get(IntegrationSyncJob, job_id)
    if item is None or item.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Job não encontrado.")

    complete_sync_job(
        db,
        job=item,
        processed=processed,
        failed=failed,
        result=result or {},
    )
    db.commit()
    return {"id": item.id, "status": item.status}


@router.get("/sync-jobs")
def sync_jobs(
    connection_id: str | None = None,
    status_filter: str | None = Query(default=None, alias="status"),
    principal: Principal = Depends(require_permission("integrations.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    query = select(IntegrationSyncJob).where(
        IntegrationSyncJob.company_id == principal.company.id
    )
    if connection_id:
        query = query.where(IntegrationSyncJob.connection_id == connection_id)
    if status_filter:
        query = query.where(IntegrationSyncJob.status == status_filter)
    items = db.scalars(
        query.order_by(IntegrationSyncJob.created_at.desc()).limit(300)
    ).all()
    return [
        {
            "id": item.id,
            "connection_id": item.connection_id,
            "job_type": item.job_type,
            "direction": item.direction,
            "status": item.status,
            "records_processed": item.records_processed,
            "records_failed": item.records_failed,
            "created_at": item.created_at,
        }
        for item in items
    ]


@router.post("/webhooks", status_code=201)
def create_webhook(
    payload: OutboundWebhookCreateRequest,
    principal: Principal = Depends(require_permission("integrations.manage")),
    db: Session = Depends(get_db),
) -> dict:
    _farm_allowed(principal, payload.farm_id)

    import hashlib
    secret_hash = hashlib.sha256(payload.secret.encode("utf-8")).hexdigest() if payload.secret else ""

    item = OutboundWebhook(
        id=new_id("webhook"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=payload.farm_id,
        name=payload.name,
        target_url=payload.target_url,
        secret_hash=secret_hash,
        event_types=payload.event_types,
        headers=payload.headers,
        active=True,
        retry_policy=payload.retry_policy,
        created_by=principal.user.id,
    )
    db.add(item)
    db.commit()
    return {"id": item.id}


@router.get("/webhooks")
def webhooks(
    principal: Principal = Depends(require_permission("integrations.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    items = db.scalars(
        select(OutboundWebhook)
        .where(OutboundWebhook.company_id == principal.company.id)
        .order_by(OutboundWebhook.name)
    ).all()
    return [
        {
            "id": item.id,
            "name": item.name,
            "target_url": item.target_url,
            "event_types": item.event_types,
            "active": item.active,
        }
        for item in items
    ]


@router.post("/webhooks/events")
def queue_webhook_event(
    event_type: str,
    payload: dict,
    farm_id: str | None = None,
    principal: Principal = Depends(require_permission("integrations.execute")),
    db: Session = Depends(get_db),
) -> dict:
    _farm_allowed(principal, farm_id)
    deliveries = queue_event_for_webhooks(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=farm_id,
        event_type=event_type,
        payload=payload,
    )
    db.commit()
    return {
        "queued": len(deliveries),
        "delivery_ids": [item.id for item in deliveries],
    }


@router.get("/webhooks/deliveries")
def webhook_deliveries(
    status_filter: str | None = Query(default=None, alias="status"),
    principal: Principal = Depends(require_permission("integrations.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    query = select(WebhookDelivery).where(
        WebhookDelivery.company_id == principal.company.id
    )
    if status_filter:
        query = query.where(WebhookDelivery.status == status_filter)
    items = db.scalars(
        query.order_by(WebhookDelivery.created_at.desc()).limit(300)
    ).all()
    return [
        {
            "id": item.id,
            "webhook_id": item.webhook_id,
            "event_type": item.event_type,
            "status": item.status,
            "attempt_count": item.attempt_count,
            "response_status": item.response_status,
            "created_at": item.created_at,
        }
        for item in items
    ]


@router.post("/partners/applications", status_code=201)
def create_partner_application(
    payload: PartnerApplicationCreateRequest,
    principal: Principal = Depends(require_permission("partners.manage")),
    db: Session = Depends(get_db),
) -> dict:
    client_id, client_secret, secret_hash = create_partner_credentials()

    item = PartnerApplication(
        id=new_id("partner_app"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        name=payload.name,
        partner_name=payload.partner_name,
        client_id=client_id,
        client_secret_hash=secret_hash,
        scopes=payload.scopes,
        allowed_origins=payload.allowed_origins,
        rate_limit_per_minute=payload.rate_limit_per_minute,
        active=True,
    )
    db.add(item)
    db.commit()
    return {
        "id": item.id,
        "client_id": client_id,
        "client_secret": client_secret,
        "warning": "O segredo é exibido somente nesta resposta.",
    }


@router.get("/partners/applications")
def partner_applications(
    principal: Principal = Depends(require_permission("partners.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    items = db.scalars(
        select(PartnerApplication)
        .where(PartnerApplication.company_id == principal.company.id)
        .order_by(PartnerApplication.partner_name)
    ).all()
    return [
        {
            "id": item.id,
            "name": item.name,
            "partner_name": item.partner_name,
            "client_id": item.client_id,
            "scopes": item.scopes,
            "rate_limit_per_minute": item.rate_limit_per_minute,
            "active": item.active,
        }
        for item in items
    ]


@router.post("/usage", status_code=201)
def record_usage(
    payload: ApiUsageRecordCreateRequest,
    principal: Principal = Depends(require_permission("partners.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = ApiUsageRecord(
        id=new_id("api_usage"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    return {"id": item.id}


@router.get("/usage/summary")
def usage_summary(
    principal: Principal = Depends(require_permission("partners.read")),
    db: Session = Depends(get_db),
) -> dict:
    records = list(
        db.scalars(
            select(ApiUsageRecord)
            .where(ApiUsageRecord.company_id == principal.company.id)
            .order_by(ApiUsageRecord.occurred_at.desc())
            .limit(5000)
        ).all()
    )

    return {
        "requests": len(records),
        "request_units": sum(item.request_units for item in records),
        "average_duration_ms": round(
            sum(item.duration_ms for item in records) / len(records), 2
        ) if records else 0,
        "error_requests": sum(
            1 for item in records if item.status_code >= 400
        ),
    }


@router.get("/dashboard")
def dashboard(
    principal: Principal = Depends(require_permission("integrations.read")),
    db: Session = Depends(get_db),
) -> dict:
    values = integration_dashboard(
        db,
        company_id=principal.company.id,
    )
    partners = db.scalar(
        select(func.count())
        .select_from(PartnerApplication)
        .where(
            PartnerApplication.company_id == principal.company.id,
            PartnerApplication.active.is_(True),
        )
    ) or 0
    values["active_partner_applications"] = int(partners)
    return values
