
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models import (
    CommercialInvoice,
    CommercialPlan,
    CommercialProposal,
    CommercialSubscription,
    RealtimeNotification,
    new_id,
)


def proposal_totals(items: list[dict[str, Any]], discount: float) -> tuple[float, float]:
    subtotal = 0.0
    for item in items:
        quantity = float(item.get("quantity", 1) or 0)
        unit_price = float(item.get("unit_price", 0) or 0)
        subtotal += quantity * unit_price
    total = max(0.0, subtotal - float(discount or 0))
    return round(subtotal, 2), round(total, 2)


def create_invoice_for_subscription(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    subscription: CommercialSubscription,
    plan: CommercialPlan,
) -> CommercialInvoice:
    due_at = datetime.now(timezone.utc) + timedelta(days=10)
    reference = f"SUB-{subscription.id[-8:]}-{due_at:%Y%m}"

    existing = db.scalar(
        select(CommercialInvoice).where(
            CommercialInvoice.company_id == company_id,
            CommercialInvoice.reference == reference,
        )
    )
    if existing:
        return existing

    invoice = CommercialInvoice(
        id=new_id("invoice"),
        tenant_id=tenant_id,
        company_id=company_id,
        customer_id=subscription.customer_id,
        subscription_id=subscription.id,
        reference=reference,
        amount=plan.price,
        due_at=due_at,
        status="open",
        payment_method="",
        metadata_json={
            "plan_code": plan.code,
            "billing_cycle": plan.billing_cycle,
        },
    )
    db.add(invoice)
    db.flush()
    return invoice


def create_due_notifications(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
) -> list[RealtimeNotification]:
    now = datetime.now(timezone.utc)
    horizon = now + timedelta(days=3)

    invoices = list(
        db.scalars(
            select(CommercialInvoice).where(
                CommercialInvoice.company_id == company_id,
                CommercialInvoice.status == "open",
                CommercialInvoice.due_at <= horizon,
            )
        ).all()
    )

    notifications: list[RealtimeNotification] = []
    for invoice in invoices:
        key = f"commercial:invoice_due:{invoice.id}"
        existing = db.scalar(
            select(RealtimeNotification).where(
                RealtimeNotification.company_id == company_id,
                RealtimeNotification.deduplication_key == key,
                RealtimeNotification.status.in_(["pending", "delivered"]),
            )
        )
        if existing:
            continue

        notification = RealtimeNotification(
            id=new_id("notification"),
            tenant_id=tenant_id,
            company_id=company_id,
            farm_id=None,
            user_id=None,
            channel="in_app",
            category="commercial",
            severity="warning",
            title="Cobrança próxima do vencimento",
            message=(
                f"Fatura {invoice.reference} no valor de "
                f"R$ {invoice.amount:.2f} vence em {invoice.due_at:%d/%m/%Y}."
            ),
            payload={
                "invoice_id": invoice.id,
                "customer_id": invoice.customer_id,
                "amount": invoice.amount,
                "due_at": invoice.due_at.isoformat(),
            },
            deduplication_key=key,
            status="pending",
        )
        db.add(notification)
        notifications.append(notification)

    db.flush()
    return notifications
