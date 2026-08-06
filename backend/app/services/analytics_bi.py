
from __future__ import annotations

from calendar import monthrange
from datetime import datetime, timezone
from math import floor

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..models import (
    AnalyticsBenchmarkSnapshot,
    AnalyticsFactSnapshot,
    AnalyticsFarmScore,
    AnalyticsGoal,
    FinancialEntry,
    HealthEvent,
    InventoryProduct,
    LivestockAnimal,
    ReproductionEvent,
    WeightRecord,
    new_id,
)


def month_period(reference: datetime | None = None) -> tuple[datetime, datetime]:
    value = reference or datetime.now(timezone.utc)
    start = datetime(value.year, value.month, 1, tzinfo=timezone.utc)
    end = datetime(
        value.year,
        value.month,
        monthrange(value.year, value.month)[1],
        23,
        59,
        59,
        tzinfo=timezone.utc,
    )
    return start, end


def _count(db: Session, model, company_id: str, farm_id: str | None, *conditions) -> int:
    query = select(func.count()).select_from(model).where(
        model.company_id == company_id,
        *conditions,
    )
    if farm_id and hasattr(model, "farm_id"):
        query = query.where(model.farm_id == farm_id)
    return int(db.scalar(query) or 0)


def _sum(db: Session, column, model, company_id: str, farm_id: str | None, *conditions) -> float:
    query = select(func.sum(column)).where(
        model.company_id == company_id,
        *conditions,
    )
    if farm_id and hasattr(model, "farm_id"):
        query = query.where(model.farm_id == farm_id)
    return float(db.scalar(query) or 0)


def build_monthly_facts(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str | None,
    reference: datetime | None = None,
) -> list[AnalyticsFactSnapshot]:
    start, end = month_period(reference)

    total_animals = _count(
        db,
        LivestockAnimal,
        company_id,
        farm_id,
    )
    active_animals = _count(
        db,
        LivestockAnimal,
        company_id,
        farm_id,
        LivestockAnimal.status == "active",
    )
    health_events = _count(
        db,
        HealthEvent,
        company_id,
        farm_id,
        HealthEvent.occurred_at >= start,
        HealthEvent.occurred_at <= end,
    )
    reproduction_events = _count(
        db,
        ReproductionEvent,
        company_id,
        farm_id,
        ReproductionEvent.occurred_at >= start,
        ReproductionEvent.occurred_at <= end,
    )
    average_weight_query = select(func.avg(LivestockAnimal.current_weight)).where(
        LivestockAnimal.company_id == company_id,
    )
    if farm_id:
        average_weight_query = average_weight_query.where(
            LivestockAnimal.farm_id == farm_id
        )
    average_weight = float(db.scalar(average_weight_query) or 0)

    revenue = _sum(
        db,
        FinancialEntry.amount,
        FinancialEntry,
        company_id,
        farm_id,
        FinancialEntry.entry_type == "revenue",
    )
    expense = _sum(
        db,
        FinancialEntry.amount,
        FinancialEntry,
        company_id,
        farm_id,
        FinancialEntry.entry_type == "expense",
    )
    inventory_value_query = select(
        func.sum(InventoryProduct.quantity * InventoryProduct.average_cost)
    ).where(InventoryProduct.company_id == company_id)
    if farm_id:
        inventory_value_query = inventory_value_query.where(
            InventoryProduct.farm_id == farm_id
        )
    inventory_value = float(db.scalar(inventory_value_query) or 0)

    definitions = [
        ("animals_total", "Total de animais", "herd", float(total_animals), "cabeças", "COUNT(livestock_animals)", ["livestock_animals"]),
        ("animals_active", "Animais ativos", "herd", float(active_animals), "cabeças", "COUNT(livestock_animals WHERE status='active')", ["livestock_animals"]),
        ("average_weight", "Peso médio", "production", average_weight, "kg", "AVG(livestock_animals.current_weight)", ["livestock_animals"]),
        ("health_events_month", "Eventos sanitários no mês", "health", float(health_events), "eventos", "COUNT(health_events IN PERIOD)", ["health_events"]),
        ("reproduction_events_month", "Eventos reprodutivos no mês", "reproduction", float(reproduction_events), "eventos", "COUNT(reproduction_events IN PERIOD)", ["reproduction_events"]),
        ("revenue_total", "Receita acumulada", "finance", revenue, "R$", "SUM(financial_entries WHERE type='revenue')", ["financial_entries"]),
        ("expense_total", "Despesa acumulada", "finance", expense, "R$", "SUM(financial_entries WHERE type='expense')", ["financial_entries"]),
        ("financial_balance", "Saldo financeiro", "finance", revenue - expense, "R$", "SUM(revenue) - SUM(expense)", ["financial_entries"]),
        ("inventory_value", "Valor do estoque", "inventory", inventory_value, "R$", "SUM(quantity * average_cost)", ["inventory_products"]),
    ]

    snapshots: list[AnalyticsFactSnapshot] = []
    for key, name, group, value, unit, formula, sources in definitions:
        existing = db.scalar(
            select(AnalyticsFactSnapshot).where(
                AnalyticsFactSnapshot.company_id == company_id,
                AnalyticsFactSnapshot.farm_id == farm_id,
                AnalyticsFactSnapshot.metric_key == key,
                AnalyticsFactSnapshot.period_start == start,
                AnalyticsFactSnapshot.period_end == end,
            )
        )
        if existing is None:
            existing = AnalyticsFactSnapshot(
                id=new_id("analytics_fact"),
                tenant_id=tenant_id,
                company_id=company_id,
                farm_id=farm_id,
                metric_key=key,
                metric_name=name,
                metric_group=group,
                value=value,
                unit=unit,
                period_start=start,
                period_end=end,
                dimensions={"farm_id": farm_id, "year": start.year, "month": start.month},
                source_tables=sources,
                formula=formula,
            )
            db.add(existing)
        else:
            existing.value = value
            existing.generated_at = datetime.now(timezone.utc)
        snapshots.append(existing)

    db.flush()
    return snapshots


def build_benchmarks(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    metric_key: str,
    period_start: datetime,
    period_end: datetime,
) -> list[AnalyticsBenchmarkSnapshot]:
    facts = list(
        db.scalars(
            select(AnalyticsFactSnapshot).where(
                AnalyticsFactSnapshot.company_id == company_id,
                AnalyticsFactSnapshot.metric_key == metric_key,
                AnalyticsFactSnapshot.period_start == period_start,
                AnalyticsFactSnapshot.period_end == period_end,
                AnalyticsFactSnapshot.farm_id.is_not(None),
            )
        ).all()
    )
    ordered = sorted(facts, key=lambda item: item.value, reverse=True)
    total = len(ordered)
    snapshots: list[AnalyticsBenchmarkSnapshot] = []

    for index, fact in enumerate(ordered, start=1):
        percentile = 100.0 if total <= 1 else ((total - index) / (total - 1)) * 100
        item = AnalyticsBenchmarkSnapshot(
            id=new_id("benchmark"),
            tenant_id=tenant_id,
            company_id=company_id,
            farm_id=fact.farm_id,
            metric_key=metric_key,
            value=fact.value,
            percentile=percentile,
            rank_position=index,
            peer_count=total,
            peer_group="company_farms",
            period_start=period_start,
            period_end=period_end,
        )
        db.add(item)
        snapshots.append(item)

    db.flush()
    return snapshots


def update_goals(
    db: Session,
    *,
    company_id: str,
    farm_id: str | None,
) -> list[AnalyticsGoal]:
    goals_query = select(AnalyticsGoal).where(
        AnalyticsGoal.company_id == company_id,
        AnalyticsGoal.status == "active",
    )
    if farm_id:
        goals_query = goals_query.where(AnalyticsGoal.farm_id == farm_id)

    goals = list(db.scalars(goals_query).all())
    for goal in goals:
        latest = db.scalar(
            select(AnalyticsFactSnapshot)
            .where(
                AnalyticsFactSnapshot.company_id == company_id,
                AnalyticsFactSnapshot.farm_id == goal.farm_id,
                AnalyticsFactSnapshot.metric_key == goal.kpi_key,
            )
            .order_by(AnalyticsFactSnapshot.period_end.desc())
        )
        if latest:
            goal.current_value = latest.value
        if goal.current_value >= goal.target_value and goal.target_value >= goal.baseline_value:
            goal.status = "achieved"
        elif goal.current_value <= goal.target_value and goal.target_value < goal.baseline_value:
            goal.status = "achieved"
        elif datetime.now(timezone.utc) > goal.due_date:
            goal.status = "overdue"
    db.flush()
    return goals


def build_farm_score(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str,
    reference: datetime | None = None,
) -> AnalyticsFarmScore:
    start, end = month_period(reference)
    facts = list(
        db.scalars(
            select(AnalyticsFactSnapshot).where(
                AnalyticsFactSnapshot.company_id == company_id,
                AnalyticsFactSnapshot.farm_id == farm_id,
                AnalyticsFactSnapshot.period_start == start,
                AnalyticsFactSnapshot.period_end == end,
            )
        ).all()
    )
    values = {item.metric_key: item.value for item in facts}

    herd_score = 100.0 if values.get("animals_total", 0) > 0 else 0.0
    finance_balance = values.get("financial_balance", 0)
    finance_score = max(0.0, min(100.0, 50.0 + finance_balance / 1000))
    health_events = values.get("health_events_month", 0)
    health_score = max(0.0, min(100.0, 100.0 - health_events * 2))
    reproduction_events = values.get("reproduction_events_month", 0)
    reproduction_score = max(0.0, min(100.0, reproduction_events * 5))
    inventory_score = 100.0 if values.get("inventory_value", 0) > 0 else 40.0

    components = {
        "herd": round(herd_score, 2),
        "finance": round(finance_score, 2),
        "health": round(health_score, 2),
        "reproduction": round(reproduction_score, 2),
        "inventory": round(inventory_score, 2),
    }
    score = (
        herd_score * 0.20
        + finance_score * 0.25
        + health_score * 0.20
        + reproduction_score * 0.20
        + inventory_score * 0.15
    )
    grade = (
        "A" if score >= 85
        else "B" if score >= 70
        else "C" if score >= 55
        else "D"
    )
    explanations = [
        f"Rebanho contribuiu com {herd_score:.1f}/100.",
        f"Financeiro contribuiu com {finance_score:.1f}/100.",
        f"Sanidade contribuiu com {health_score:.1f}/100.",
        f"Reprodução contribuiu com {reproduction_score:.1f}/100.",
        f"Estoque contribuiu com {inventory_score:.1f}/100.",
    ]

    item = AnalyticsFarmScore(
        id=new_id("farm_score"),
        tenant_id=tenant_id,
        company_id=company_id,
        farm_id=farm_id,
        score=round(score, 2),
        grade=grade,
        component_scores=components,
        explanations=explanations,
        period_start=start,
        period_end=end,
    )
    db.add(item)
    db.flush()
    return item
