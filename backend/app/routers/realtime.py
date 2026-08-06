
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, WebSocket, WebSocketDisconnect
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..database import SessionLocal, get_db
from ..models import (
    RealtimeEvent,
    RealtimeNotification,
    RealtimeSubscription,
    new_id,
)
from ..schemas import (
    RealtimeNotificationCreateRequest,
    RealtimeNotificationResponse,
    RealtimePublishRequest,
    RealtimeSubscriptionRequest,
)
from ..services.realtime_hub import realtime_hub

router = APIRouter(prefix="/realtime", tags=["realtime"])


def _farm_allowed(principal: Principal, farm_id: str | None) -> None:
    if farm_id is None or principal.membership.role in {"owner", "admin", "companyAdministrator"}:
        return
    if farm_id not in set(principal.membership.farm_ids or []):
        raise HTTPException(status_code=403, detail="Fazenda não autorizada.")


@router.post("/publish")
async def publish_event(
    payload: RealtimePublishRequest,
    principal: Principal = Depends(require_permission("realtime.publish")),
    db: Session = Depends(get_db),
) -> dict:
    _farm_allowed(principal, payload.farm_id)
    event = RealtimeEvent(
        id=new_id("realtime_event"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=payload.farm_id,
        topic=payload.topic,
        event_type=payload.event_type,
        entity_type=payload.entity_type,
        entity_id=payload.entity_id,
        payload=payload.payload,
        correlation_id=payload.correlation_id,
        source=payload.source,
    )
    db.add(event)
    db.commit()

    room = f"company:{principal.company.id}"
    delivered = await realtime_hub.publish(
        room,
        {
            "id": event.id,
            "topic": event.topic,
            "event_type": event.event_type,
            "farm_id": event.farm_id,
            "entity_type": event.entity_type,
            "entity_id": event.entity_id,
            "payload": event.payload,
            "source": event.source,
            "occurred_at": event.occurred_at.isoformat(),
        },
    )
    return {"event_id": event.id, "delivered_connections": delivered}


@router.get("/events")
def list_events(
    farm_id: str | None = None,
    topic: str | None = None,
    limit: int = Query(default=200, ge=1, le=2000),
    principal: Principal = Depends(require_permission("realtime.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    _farm_allowed(principal, farm_id)
    query = select(RealtimeEvent).where(
        RealtimeEvent.company_id == principal.company.id
    )
    if farm_id:
        query = query.where(RealtimeEvent.farm_id == farm_id)
    if topic:
        query = query.where(RealtimeEvent.topic == topic)
    items = db.scalars(
        query.order_by(RealtimeEvent.occurred_at.desc()).limit(limit)
    ).all()
    return [
        {
            "id": item.id,
            "topic": item.topic,
            "event_type": item.event_type,
            "farm_id": item.farm_id,
            "entity_type": item.entity_type,
            "entity_id": item.entity_id,
            "payload": item.payload,
            "source": item.source,
            "occurred_at": item.occurred_at,
        }
        for item in items
    ]


@router.post("/notifications", response_model=RealtimeNotificationResponse, status_code=201)
async def create_notification(
    payload: RealtimeNotificationCreateRequest,
    principal: Principal = Depends(require_permission("notifications.manage")),
    db: Session = Depends(get_db),
) -> RealtimeNotification:
    _farm_allowed(principal, payload.farm_id)

    if payload.deduplication_key:
        existing = db.scalar(
            select(RealtimeNotification).where(
                RealtimeNotification.company_id == principal.company.id,
                RealtimeNotification.deduplication_key == payload.deduplication_key,
                RealtimeNotification.status.in_(["pending", "delivered"]),
            )
        )
        if existing:
            return existing

    item = RealtimeNotification(
        id=new_id("notification"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    db.refresh(item)

    delivered = await realtime_hub.publish(
        f"company:{principal.company.id}",
        {
            "type": "notification",
            "notification": {
                "id": item.id,
                "category": item.category,
                "severity": item.severity,
                "title": item.title,
                "message": item.message,
                "farm_id": item.farm_id,
                "payload": item.payload,
                "created_at": item.created_at.isoformat(),
            },
        },
    )
    if delivered:
        item.status = "delivered"
        item.delivered_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(item)
    return item


@router.get("/notifications", response_model=list[RealtimeNotificationResponse])
def notifications(
    farm_id: str | None = None,
    unread_only: bool = False,
    principal: Principal = Depends(require_permission("notifications.read")),
    db: Session = Depends(get_db),
) -> list[RealtimeNotification]:
    _farm_allowed(principal, farm_id)
    query = select(RealtimeNotification).where(
        RealtimeNotification.company_id == principal.company.id,
        or_(
            RealtimeNotification.user_id.is_(None),
            RealtimeNotification.user_id == principal.user.id,
        ),
    )
    if farm_id:
        query = query.where(RealtimeNotification.farm_id == farm_id)
    if unread_only:
        query = query.where(RealtimeNotification.read_at.is_(None))
    return list(
        db.scalars(
            query.order_by(RealtimeNotification.created_at.desc()).limit(500)
        ).all()
    )


@router.patch("/notifications/{notification_id}/read", response_model=RealtimeNotificationResponse)
def mark_notification_read(
    notification_id: str,
    principal: Principal = Depends(require_permission("notifications.read")),
    db: Session = Depends(get_db),
) -> RealtimeNotification:
    item = db.get(RealtimeNotification, notification_id)
    if item is None or item.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Notificação não encontrada.")
    item.read_at = datetime.now(timezone.utc)
    item.status = "read"
    db.commit()
    db.refresh(item)
    return item


@router.post("/subscriptions")
def save_subscription(
    payload: RealtimeSubscriptionRequest,
    principal: Principal = Depends(require_permission("notifications.read")),
    db: Session = Depends(get_db),
) -> dict:
    _farm_allowed(principal, payload.farm_id)
    item = db.scalar(
        select(RealtimeSubscription).where(
            RealtimeSubscription.company_id == principal.company.id,
            RealtimeSubscription.user_id == principal.user.id,
            RealtimeSubscription.topic == payload.topic,
            RealtimeSubscription.farm_id == payload.farm_id,
        )
    )
    if item is None:
        item = RealtimeSubscription(
            id=new_id("subscription"),
            tenant_id=principal.company.tenant_id,
            company_id=principal.company.id,
            user_id=principal.user.id,
            **payload.model_dump(),
        )
        db.add(item)
    else:
        for field, value in payload.model_dump().items():
            setattr(item, field, value)
    db.commit()
    return {"id": item.id, "topic": item.topic, "enabled": item.enabled}


@router.get("/metrics")
def realtime_metrics(
    principal: Principal = Depends(require_permission("realtime.read")),
) -> dict:
    return realtime_hub.metrics()


@router.websocket("/ws/{company_id}")
async def websocket_company(websocket: WebSocket, company_id: str) -> None:
    # A autenticação completa do WebSocket será ligada ao token no cliente.
    # Nesta fase, o company_id define a sala e o backend mantém a conexão.
    room = f"company:{company_id}"
    await realtime_hub.connect(room, websocket)
    try:
        await websocket.send_json(
            {"type": "connected", "company_id": company_id}
        )
        while True:
            message = await websocket.receive_json()
            if message.get("type") == "ping":
                await websocket.send_json(
                    {
                        "type": "pong",
                        "timestamp": datetime.now(timezone.utc).isoformat(),
                    }
                )
    except WebSocketDisconnect:
        await realtime_hub.disconnect(room, websocket)
    except Exception:
        await realtime_hub.disconnect(room, websocket)
