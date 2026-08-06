
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..database import get_db
from ..models import (
    AnalyticsBenchmarkSnapshot,
    AnalyticsFactSnapshot,
    AnalyticsFarmScore,
    AnalyticsGoal,
    AnalyticsKpiDefinition,
    new_id,
)
from ..schemas import (
    AnalyticsBenchmarkResponse,
    AnalyticsFactResponse,
    AnalyticsFarmScoreResponse,
    AnalyticsGoalCreateRequest,
    AnalyticsGoalResponse,
    AnalyticsGoalUpdateRequest,
    AnalyticsKpiCreateRequest,
    AnalyticsKpiResponse,
)
from ..services.analytics_bi import (
    build_benchmarks,
    build_farm_score,
    build_monthly_facts,
    month_period,
    update_goals,
)

router = APIRouter(prefix="/analytics", tags=["analytics"])


def _farm_allowed(principal: Principal, farm_id: str | None) -> None:
    if farm_id is None or principal.membership.role in {"owner", "admin"}:
        return
    allowed = set(principal.membership.farm_ids or [])
    if farm_id not in allowed:
        raise HTTPException(status_code=403, detail="Fazenda não autorizada.")


@router.post("/warehouse/refresh", response_model=list[AnalyticsFactResponse])
def refresh_warehouse(
    farm_id: str | None = None,
    reference: datetime | None = None,
    principal: Principal = Depends(require_permission("analytics.manage")),
    db: Session = Depends(get_db),
) -> list[AnalyticsFactSnapshot]:
    _farm_allowed(principal, farm_id)
    items = build_monthly_facts(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=farm_id,
        reference=reference,
    )
    db.commit()
    return items


@router.get("/facts", response_model=list[AnalyticsFactResponse])
def facts(
    farm_id: str | None = None,
    metric_group: str | None = None,
    metric_key: str | None = None,
    limit: int = Query(default=500, ge=1, le=5000),
    principal: Principal = Depends(require_permission("analytics.read")),
    db: Session = Depends(get_db),
) -> list[AnalyticsFactSnapshot]:
    _farm_allowed(principal, farm_id)
    query = select(AnalyticsFactSnapshot).where(
        AnalyticsFactSnapshot.company_id == principal.company.id
    )
    if farm_id:
        query = query.where(AnalyticsFactSnapshot.farm_id == farm_id)
    if metric_group:
        query = query.where(AnalyticsFactSnapshot.metric_group == metric_group)
    if metric_key:
        query = query.where(AnalyticsFactSnapshot.metric_key == metric_key)
    return list(
        db.scalars(
            query.order_by(AnalyticsFactSnapshot.period_end.desc()).limit(limit)
        ).all()
    )


@router.post("/kpis", response_model=AnalyticsKpiResponse, status_code=201)
def create_kpi(
    payload: AnalyticsKpiCreateRequest,
    principal: Principal = Depends(require_permission("analytics.manage")),
    db: Session = Depends(get_db),
) -> AnalyticsKpiDefinition:
    item = AnalyticsKpiDefinition(
        id=new_id("analytics_kpi"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Chave de KPI duplicada.") from exc
    db.refresh(item)
    return item


@router.get("/kpis", response_model=list[AnalyticsKpiResponse])
def list_kpis(
    principal: Principal = Depends(require_permission("analytics.read")),
    db: Session = Depends(get_db),
) -> list[AnalyticsKpiDefinition]:
    return list(
        db.scalars(
            select(AnalyticsKpiDefinition)
            .where(
                AnalyticsKpiDefinition.company_id == principal.company.id,
                AnalyticsKpiDefinition.active.is_(True),
            )
            .order_by(AnalyticsKpiDefinition.metric_group, AnalyticsKpiDefinition.name)
        ).all()
    )


@router.post("/goals", response_model=AnalyticsGoalResponse, status_code=201)
def create_goal(
    payload: AnalyticsGoalCreateRequest,
    principal: Principal = Depends(require_permission("analytics.manage")),
    db: Session = Depends(get_db),
) -> AnalyticsGoal:
    _farm_allowed(principal, payload.farm_id)
    item = AnalyticsGoal(
        id=new_id("analytics_goal"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        current_value=payload.baseline_value,
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.get("/goals", response_model=list[AnalyticsGoalResponse])
def list_goals(
    farm_id: str | None = None,
    status_filter: str | None = Query(default=None, alias="status"),
    principal: Principal = Depends(require_permission("analytics.read")),
    db: Session = Depends(get_db),
) -> list[AnalyticsGoal]:
    _farm_allowed(principal, farm_id)
    query = select(AnalyticsGoal).where(
        AnalyticsGoal.company_id == principal.company.id
    )
    if farm_id:
        query = query.where(AnalyticsGoal.farm_id == farm_id)
    if status_filter:
        query = query.where(AnalyticsGoal.status == status_filter)
    return list(db.scalars(query.order_by(AnalyticsGoal.due_date)).all())


@router.patch("/goals/{goal_id}", response_model=AnalyticsGoalResponse)
def update_goal(
    goal_id: str,
    payload: AnalyticsGoalUpdateRequest,
    principal: Principal = Depends(require_permission("analytics.manage")),
    db: Session = Depends(get_db),
) -> AnalyticsGoal:
    item = db.get(AnalyticsGoal, goal_id)
    if item is None or item.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Meta não encontrada.")
    _farm_allowed(principal, item.farm_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(item, field, value)
    db.commit()
    db.refresh(item)
    return item


@router.post("/goals/recalculate", response_model=list[AnalyticsGoalResponse])
def recalculate_goals(
    farm_id: str | None = None,
    principal: Principal = Depends(require_permission("analytics.manage")),
    db: Session = Depends(get_db),
) -> list[AnalyticsGoal]:
    _farm_allowed(principal, farm_id)
    items = update_goals(
        db,
        company_id=principal.company.id,
        farm_id=farm_id,
    )
    db.commit()
    return items


@router.post("/benchmarks/{metric_key}", response_model=list[AnalyticsBenchmarkResponse])
def benchmark(
    metric_key: str,
    reference: datetime | None = None,
    principal: Principal = Depends(require_permission("analytics.manage")),
    db: Session = Depends(get_db),
) -> list[AnalyticsBenchmarkSnapshot]:
    start, end = month_period(reference)
    items = build_benchmarks(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        metric_key=metric_key,
        period_start=start,
        period_end=end,
    )
    db.commit()
    return items


@router.get("/benchmarks", response_model=list[AnalyticsBenchmarkResponse])
def benchmarks(
    farm_id: str | None = None,
    metric_key: str | None = None,
    principal: Principal = Depends(require_permission("analytics.read")),
    db: Session = Depends(get_db),
) -> list[AnalyticsBenchmarkSnapshot]:
    _farm_allowed(principal, farm_id)
    query = select(AnalyticsBenchmarkSnapshot).where(
        AnalyticsBenchmarkSnapshot.company_id == principal.company.id
    )
    if farm_id:
        query = query.where(AnalyticsBenchmarkSnapshot.farm_id == farm_id)
    if metric_key:
        query = query.where(AnalyticsBenchmarkSnapshot.metric_key == metric_key)
    return list(
        db.scalars(
            query.order_by(AnalyticsBenchmarkSnapshot.generated_at.desc())
        ).all()
    )


@router.post("/farm-score/{farm_id}", response_model=AnalyticsFarmScoreResponse)
def generate_farm_score(
    farm_id: str,
    reference: datetime | None = None,
    principal: Principal = Depends(require_permission("analytics.manage")),
    db: Session = Depends(get_db),
) -> AnalyticsFarmScore:
    _farm_allowed(principal, farm_id)
    build_monthly_facts(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=farm_id,
        reference=reference,
    )
    item = build_farm_score(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=farm_id,
        reference=reference,
    )
    db.commit()
    db.refresh(item)
    return item


@router.get("/farm-score/{farm_id}", response_model=list[AnalyticsFarmScoreResponse])
def farm_score_history(
    farm_id: str,
    principal: Principal = Depends(require_permission("analytics.read")),
    db: Session = Depends(get_db),
) -> list[AnalyticsFarmScore]:
    _farm_allowed(principal, farm_id)
    return list(
        db.scalars(
            select(AnalyticsFarmScore)
            .where(
                AnalyticsFarmScore.company_id == principal.company.id,
                AnalyticsFarmScore.farm_id == farm_id,
            )
            .order_by(AnalyticsFarmScore.period_end.desc())
        ).all()
    )


@router.get("/dashboard")
def executive_dashboard(
    farm_id: str | None = None,
    principal: Principal = Depends(require_permission("analytics.read")),
    db: Session = Depends(get_db),
) -> dict:
    _farm_allowed(principal, farm_id)
    facts = list(
        db.scalars(
            select(AnalyticsFactSnapshot)
            .where(
                AnalyticsFactSnapshot.company_id == principal.company.id,
                AnalyticsFactSnapshot.farm_id == farm_id,
            )
            .order_by(AnalyticsFactSnapshot.period_end.desc())
            .limit(100)
        ).all()
    )
    goals = list(
        db.scalars(
            select(AnalyticsGoal)
            .where(
                AnalyticsGoal.company_id == principal.company.id,
                AnalyticsGoal.farm_id == farm_id,
            )
            .order_by(AnalyticsGoal.due_date)
            .limit(50)
        ).all()
    )
    scores = list(
        db.scalars(
            select(AnalyticsFarmScore)
            .where(
                AnalyticsFarmScore.company_id == principal.company.id,
                AnalyticsFarmScore.farm_id == farm_id,
            )
            .order_by(AnalyticsFarmScore.period_end.desc())
            .limit(12)
        ).all()
    )
    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "farm_id": farm_id,
        "facts": [
            {
                "metric_key": item.metric_key,
                "metric_name": item.metric_name,
                "metric_group": item.metric_group,
                "value": item.value,
                "unit": item.unit,
                "period_start": item.period_start.isoformat(),
                "period_end": item.period_end.isoformat(),
                "formula": item.formula,
                "source_tables": item.source_tables,
            }
            for item in facts
        ],
        "goals": [
            {
                "id": item.id,
                "kpi_key": item.kpi_key,
                "title": item.title,
                "current_value": item.current_value,
                "target_value": item.target_value,
                "status": item.status,
                "due_date": item.due_date.isoformat(),
            }
            for item in goals
        ],
        "scores": [
            {
                "score": item.score,
                "grade": item.grade,
                "components": item.component_scores,
                "period_end": item.period_end.isoformat(),
            }
            for item in scores
        ],
    }
