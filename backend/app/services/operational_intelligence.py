
from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..models import (
    FinancialEntry,
    HealthEvent,
    HerdLot,
    IndicatorSnapshot,
    InventoryProduct,
    LivestockAnimal,
    OperationalAlert,
    ReproductionEvent,
    WeightRecord,
    new_id,
)


def generate_alerts(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str | None,
) -> list[OperationalAlert]:
    alerts: list[OperationalAlert] = []

    inventory_query = select(InventoryProduct).where(
        InventoryProduct.company_id == company_id,
        InventoryProduct.active.is_(True),
        InventoryProduct.quantity <= InventoryProduct.minimum_quantity,
    )
    if farm_id:
        inventory_query = inventory_query.where(
            InventoryProduct.farm_id == farm_id
        )

    for product in db.scalars(inventory_query).all():
        existing = db.scalar(
            select(OperationalAlert).where(
                OperationalAlert.company_id == company_id,
                OperationalAlert.alert_type == "inventory_minimum",
                OperationalAlert.entity_id == product.id,
                OperationalAlert.status == "open",
            )
        )
        if existing:
            continue
        alert = OperationalAlert(
            id=new_id("alert"),
            tenant_id=tenant_id,
            company_id=company_id,
            farm_id=product.farm_id,
            alert_type="inventory_minimum",
            severity="high" if product.quantity <= 0 else "medium",
            title=f"Estoque baixo: {product.name}",
            description=(
                f"Quantidade atual {product.quantity} {product.unit}; "
                f"mínimo {product.minimum_quantity} {product.unit}."
            ),
            entity_type="inventory_product",
            entity_id=product.id,
            generated_by="inventory_rule",
        )
        db.add(alert)
        alerts.append(alert)

    withdrawal_query = select(HealthEvent).where(
        HealthEvent.company_id == company_id,
        HealthEvent.withdrawal_until.is_not(None),
        HealthEvent.withdrawal_until > datetime.now(timezone.utc),
    )
    if farm_id:
        withdrawal_query = withdrawal_query.where(
            HealthEvent.farm_id == farm_id
        )

    for event in db.scalars(withdrawal_query).all():
        existing = db.scalar(
            select(OperationalAlert).where(
                OperationalAlert.company_id == company_id,
                OperationalAlert.alert_type == "withdrawal_period",
                OperationalAlert.entity_id == event.id,
                OperationalAlert.status == "open",
            )
        )
        if existing:
            continue
        alert = OperationalAlert(
            id=new_id("alert"),
            tenant_id=tenant_id,
            company_id=company_id,
            farm_id=event.farm_id,
            alert_type="withdrawal_period",
            severity="high",
            title="Animal ou lote em período de carência",
            description=f"Produto: {event.product_name}.",
            entity_type="health_event",
            entity_id=event.id,
            due_at=event.withdrawal_until,
            generated_by="health_rule",
        )
        db.add(alert)
        alerts.append(alert)

    db.flush()
    return alerts


def build_indicators(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str | None,
) -> list[IndicatorSnapshot]:
    farm_filter = [] if farm_id is None else [LivestockAnimal.farm_id == farm_id]

    animals = db.scalar(
        select(func.count())
        .select_from(LivestockAnimal)
        .where(
            LivestockAnimal.company_id == company_id,
            *farm_filter,
        )
    ) or 0

    active_animals = db.scalar(
        select(func.count())
        .select_from(LivestockAnimal)
        .where(
            LivestockAnimal.company_id == company_id,
            LivestockAnimal.status == "active",
            *farm_filter,
        )
    ) or 0

    average_weight = db.scalar(
        select(func.avg(LivestockAnimal.current_weight)).where(
            LivestockAnimal.company_id == company_id,
            *farm_filter,
        )
    ) or 0

    revenue_query = select(func.sum(FinancialEntry.amount)).where(
        FinancialEntry.company_id == company_id,
        FinancialEntry.entry_type == "revenue",
    )
    expense_query = select(func.sum(FinancialEntry.amount)).where(
        FinancialEntry.company_id == company_id,
        FinancialEntry.entry_type == "expense",
    )
    if farm_id:
        revenue_query = revenue_query.where(FinancialEntry.farm_id == farm_id)
        expense_query = expense_query.where(FinancialEntry.farm_id == farm_id)

    revenue = float(db.scalar(revenue_query) or 0)
    expense = float(db.scalar(expense_query) or 0)

    definitions = [
        (
            "animals_total",
            "Total de animais",
            float(animals),
            "cabeças",
            "COUNT(livestock_animals)",
            ["livestock_animals"],
        ),
        (
            "animals_active",
            "Animais ativos",
            float(active_animals),
            "cabeças",
            "COUNT(livestock_animals WHERE status='active')",
            ["livestock_animals"],
        ),
        (
            "average_weight",
            "Peso médio",
            float(average_weight),
            "kg",
            "AVG(livestock_animals.current_weight)",
            ["livestock_animals"],
        ),
        (
            "financial_balance",
            "Saldo financeiro",
            revenue - expense,
            "R$",
            "SUM(revenue) - SUM(expense)",
            ["financial_entries"],
        ),
    ]

    snapshots: list[IndicatorSnapshot] = []
    for key, name, value, unit, formula, source_tables in definitions:
        snapshot = IndicatorSnapshot(
            id=new_id("indicator"),
            tenant_id=tenant_id,
            company_id=company_id,
            farm_id=farm_id,
            indicator_key=key,
            indicator_name=name,
            value=value,
            unit=unit,
            formula=formula,
            source_tables=source_tables,
            filters={"farm_id": farm_id},
        )
        db.add(snapshot)
        snapshots.append(snapshot)

    db.flush()
    return snapshots
