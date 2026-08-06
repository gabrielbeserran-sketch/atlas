
from __future__ import annotations

import hashlib
import json
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models import (
    IntegrationConnection,
    IntegrationSyncJob,
    OutboundWebhook,
    PartnerApplication,
    WebhookDelivery,
    new_id,
)


def _hash_secret(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def encode_credentials(credentials: dict[str, Any]) -> str:
    # Estrutura de desenvolvimento: os dados são serializados e ofuscados por hash.
    # Em produção deve ser substituída por KMS/Vault com criptografia reversível segura.
    serialized = json.dumps(credentials, sort_keys=True, ensure_ascii=False)
    digest = _hash_secret(serialized)
    return json.dumps({"digest": digest, "configured": bool(credentials)})


def create_partner_credentials() -> tuple[str, str, str]:
    client_id = f"atlas_{secrets.token_urlsafe(18)}"
    client_secret = secrets.token_urlsafe(42)
    return client_id, client_secret, _hash_secret(client_secret)


def create_webhook_delivery(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    webhook: OutboundWebhook,
    event_type: str,
    payload: dict[str, Any],
) -> WebhookDelivery:
    item = WebhookDelivery(
        id=new_id("webhook_delivery"),
        tenant_id=tenant_id,
        company_id=company_id,
        webhook_id=webhook.id,
        event_type=event_type,
        payload=payload,
        status="pending",
        attempt_count=0,
        next_attempt_at=datetime.now(timezone.utc),
    )
    db.add(item)
    db.flush()
    return item


def queue_event_for_webhooks(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str | None,
    event_type: str,
    payload: dict[str, Any],
) -> list[WebhookDelivery]:
    webhooks = list(
        db.scalars(
            select(OutboundWebhook).where(
                OutboundWebhook.company_id == company_id,
                OutboundWebhook.active.is_(True),
            )
        ).all()
    )

    deliveries = []
    for webhook in webhooks:
        if webhook.farm_id is not None and webhook.farm_id != farm_id:
            continue
        if event_type not in set(webhook.event_types or []):
            continue
        deliveries.append(
            create_webhook_delivery(
                db,
                tenant_id=tenant_id,
                company_id=company_id,
                webhook=webhook,
                event_type=event_type,
                payload=payload,
            )
        )
    return deliveries


def complete_sync_job(
    db: Session,
    *,
    job: IntegrationSyncJob,
    processed: int,
    failed: int,
    result: dict[str, Any],
) -> None:
    job.records_processed = processed
    job.records_failed = failed
    job.result = result
    job.status = "completed" if failed == 0 else "completed_with_errors"
    job.completed_at = datetime.now(timezone.utc)

    connection = db.get(IntegrationConnection, job.connection_id)
    if connection is not None:
        connection.last_sync_at = job.completed_at
        connection.status = "active" if failed == 0 else "degraded"
        connection.last_error = "" if failed == 0 else f"{failed} registro(s) falharam."


def integration_dashboard(db: Session, *, company_id: str) -> dict:
    connections = list(
        db.scalars(
            select(IntegrationConnection).where(
                IntegrationConnection.company_id == company_id
            )
        ).all()
    )
    jobs = list(
        db.scalars(
            select(IntegrationSyncJob)
            .where(IntegrationSyncJob.company_id == company_id)
            .order_by(IntegrationSyncJob.created_at.desc())
            .limit(100)
        ).all()
    )
    deliveries = list(
        db.scalars(
            select(WebhookDelivery)
            .where(WebhookDelivery.company_id == company_id)
            .order_by(WebhookDelivery.created_at.desc())
            .limit(100)
        ).all()
    )

    return {
        "connections": len(connections),
        "active_connections": sum(
            1 for item in connections if item.status == "active"
        ),
        "degraded_connections": sum(
            1 for item in connections if item.status == "degraded"
        ),
        "queued_jobs": sum(1 for item in jobs if item.status == "queued"),
        "failed_jobs": sum(
            1 for item in jobs if item.status in {"failed", "completed_with_errors"}
        ),
        "pending_webhooks": sum(
            1 for item in deliveries if item.status == "pending"
        ),
        "failed_webhooks": sum(
            1 for item in deliveries if item.status == "failed"
        ),
    }
