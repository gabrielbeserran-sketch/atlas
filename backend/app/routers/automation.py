
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..database import get_db
from ..models import (
    AutomationRule,
    CorporateCalendarEvent,
    ExecutiveDigest,
    StrategicObjective,
    WorkflowDefinition,
    WorkflowInstance,
    new_id,
)
from ..schemas import (
    AutomationRuleCreateRequest,
    CorporateCalendarEventCreateRequest,
    StrategicObjectiveCreateRequest,
    WorkflowCreateRequest,
    WorkflowStartRequest,
)
from ..services.automation_engine import (
    execute_event_rules,
    generate_executive_digest,
)

router = APIRouter(prefix="/automation", tags=["automation"])


@router.post("/rules", status_code=201)
def create_rule(
    payload: AutomationRuleCreateRequest,
    principal: Principal = Depends(require_permission("automation.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = AutomationRule(
        id=new_id("automation_rule"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    return {"id": item.id}


@router.get("/rules")
def list_rules(
    principal: Principal = Depends(require_permission("automation.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    items = db.scalars(
        select(AutomationRule)
        .where(AutomationRule.company_id == principal.company.id)
        .order_by(AutomationRule.priority.desc())
    ).all()
    return [
        {
            "id": item.id,
            "name": item.name,
            "event_type": item.event_type,
            "enabled": item.enabled,
            "priority": item.priority,
            "last_executed_at": item.last_executed_at,
        }
        for item in items
    ]


@router.post("/events/execute")
def execute_rules(
    event_type: str,
    payload: dict,
    farm_id: str | None = None,
    principal: Principal = Depends(require_permission("automation.execute")),
    db: Session = Depends(get_db),
) -> dict:
    ids = execute_event_rules(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=farm_id,
        event_type=event_type,
        payload=payload,
    )
    db.commit()
    return {"executed_rules": ids}


@router.post("/workflows", status_code=201)
def create_workflow(
    payload: WorkflowCreateRequest,
    principal: Principal = Depends(require_permission("automation.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = WorkflowDefinition(
        id=new_id("workflow"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    return {"id": item.id}


@router.get("/workflows")
def workflows(
    principal: Principal = Depends(require_permission("automation.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    items = db.scalars(
        select(WorkflowDefinition)
        .where(WorkflowDefinition.company_id == principal.company.id)
        .order_by(WorkflowDefinition.name)
    ).all()
    return [
        {
            "id": item.id,
            "code": item.code,
            "name": item.name,
            "steps": item.steps,
            "active": item.active,
        }
        for item in items
    ]


@router.post("/workflows/{workflow_id}/start", status_code=201)
def start_workflow(
    workflow_id: str,
    payload: WorkflowStartRequest,
    principal: Principal = Depends(require_permission("automation.execute")),
    db: Session = Depends(get_db),
) -> dict:
    workflow = db.get(WorkflowDefinition, workflow_id)
    if workflow is None or workflow.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Workflow não encontrado.")
    item = WorkflowInstance(
        id=new_id("workflow_instance"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=payload.farm_id,
        workflow_id=workflow.id,
        status="running",
        current_step=0,
        context=payload.context,
        started_by=principal.user.id,
    )
    db.add(item)
    db.commit()
    return {"id": item.id, "status": item.status}


@router.post("/calendar", status_code=201)
def create_calendar_event(
    payload: CorporateCalendarEventCreateRequest,
    principal: Principal = Depends(require_permission("automation.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = CorporateCalendarEvent(
        id=new_id("calendar_event"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        status="scheduled",
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    return {"id": item.id}


@router.get("/calendar")
def calendar(
    principal: Principal = Depends(require_permission("automation.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    items = db.scalars(
        select(CorporateCalendarEvent)
        .where(CorporateCalendarEvent.company_id == principal.company.id)
        .order_by(CorporateCalendarEvent.starts_at)
    ).all()
    return [
        {
            "id": item.id,
            "title": item.title,
            "category": item.category,
            "starts_at": item.starts_at,
            "status": item.status,
        }
        for item in items
    ]


@router.post("/objectives", status_code=201)
def create_objective(
    payload: StrategicObjectiveCreateRequest,
    principal: Principal = Depends(require_permission("strategy.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = StrategicObjective(
        id=new_id("objective"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        status="active",
        progress_percent=0,
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    return {"id": item.id}


@router.get("/objectives")
def objectives(
    principal: Principal = Depends(require_permission("strategy.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    items = db.scalars(
        select(StrategicObjective)
        .where(StrategicObjective.company_id == principal.company.id)
        .order_by(StrategicObjective.created_at.desc())
    ).all()
    return [
        {
            "id": item.id,
            "title": item.title,
            "status": item.status,
            "progress_percent": item.progress_percent,
            "due_at": item.due_at,
            "key_results": item.key_results,
        }
        for item in items
    ]


@router.post("/executive-digests", status_code=201)
def create_digest(
    period: str = "daily",
    farm_id: str | None = None,
    principal: Principal = Depends(require_permission("strategy.read")),
    db: Session = Depends(get_db),
) -> dict:
    item = generate_executive_digest(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=farm_id,
        period=period,
    )
    db.commit()
    return {
        "id": item.id,
        "summary": item.summary,
        "metrics": item.metrics,
        "priorities": item.priorities,
    }


@router.get("/dashboard")
def dashboard(
    principal: Principal = Depends(require_permission("automation.read")),
    db: Session = Depends(get_db),
) -> dict:
    rules = list(db.scalars(select(AutomationRule).where(AutomationRule.company_id == principal.company.id)).all())
    workflows = list(db.scalars(select(WorkflowInstance).where(WorkflowInstance.company_id == principal.company.id)).all())
    objectives = list(db.scalars(select(StrategicObjective).where(StrategicObjective.company_id == principal.company.id)).all())
    return {
        "active_rules": sum(1 for item in rules if item.enabled),
        "running_workflows": sum(1 for item in workflows if item.status == "running"),
        "active_objectives": sum(1 for item in objectives if item.status == "active"),
        "average_objective_progress": round(
            sum(item.progress_percent for item in objectives) / len(objectives), 2
        ) if objectives else 0,
    }
