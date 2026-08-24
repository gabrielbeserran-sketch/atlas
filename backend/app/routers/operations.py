
from __future__ import annotations

import csv
import io
import json
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..database import get_db
from ..business_models import AtlasActionPlanItem
from ..models import (
    AnimalMovement,
    EntityState,
    FinancialEntry,
    HealthEvent,
    IndicatorSnapshot,
    InventoryMovement,
    LivestockAnimal,
    NutritionEvent,
    OperationalAlert,
    OperationalTask,
    ReproductionEvent,
    SyncChange,
    WeightRecord,
    new_id,
)
from ..schemas import (
    ConflictResolutionRequest,
    IndicatorSnapshotResponse,
    OperationalAlertResponse,
    OperationalTaskCreateRequest,
    OperationalTaskResponse,
    OperationalTaskUpdateRequest,
    TimelineItemResponse,
)
from ..services.operational_intelligence import (
    build_indicators,
    generate_alerts,
)

router = APIRouter(prefix="/operations", tags=["operations"])


def _farm_allowed(principal: Principal, farm_id: str | None) -> None:
    if farm_id is None or principal.membership.role in {"owner", "admin"}:
        return
    allowed = set(principal.membership.farm_ids or [])
    if allowed and farm_id not in allowed:
        raise HTTPException(status_code=403, detail="Fazenda não autorizada.")


@router.post("/conflicts/{entity_type}/{entity_id}/resolve")
def resolve_conflict(
    entity_type: str,
    entity_id: str,
    payload: ConflictResolutionRequest,
    principal: Principal = Depends(require_permission("sync.write")),
    db: Session = Depends(get_db),
) -> dict:
    state = db.scalar(
        select(EntityState).where(
            EntityState.company_id == principal.company.id,
            EntityState.entity_type == entity_type,
            EntityState.entity_id == entity_id,
        )
    )
    if state is None:
        raise HTTPException(status_code=404, detail="Entidade remota não encontrada.")

    if payload.strategy == "keep_remote":
        resolved_payload = state.payload
    elif payload.strategy == "keep_local":
        if payload.merged_payload is None:
            raise HTTPException(status_code=422, detail="Informe o conteúdo local.")
        resolved_payload = payload.merged_payload
    else:
        if payload.merged_payload is None:
            raise HTTPException(status_code=422, detail="Informe o conteúdo mesclado.")
        resolved_payload = {**state.payload, **payload.merged_payload}

    state.version += 1
    state.payload = resolved_payload
    state.updated_by = principal.user.id

    change = SyncChange(
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=state.farm_id,
        entity_type=entity_type,
        entity_id=entity_id,
        version=state.version,
        payload=resolved_payload,
        deleted=False,
    )
    db.add(change)
    db.commit()

    return {
        "entity_type": entity_type,
        "entity_id": entity_id,
        "version": state.version,
        "payload": resolved_payload,
        "strategy": payload.strategy,
        "justification": payload.justification,
    }


@router.get("/timeline", response_model=list[TimelineItemResponse])
def timeline(
    farm_id: str,
    animal_id: str | None = None,
    limit: int = Query(default=200, ge=1, le=1000),
    principal: Principal = Depends(require_permission("herd.read")),
    db: Session = Depends(get_db),
) -> list[TimelineItemResponse]:
    _farm_allowed(principal, farm_id)
    items: list[TimelineItemResponse] = []

    def add(
        event_id: str,
        event_type: str,
        module: str,
        title: str,
        occurred_at: datetime,
        entity_type: str,
        entity_id: str,
        details: dict,
    ) -> None:
        items.append(
            TimelineItemResponse(
                event_id=event_id,
                event_type=event_type,
                module=module,
                title=title,
                occurred_at=occurred_at,
                entity_type=entity_type,
                entity_id=entity_id,
                details=details,
            )
        )

    queries = [
        (
            AnimalMovement,
            "herd",
            "movement",
            lambda row: f"Movimentação: {row.movement_type}",
            lambda row: row.occurred_at,
            lambda row: row.animal_id,
            lambda row: {"from_lot_id": row.from_lot_id, "to_lot_id": row.to_lot_id},
        ),
        (
            WeightRecord,
            "weight",
            "weight",
            lambda row: f"Pesagem: {row.weight:.1f} kg",
            lambda row: row.measured_at,
            lambda row: row.animal_id,
            lambda row: {"weight": row.weight, "body_condition_score": row.body_condition_score},
        ),
        (
            ReproductionEvent,
            "reproduction",
            "reproduction",
            lambda row: f"Reprodução: {row.event_type}",
            lambda row: row.occurred_at,
            lambda row: row.animal_id,
            lambda row: {"result": row.result, "protocol_name": row.protocol_name},
        ),
        (
            HealthEvent,
            "health",
            "health",
            lambda row: f"Sanidade: {row.event_type}",
            lambda row: row.occurred_at,
            lambda row: row.animal_id or row.lot_id or row.id,
            lambda row: {"product_name": row.product_name, "withdrawal_until": row.withdrawal_until.isoformat() if row.withdrawal_until else None},
        ),
    ]

    for model, module, event_type, title, date_value, entity_value, details in queries:
        query = select(model).where(
            model.company_id == principal.company.id,
            model.farm_id == farm_id,
        )
        if animal_id and hasattr(model, "animal_id"):
            query = query.where(model.animal_id == animal_id)
        for row in db.scalars(query).all():
            add(
                row.id,
                event_type,
                module,
                title(row),
                date_value(row),
                model.__tablename__,
                entity_value(row),
                details(row),
            )

    items.sort(key=lambda item: item.occurred_at, reverse=True)
    return items[:limit]


@router.post("/alerts/generate", response_model=list[OperationalAlertResponse])
def generate_operational_alerts(
    farm_id: str | None = None,
    principal: Principal = Depends(require_permission("herd.read")),
    db: Session = Depends(get_db),
) -> list[OperationalAlert]:
    _farm_allowed(principal, farm_id)
    alerts = generate_alerts(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=farm_id,
    )
    db.commit()
    return alerts


@router.get("/alerts", response_model=list[OperationalAlertResponse])
def list_alerts(
    farm_id: str | None = None,
    status_filter: str = Query(default="open", alias="status"),
    principal: Principal = Depends(require_permission("herd.read")),
    db: Session = Depends(get_db),
) -> list[OperationalAlert]:
    _farm_allowed(principal, farm_id)
    query = select(OperationalAlert).where(
        OperationalAlert.company_id == principal.company.id,
        OperationalAlert.status == status_filter,
    )
    if farm_id:
        query = query.where(OperationalAlert.farm_id == farm_id)
    return list(db.scalars(query.order_by(OperationalAlert.created_at.desc())).all())


@router.post("/alerts/{alert_id}/task", response_model=OperationalTaskResponse)
def alert_to_task(
    alert_id: str,
    principal: Principal = Depends(require_permission("herd.write")),
    db: Session = Depends(get_db),
) -> OperationalTask:
    alert = db.get(OperationalAlert, alert_id)
    if alert is None or alert.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Alerta não encontrado.")
    _farm_allowed(principal, alert.farm_id)
    task = OperationalTask(
        id=new_id("task"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=alert.farm_id,
        source_type="alert",
        source_id=alert.id,
        title=alert.title,
        description=alert.description,
        priority="urgent" if alert.severity == "high" else "medium",
        due_at=alert.due_at,
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@router.post("/tasks", response_model=OperationalTaskResponse, status_code=201)
def create_task(
    payload: OperationalTaskCreateRequest,
    principal: Principal = Depends(require_permission("herd.write")),
    db: Session = Depends(get_db),
) -> OperationalTask:
    _farm_allowed(principal, payload.farm_id)
    task = OperationalTask(
        id=new_id("task"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return task


@router.get("/tasks", response_model=list[OperationalTaskResponse])
def list_tasks(
    farm_id: str | None = None,
    status_filter: str = Query(default="open", alias="status"),
    principal: Principal = Depends(require_permission("herd.read")),
    db: Session = Depends(get_db),
) -> list[OperationalTask]:
    _farm_allowed(principal, farm_id)
    query = select(OperationalTask).where(
        OperationalTask.company_id == principal.company.id,
        OperationalTask.status == status_filter,
    )
    if farm_id:
        query = query.where(OperationalTask.farm_id == farm_id)
    return list(db.scalars(query.order_by(OperationalTask.created_at.desc())).all())


@router.patch("/tasks/{task_id}", response_model=OperationalTaskResponse)
def update_task(
    task_id: str,
    payload: OperationalTaskUpdateRequest,
    principal: Principal = Depends(require_permission("herd.write")),
    db: Session = Depends(get_db),
) -> OperationalTask:
    task = db.get(OperationalTask, task_id)
    if task is None or task.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Tarefa não encontrada.")
    _farm_allowed(principal, task.farm_id)
    changes = payload.model_dump(exclude_unset=True)
    source_backed = bool(task.source_id) and task.source_type in {
        "reproduction_event", "health_event", "consultancy_action"
    }
    if source_backed:
        changes.pop("source_type", None)
    due_at_changed = "due_at" in changes
    for field, value in changes.items():
        setattr(task, field, value)
    if task.status == "completed" and task.completed_at is None:
        task.completed_at = datetime.now(timezone.utc)
    elif task.status != "completed":
        task.completed_at = None

    if task.source_type == "consultancy_action" and task.source_id:
        action = db.scalar(
            select(AtlasActionPlanItem).where(
                AtlasActionPlanItem.id == task.source_id,
                AtlasActionPlanItem.company_id == principal.company.id,
                AtlasActionPlanItem.farm_id == task.farm_id,
            )
        )
        if action is not None:
            action.title = task.title
            action.description = task.description
            action.priority = "critical" if task.priority == "urgent" else task.priority
            action.due_at = task.due_at
            action.status = task.status
            action.completed_at = task.completed_at
            if task.status == "completed" and task.evidence.strip():
                action.actual_result = task.evidence.strip()

    if source_backed and due_at_changed:
        if task.source_type == "reproduction_event":
            event = db.scalar(
                select(ReproductionEvent).where(
                    ReproductionEvent.id == task.source_id,
                    ReproductionEvent.company_id == principal.company.id,
                    ReproductionEvent.farm_id == task.farm_id,
                )
            )
            if event is not None:
                event.expected_date = task.due_at
        elif task.source_type == "health_event":
            event = db.scalar(
                select(HealthEvent).where(
                    HealthEvent.id == task.source_id,
                    HealthEvent.company_id == principal.company.id,
                    HealthEvent.farm_id == task.farm_id,
                )
            )
            if event is not None:
                event.next_date = task.due_at

    db.commit()
    db.refresh(task)
    return task


@router.post("/indicators/generate", response_model=list[IndicatorSnapshotResponse])
def generate_indicators(
    farm_id: str | None = None,
    principal: Principal = Depends(require_permission("finance.read")),
    db: Session = Depends(get_db),
) -> list[IndicatorSnapshot]:
    _farm_allowed(principal, farm_id)
    snapshots = build_indicators(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=farm_id,
    )
    db.commit()
    return snapshots


@router.get("/indicators", response_model=list[IndicatorSnapshotResponse])
def list_indicators(
    farm_id: str | None = None,
    principal: Principal = Depends(require_permission("finance.read")),
    db: Session = Depends(get_db),
) -> list[IndicatorSnapshot]:
    _farm_allowed(principal, farm_id)
    query = select(IndicatorSnapshot).where(
        IndicatorSnapshot.company_id == principal.company.id,
    )
    if farm_id:
        query = query.where(IndicatorSnapshot.farm_id == farm_id)
    return list(db.scalars(query.order_by(IndicatorSnapshot.generated_at.desc())).all())


@router.get("/exports/{dataset}.csv")
def export_csv(
    dataset: str,
    farm_id: str,
    principal: Principal = Depends(require_permission("herd.read")),
    db: Session = Depends(get_db),
) -> Response:
    _farm_allowed(principal, farm_id)
    model_map = {
        "animals": LivestockAnimal,
        "health": HealthEvent,
        "reproduction": ReproductionEvent,
        "nutrition": NutritionEvent,
        "finance": FinancialEntry,
        "inventory": InventoryMovement,
    }
    model = model_map.get(dataset)
    if model is None:
        raise HTTPException(status_code=404, detail="Conjunto de dados inválido.")

    rows = db.scalars(
        select(model).where(
            model.company_id == principal.company.id,
            model.farm_id == farm_id,
        )
    ).all()

    output = io.StringIO()
    if not rows:
        output.write("")
    else:
        columns = [column.name for column in model.__table__.columns]
        writer = csv.DictWriter(output, fieldnames=columns)
        writer.writeheader()
        for row in rows:
            writer.writerow(
                {
                    column: (
                        json.dumps(getattr(row, column), ensure_ascii=False)
                        if isinstance(getattr(row, column), (dict, list))
                        else getattr(row, column)
                    )
                    for column in columns
                }
            )

    return Response(
        content=output.getvalue(),
        media_type="text/csv; charset=utf-8",
        headers={
            "Content-Disposition": f'attachment; filename="atlas_{dataset}_{farm_id}.csv"'
        },
    )


@router.get("/reports/executive")
def executive_report_data(
    farm_id: str,
    principal: Principal = Depends(require_permission("finance.read")),
    db: Session = Depends(get_db),
) -> dict:
    _farm_allowed(principal, farm_id)
    indicators = build_indicators(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=farm_id,
    )
    alerts = generate_alerts(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=farm_id,
    )
    db.commit()
    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "company": {
            "id": principal.company.id,
            "name": principal.company.name,
        },
        "farm_id": farm_id,
        "indicators": [
            {
                "key": item.indicator_key,
                "name": item.indicator_name,
                "value": item.value,
                "unit": item.unit,
                "formula": item.formula,
                "sources": item.source_tables,
            }
            for item in indicators
        ],
        "alerts": [
            {
                "id": item.id,
                "severity": item.severity,
                "title": item.title,
                "description": item.description,
            }
            for item in alerts
        ],
    }
