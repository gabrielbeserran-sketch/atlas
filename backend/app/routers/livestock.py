
from __future__ import annotations

from collections import defaultdict

from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.services.concurrency import advisory_transaction_lock

from ..authz import Principal, get_principal, require_permission
from ..database import get_db
from ..models import (
    AnimalMovement,
    FinancialEntry,
    HealthEvent,
    HealthProtocol,
    HerdLot,
    InventoryMovement,
    InventoryProduct,
    LivestockAnimal,
    NutritionEvent,
    ReproductionEvent,
    WeightRecord,
    new_id,
    NutritionIngredient,
    NutritionPlan,
    Paddock,
    OperationalTask,
)
from ..schemas import (
    AnimalMovementRequest,
    AnimalMovementResponse,
    FinancialEntryCreateRequest,
    FinancialEntryResponse,
    HealthEventCreateRequest,
    HealthEventUpdateRequest,
    HealthEventResponse,
    HealthProtocolApplyRequest,
    HealthProtocolCreateRequest,
    HealthProtocolResponse,
    HerdLotCreateRequest,
    HerdLotResponse,
    HerdLotUpdateRequest,
    InventoryMovementRequest,
    InventoryProductCreateRequest,
    InventoryProductResponse,
    LivestockAnimalCreateRequest,
    LivestockAnimalResponse,
    LivestockAnimalUpdateRequest,
    NutritionEventCreateRequest,
    NutritionEventResponse,
    ReproductionEventCreateRequest,
    ReproductionEventUpdateRequest,
    ReproductionEventResponse,
    ReproductionSummaryResponse,
    WeightCreateRequest,
    WeightResponse,
    InventoryProductPhase2CreateRequest,
    InventoryMovementPhase2Request,
    InventoryMovementPhase2Response,
    InventoryAlertResponse,
    NutritionIngredientCreateRequest,
    NutritionIngredientResponse,
    NutritionPlanCreateRequest,
    NutritionPlanResponse,
    NutritionConsumptionRequest,
    FinancialEntryPhase3CreateRequest,
    FinancialEntryPhase3Response,
    FinancialSettlementRequest,
    FinancialSummaryResponse,
    PaddockCreateRequest,
    PaddockUpdateRequest,
    PaddockResponse,
    AnimalTimelineResponse,
)

router = APIRouter(prefix="/livestock", tags=["livestock"])


def _farm_allowed(principal: Principal, farm_id: str) -> None:
    if principal.membership.role in {"owner", "admin"}:
        return
    allowed = set(principal.membership.farm_ids or [])
    if allowed and farm_id not in allowed:
        raise HTTPException(status_code=403, detail="Fazenda não autorizada.")


def _animal(db: Session, principal: Principal, animal_id: str) -> LivestockAnimal:
    item = db.scalar(
        select(LivestockAnimal).where(
            LivestockAnimal.id == animal_id,
            LivestockAnimal.company_id == principal.company.id,
        )
    )
    if item is None:
        raise HTTPException(status_code=404, detail="Animal não encontrado.")
    _farm_allowed(principal, item.farm_id)
    return item


def _sync_operational_task(
    *,
    db: Session,
    principal: Principal,
    farm_id: str,
    source_type: str,
    source_id: str,
    title: str,
    description: str,
    due_at: datetime | None,
    priority: str = "medium",
) -> OperationalTask | None:
    tasks = list(
        db.scalars(
            select(OperationalTask)
            .where(
                OperationalTask.company_id == principal.company.id,
                OperationalTask.farm_id == farm_id,
                OperationalTask.source_type == source_type,
                OperationalTask.source_id == source_id,
            )
            .order_by(OperationalTask.created_at.asc())
        ).all()
    )
    task = tasks[0] if tasks else None
    for duplicate in tasks[1:]:
        duplicate.status = "cancelled"

    if due_at is None:
        if task is not None and task.status not in {"completed", "cancelled"}:
            task.status = "cancelled"
        return task

    if task is None:
        task = OperationalTask(
            id=new_id("task"),
            tenant_id=principal.company.tenant_id,
            company_id=principal.company.id,
            farm_id=farm_id,
            source_type=source_type,
            source_id=source_id,
            title=title,
            description=description,
            priority=priority,
            due_at=due_at,
            status="open",
        )
        db.add(task)
        return task

    task.title = title
    task.description = description
    task.priority = priority
    task.due_at = due_at
    if task.status == "cancelled":
        task.status = "open"
    return task


def _delete_source_tasks(
    *,
    db: Session,
    principal: Principal,
    source_type: str,
    source_id: str,
) -> None:
    tasks = db.scalars(
        select(OperationalTask).where(
            OperationalTask.company_id == principal.company.id,
            OperationalTask.source_type == source_type,
            OperationalTask.source_id == source_id,
        )
    ).all()
    for task in tasks:
        db.delete(task)


def _refresh_animal_reproduction_state(
    *,
    db: Session,
    animal: LivestockAnimal,
) -> None:
    latest = db.scalar(
        select(ReproductionEvent)
        .where(ReproductionEvent.animal_id == animal.id)
        .order_by(ReproductionEvent.occurred_at.desc())
        .limit(1)
    )
    if latest is None:
        animal.last_reproduction_event_at = None
        animal.reproductive_status = ""
        animal.expected_calving_at = None
        return
    animal.last_reproduction_event_at = latest.occurred_at
    animal.reproductive_status = latest.reproductive_status or ""
    if latest.event_code == "pregnancy_diagnosis" and latest.reproductive_status == "pregnant":
        animal.expected_calving_at = latest.expected_date or (
            latest.occurred_at.replace(microsecond=0)
            + timedelta(days=max(0, 283 - latest.pregnancy_days))
        )
    elif latest.event_code in {"calving", "abortion", "reproductive_cull"}:
        animal.expected_calving_at = None


def _lot(db: Session, principal: Principal, lot_id: str) -> HerdLot:
    item = db.scalar(
        select(HerdLot).where(
            HerdLot.id == lot_id,
            HerdLot.company_id == principal.company.id,
        )
    )
    if item is None:
        raise HTTPException(status_code=404, detail="Lote não encontrado.")
    _farm_allowed(principal, item.farm_id)
    return item


@router.post("/lots", response_model=HerdLotResponse, status_code=201)
def create_lot(
    payload: HerdLotCreateRequest,
    principal: Principal = Depends(require_permission("herd.write")),
    db: Session = Depends(get_db),
) -> HerdLot:
    _farm_allowed(principal, payload.farm_id)
    item = HerdLot(
        id=new_id("lot"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=payload.farm_id,
        name=payload.name.strip(),
        category=payload.category.strip(),
        capacity=payload.capacity,
        paddock=payload.paddock.strip(),
        notes=payload.notes.strip(),
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Lote duplicado.") from exc
    db.refresh(item)
    return item


@router.get("/lots", response_model=list[HerdLotResponse])
def list_lots(
    farm_id: str,
    active_only: bool = True,
    principal: Principal = Depends(require_permission("herd.read")),
    db: Session = Depends(get_db),
) -> list[HerdLot]:
    _farm_allowed(principal, farm_id)
    query = select(HerdLot).where(
        HerdLot.company_id == principal.company.id,
        HerdLot.farm_id == farm_id,
    )
    if active_only:
        query = query.where(HerdLot.status == "active")
    return list(db.scalars(query.order_by(HerdLot.name)).all())


@router.patch("/lots/{lot_id}", response_model=HerdLotResponse)
def update_lot(
    lot_id: str,
    payload: HerdLotUpdateRequest,
    principal: Principal = Depends(require_permission("herd.write")),
    db: Session = Depends(get_db),
) -> HerdLot:
    item = _lot(db, principal, lot_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(item, field, value.strip() if isinstance(value, str) else value)
    db.commit()
    db.refresh(item)
    return item


@router.delete(
    "/lots/{lot_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    response_model=None,
)
def deactivate_lot(
    lot_id: str,
    principal: Principal = Depends(require_permission("herd.write")),
    db: Session = Depends(get_db),
) -> Response:
    item = _lot(db, principal, lot_id)
    animal_count = db.scalar(
        select(func.count(LivestockAnimal.id)).where(
            LivestockAnimal.company_id == principal.company.id,
            LivestockAnimal.lot_id == item.id,
            LivestockAnimal.status.in_(["active", "Ativo"]),
        )
    ) or 0
    if animal_count > 0:
        raise HTTPException(
            status_code=409,
            detail="Mova os animais ativos antes de inativar o lote.",
        )
    item.status = "inactive"
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/animals", response_model=LivestockAnimalResponse, status_code=201)
def create_animal(
    payload: LivestockAnimalCreateRequest,
    principal: Principal = Depends(require_permission("animals.create")),
    db: Session = Depends(get_db),
) -> LivestockAnimal:
    _farm_allowed(principal, payload.farm_id)
    if payload.lot_id:
        lot = _lot(db, principal, payload.lot_id)
        if lot.farm_id != payload.farm_id:
            raise HTTPException(status_code=422, detail="Lote pertence a outra fazenda.")

    tag = payload.tag.strip()
    sisbov = payload.sisbov.strip()
    duplicate_query = select(LivestockAnimal).where(
        LivestockAnimal.company_id == principal.company.id,
        or_(
            LivestockAnimal.tag == tag,
            LivestockAnimal.sisbov == sisbov if sisbov else False,
        ),
    )
    if db.scalar(duplicate_query):
        raise HTTPException(status_code=409, detail="Brinco ou SISBOV já cadastrado.")

    item = LivestockAnimal(
        id=new_id("animal"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    item.tag = tag
    item.sisbov = sisbov
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.get("/animals", response_model=list[LivestockAnimalResponse])
def list_animals(
    farm_id: str,
    lot_id: str | None = None,
    status_filter: str | None = Query(default=None, alias="status"),
    search: str = "",
    principal: Principal = Depends(require_permission("animals.read")),
    db: Session = Depends(get_db),
) -> list[LivestockAnimal]:
    _farm_allowed(principal, farm_id)
    query = select(LivestockAnimal).where(
        LivestockAnimal.company_id == principal.company.id,
        LivestockAnimal.farm_id == farm_id,
        LivestockAnimal.status != "Excluído",
    )
    if lot_id:
        query = query.where(LivestockAnimal.lot_id == lot_id)
    if status_filter:
        query = query.where(LivestockAnimal.status == status_filter)
    if search.strip():
        term = f"%{search.strip()}%"
        query = query.where(
            or_(
                LivestockAnimal.tag.ilike(term),
                LivestockAnimal.sisbov.ilike(term),
                LivestockAnimal.name.ilike(term),
            )
        )
    return list(db.scalars(query.order_by(LivestockAnimal.tag)).all())



@router.get(
    "/animals/{animal_id}/timeline",
    response_model=list[AnimalTimelineResponse],
)
def livestock_animal_timeline(
    animal_id: str,
    principal: Principal = Depends(require_permission("animals.read")),
    db: Session = Depends(get_db),
) -> list[AnimalTimelineResponse]:
    """Timeline Enterprise do animal oficial do módulo Rebanho.

    O Flutter cria e lê animais em ``livestock_animals``. A timeline antiga
    consultava o domínio legado ``EntityState`` em ``/animals/{id}/timeline``,
    por isso animais válidos do Rebanho retornavam 404.

    Esta rota consolida os eventos que já pertencem ao domínio pecuário real:
    cadastro, movimentações, pesagens, reprodução e sanidade.
    """
    animal = _animal(db, principal, animal_id)

    records: list[AnimalTimelineResponse] = [
        AnimalTimelineResponse(
            id=f"animal_create_{animal.id}",
            action="create",
            category="Cadastro",
            title="Animal cadastrado",
            description=f'Animal "{animal.tag}" cadastrado no rebanho.',
            before={},
            after={
                "tag": animal.tag,
                "name": animal.name,
                "farm_id": animal.farm_id,
                "lot_id": animal.lot_id,
                "category": animal.category,
                "sex": animal.sex,
                "breed": animal.breed,
                "weight": animal.current_weight,
                "body_condition_score": animal.body_condition_score,
                "status": animal.status,
            },
            user_id="",
            occurred_at=animal.created_at,
        )
    ]

    movements = db.scalars(
        select(AnimalMovement).where(
            AnimalMovement.company_id == principal.company.id,
            AnimalMovement.tenant_id == principal.company.tenant_id,
            AnimalMovement.animal_id == animal.id,
        )
    ).all()
    for movement in movements:
        records.append(
            AnimalTimelineResponse(
                id=movement.id,
                action="update",
                category="Manejo",
                title="Movimentação de animal",
                description=movement.reason or movement.movement_type,
                before={"lot_id": movement.from_lot_id},
                after={
                    "lot_id": movement.to_lot_id,
                    "movement_type": movement.movement_type,
                    "document_reference": movement.document_reference,
                },
                user_id=movement.created_by,
                occurred_at=movement.occurred_at,
            )
        )

    weights = db.scalars(
        select(WeightRecord).where(
            WeightRecord.company_id == principal.company.id,
            WeightRecord.tenant_id == principal.company.tenant_id,
            WeightRecord.animal_id == animal.id,
        )
    ).all()
    for record in weights:
        records.append(
            AnimalTimelineResponse(
                id=record.id,
                action="update",
                category="Pesagem",
                title="Pesagem registrada",
                description=record.notes or "Peso e escore corporal registrados.",
                before={},
                after={
                    "weight": record.weight,
                    "body_condition_score": record.body_condition_score,
                    "source": record.source,
                    "equipment": record.equipment,
                },
                user_id=record.created_by,
                occurred_at=record.measured_at,
            )
        )

    reproduction_events = db.scalars(
        select(ReproductionEvent).where(
            ReproductionEvent.company_id == principal.company.id,
            ReproductionEvent.tenant_id == principal.company.tenant_id,
            ReproductionEvent.animal_id == animal.id,
        )
    ).all()
    for event in reproduction_events:
        records.append(
            AnimalTimelineResponse(
                id=event.id,
                action="update",
                category="Reprodução",
                title=event.event_type or "Evento reprodutivo",
                description=event.notes or event.result,
                before={},
                after={
                    "event_code": event.event_code,
                    "result": event.result,
                    "reproductive_status": event.reproductive_status,
                    "protocol_name": event.protocol_name,
                    "sire_reference": event.sire_reference,
                },
                user_id=event.created_by,
                occurred_at=event.occurred_at,
            )
        )

    health_events = db.scalars(
        select(HealthEvent).where(
            HealthEvent.company_id == principal.company.id,
            HealthEvent.tenant_id == principal.company.tenant_id,
            HealthEvent.animal_id == animal.id,
        )
    ).all()
    for event in health_events:
        records.append(
            AnimalTimelineResponse(
                id=event.id,
                action="update",
                category="Sanidade",
                title=event.event_type or "Evento sanitário",
                description=event.notes or event.diagnosis or event.product_name,
                before={},
                after={
                    "product_name": event.product_name,
                    "dosage": event.dosage,
                    "route": event.route,
                    "diagnosis": event.diagnosis,
                    "severity": event.severity,
                    "status": event.status,
                },
                user_id=event.created_by,
                occurred_at=event.occurred_at,
            )
        )

    records.sort(key=lambda item: item.occurred_at, reverse=True)
    return records


@router.get("/animals/{animal_id}", response_model=LivestockAnimalResponse)
def get_animal(
    animal_id: str,
    principal: Principal = Depends(require_permission("animals.read")),
    db: Session = Depends(get_db),
) -> LivestockAnimal:
    return _animal(db, principal, animal_id)


@router.patch("/animals/{animal_id}", response_model=LivestockAnimalResponse)
def update_animal(
    animal_id: str,
    payload: LivestockAnimalUpdateRequest,
    principal: Principal = Depends(require_permission("animals.update")),
    db: Session = Depends(get_db),
) -> LivestockAnimal:
    item = _animal(db, principal, animal_id)
    changes = payload.model_dump(exclude_unset=True)
    if "lot_id" in changes and changes["lot_id"]:
        lot = _lot(db, principal, changes["lot_id"])
        if lot.farm_id != item.farm_id:
            raise HTTPException(status_code=422, detail="Lote pertence a outra fazenda.")
    for field, value in changes.items():
        setattr(item, field, value.strip() if isinstance(value, str) else value)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Brinco ou SISBOV duplicado.") from exc
    db.refresh(item)
    return item


@router.delete(
    "/animals/{animal_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    response_model=None,
)
def delete_animal(
    animal_id: str,
    principal: Principal = Depends(require_permission("animals.delete")),
    db: Session = Depends(get_db),
) -> Response:
    item = _animal(db, principal, animal_id)
    item.status = "Excluído"
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/animals/{animal_id}/movements", response_model=AnimalMovementResponse, status_code=201)
def move_animal(
    animal_id: str,
    payload: AnimalMovementRequest,
    principal: Principal = Depends(require_permission("herd.write")),
    db: Session = Depends(get_db),
) -> AnimalMovement:
    animal = _animal(db, principal, animal_id)
    previous_lot = animal.lot_id
    movement_type = payload.movement_type.strip().lower()
    lot_change_types = {"lot_change", "entry"}
    exit_types = {"sale", "death", "discard", "exit"}

    if movement_type == "lot_change" and not payload.to_lot_id:
        raise HTTPException(
            status_code=422,
            detail="A mudança de lote exige um lote de destino.",
        )

    if payload.to_lot_id:
        target = _lot(db, principal, payload.to_lot_id)
        if target.farm_id != animal.farm_id:
            raise HTTPException(status_code=422, detail="Lote de destino pertence a outra fazenda.")
        if target.status != "active":
            raise HTTPException(status_code=422, detail="Lote de destino está inativo.")

    movement = AnimalMovement(
        id=new_id("movement"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=animal.farm_id,
        animal_id=animal.id,
        movement_type=movement_type,
        from_lot_id=previous_lot,
        to_lot_id=payload.to_lot_id,
        occurred_at=payload.occurred_at or datetime.now(timezone.utc),
        reason=payload.reason,
        document_reference=payload.document_reference,
        created_by=principal.user.id,
    )

    if movement_type in lot_change_types and payload.to_lot_id:
        animal.lot_id = payload.to_lot_id
        animal.status = "active"
    elif movement_type in exit_types:
        animal.lot_id = None
        animal.status = movement_type
    db.add(movement)
    db.commit()
    db.refresh(movement)
    return movement


@router.get("/animals/{animal_id}/movements", response_model=list[AnimalMovementResponse])
def movement_history(
    animal_id: str,
    principal: Principal = Depends(require_permission("herd.read")),
    db: Session = Depends(get_db),
) -> list[AnimalMovement]:
    _animal(db, principal, animal_id)
    return list(
        db.scalars(
            select(AnimalMovement)
            .where(AnimalMovement.animal_id == animal_id)
            .order_by(AnimalMovement.occurred_at.desc())
        ).all()
    )


@router.post("/animals/{animal_id}/weights", response_model=WeightResponse, status_code=201)
def add_weight(
    animal_id: str,
    payload: WeightCreateRequest,
    principal: Principal = Depends(require_permission("herd.write")),
    db: Session = Depends(get_db),
) -> WeightRecord:
    animal = _animal(db, principal, animal_id)
    item = WeightRecord(
        id=new_id("weight"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=animal.farm_id,
        animal_id=animal.id,
        weight=payload.weight,
        body_condition_score=payload.body_condition_score,
        source=payload.source,
        equipment=payload.equipment,
        measured_at=payload.measured_at or datetime.now(timezone.utc),
        notes=payload.notes,
        created_by=principal.user.id,
    )
    db.add(item)
    db.flush()

    latest_weight = db.scalar(
        select(WeightRecord)
        .where(WeightRecord.animal_id == animal.id)
        .order_by(WeightRecord.measured_at.desc(), WeightRecord.id.desc())
        .limit(1)
    )
    if latest_weight is not None and latest_weight.id == item.id:
        animal.current_weight = item.weight
        animal.body_condition_score = item.body_condition_score

    db.commit()
    db.refresh(item)
    return item


@router.get("/animals/{animal_id}/weights", response_model=list[WeightResponse])
def weight_history(
    animal_id: str,
    principal: Principal = Depends(require_permission("herd.read")),
    db: Session = Depends(get_db),
) -> list[WeightRecord]:
    _animal(db, principal, animal_id)
    return list(
        db.scalars(
            select(WeightRecord)
            .where(WeightRecord.animal_id == animal_id)
            .order_by(WeightRecord.measured_at.desc())
        ).all()
    )


REPRODUCTION_CODES = {
    "Cio": "estrus", "Inseminação artificial": "ai", "IATF": "iatf",
    "Monta natural": "natural_service", "Diagnóstico de gestação": "pregnancy_diagnosis",
    "Parto": "calving", "Aborto": "abortion", "Repetição de cio": "repeat_estrus",
    "Descarte reprodutivo": "reproductive_cull", "Protocolo hormonal": "hormonal_protocol",
}


def _derive_reproductive_status(payload: ReproductionEventCreateRequest) -> str:
    if payload.reproductive_status.strip():
        return payload.reproductive_status.strip()
    code = payload.event_code or REPRODUCTION_CODES.get(payload.event_type, "observation")
    result = payload.result.lower()
    if code in {"ai", "iatf", "natural_service"}: return "awaiting_diagnosis"
    if code == "pregnancy_diagnosis":
        return "pregnant" if any(x in result for x in ("prenhe", "positivo", "positive")) else "open"
    if code == "calving": return "calved"
    if code == "abortion": return "open"
    if code == "reproductive_cull": return "culled"
    return ""


REPRODUCTION_CODES = {
    "Cio": "estrus", "Inseminação artificial": "ai", "IATF": "iatf",
    "Monta natural": "natural_service", "Diagnóstico de gestação": "pregnancy_diagnosis",
    "Parto": "calving", "Aborto": "abortion", "Repetição de cio": "repeat_estrus",
    "Descarte reprodutivo": "reproductive_cull", "Protocolo hormonal": "hormonal_protocol",
}


def _derive_reproductive_status(payload: ReproductionEventCreateRequest) -> str:
    if payload.reproductive_status.strip():
        return payload.reproductive_status.strip()
    code = payload.event_code or REPRODUCTION_CODES.get(payload.event_type, "observation")
    result = payload.result.lower()
    if code in {"ai", "iatf", "natural_service"}: return "awaiting_diagnosis"
    if code == "pregnancy_diagnosis":
        return "pregnant" if any(x in result for x in ("prenhe", "positivo", "positive")) else "open"
    if code == "calving": return "calved"
    if code == "abortion": return "open"
    if code == "reproductive_cull": return "culled"
    return ""


@router.post("/animals/{animal_id}/reproduction", response_model=ReproductionEventResponse, status_code=201)
def add_reproduction_event(
    animal_id: str,
    payload: ReproductionEventCreateRequest,
    principal: Principal = Depends(require_permission("reproduction.write")),
    db: Session = Depends(get_db),
) -> ReproductionEvent:
    animal = _animal(db, principal, animal_id)
    occurred_at = payload.occurred_at or datetime.now(timezone.utc)
    status_value = _derive_reproductive_status(payload)
    event_code = payload.event_code or REPRODUCTION_CODES.get(payload.event_type, "observation")
    item = ReproductionEvent(
        id=new_id("reproduction"), tenant_id=principal.company.tenant_id,
        company_id=principal.company.id, farm_id=animal.farm_id, animal_id=animal.id,
        event_code=event_code, reproductive_status=status_value,
        occurred_at=occurred_at, created_by=principal.user.id,
        **payload.model_dump(exclude={"occurred_at", "event_code", "reproductive_status"}),
    )
    animal.last_reproduction_event_at = occurred_at
    if status_value: animal.reproductive_status = status_value
    if event_code == "pregnancy_diagnosis" and status_value == "pregnant":
        animal.expected_calving_at = payload.expected_date or occurred_at.replace(microsecond=0) + timedelta(days=max(0, 283 - payload.pregnancy_days))
    elif event_code in {"calving", "abortion", "reproductive_cull"}:
        animal.expected_calving_at = None
    db.add_all([item, animal])
    _sync_operational_task(
        db=db,
        principal=principal,
        farm_id=animal.farm_id,
        source_type="reproduction_event",
        source_id=item.id,
        title=f"{payload.event_type} — {animal.name or animal.tag or animal.id}",
        description=f"Retorno reprodutivo de {animal.name or animal.tag or animal.id}.",
        due_at=payload.expected_date,
        priority="high" if event_code == "pregnancy_diagnosis" else "medium",
    )
    db.commit(); db.refresh(item)
    return item


@router.patch("/animals/{animal_id}/reproduction/{event_id}", response_model=ReproductionEventResponse)
def update_reproduction_event(
    animal_id: str,
    event_id: str,
    payload: ReproductionEventUpdateRequest,
    principal: Principal = Depends(require_permission("reproduction.write")),
    db: Session = Depends(get_db),
) -> ReproductionEvent:
    animal = _animal(db, principal, animal_id)
    item = db.scalar(
        select(ReproductionEvent).where(
            ReproductionEvent.id == event_id,
            ReproductionEvent.company_id == principal.company.id,
            ReproductionEvent.animal_id == animal.id,
        )
    )
    if item is None:
        raise HTTPException(status_code=404, detail="Evento reprodutivo não encontrado.")
    changes = payload.model_dump(exclude_unset=True)
    for field, value in changes.items():
        setattr(item, field, value)
    if "event_type" in changes and "event_code" not in changes:
        item.event_code = REPRODUCTION_CODES.get(item.event_type, item.event_code or "observation")
    if "reproductive_status" not in changes:
        probe = ReproductionEventCreateRequest(
            event_type=item.event_type, event_code=item.event_code, result=item.result,
            reproductive_status="", pregnancy_days=item.pregnancy_days,
        )
        item.reproductive_status = _derive_reproductive_status(probe)
    db.flush()
    _refresh_animal_reproduction_state(db=db, animal=animal)
    _sync_operational_task(
        db=db, principal=principal, farm_id=animal.farm_id,
        source_type="reproduction_event", source_id=item.id,
        title=f"{item.event_type} — {animal.name or animal.tag or animal.id}",
        description=f"Retorno reprodutivo de {animal.name or animal.tag or animal.id}.",
        due_at=item.expected_date,
        priority="high" if item.event_code == "pregnancy_diagnosis" else "medium",
    )
    db.commit(); db.refresh(item)
    return item


@router.delete(
    "/animals/{animal_id}/reproduction/{event_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    response_model=None,
)
def delete_reproduction_event(
    animal_id: str,
    event_id: str,
    principal: Principal = Depends(require_permission("reproduction.write")),
    db: Session = Depends(get_db),
) -> Response:
    animal = _animal(db, principal, animal_id)
    item = db.scalar(
        select(ReproductionEvent).where(
            ReproductionEvent.id == event_id,
            ReproductionEvent.company_id == principal.company.id,
            ReproductionEvent.animal_id == animal.id,
        )
    )
    if item is None:
        raise HTTPException(status_code=404, detail="Evento reprodutivo não encontrado.")
    _delete_source_tasks(
        db=db, principal=principal, source_type="reproduction_event", source_id=item.id
    )
    db.delete(item)
    db.flush()
    _refresh_animal_reproduction_state(db=db, animal=animal)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/animals/{animal_id}/reproduction", response_model=list[ReproductionEventResponse])
def reproduction_history(
    animal_id: str,
    principal: Principal = Depends(require_permission("reproduction.read")),
    db: Session = Depends(get_db),
) -> list[ReproductionEvent]:
    _animal(db, principal, animal_id)
    return list(
        db.scalars(
            select(ReproductionEvent)
            .where(ReproductionEvent.animal_id == animal_id)
            .order_by(ReproductionEvent.occurred_at.desc())
        ).all()
    )


@router.get("/reproduction/summary", response_model=ReproductionSummaryResponse)
def reproduction_summary(
    farm_id: str,
    principal: Principal = Depends(require_permission("reproduction.read")),
    db: Session = Depends(get_db),
) -> ReproductionSummaryResponse:
    _farm_allowed(principal, farm_id)
    animals = list(db.scalars(select(LivestockAnimal).where(LivestockAnimal.company_id == principal.company.id, LivestockAnimal.farm_id == farm_id, LivestockAnimal.sex.ilike("%f%"))).all())
    events = list(db.scalars(select(ReproductionEvent).where(ReproductionEvent.company_id == principal.company.id, ReproductionEvent.farm_id == farm_id)).all())
    serviced = {e.animal_id for e in events if e.event_code in {"ai", "iatf", "natural_service"}}
    diagnosed = {e.animal_id for e in events if e.event_code == "pregnancy_diagnosis"}
    pregnant = {e.animal_id for e in events if e.event_code == "pregnancy_diagnosis" and e.reproductive_status == "pregnant"}
    services = sum(1 for e in events if e.event_code in {"ai", "iatf", "natural_service"})
    calvings = sum(1 for e in events if e.event_code == "calving")
    abortions = sum(1 for e in events if e.event_code == "abortion")
    total = len(animals)
    now = datetime.now(timezone.utc)
    upcoming = [{"event_id": e.id, "animal_id": e.animal_id, "type": e.event_type, "due_at": e.expected_date.isoformat()} for e in events if e.expected_date and e.expected_date >= now][:100]
    return ReproductionSummaryResponse(
        farm_id=farm_id, total_females=total, serviced_animals=len(serviced), diagnosed_animals=len(diagnosed),
        pregnant_animals=len(pregnant), calvings=calvings, abortions=abortions, services=services,
        service_rate=round(len(serviced)*100/total,2) if total else 0,
        conception_rate=round(len(pregnant)*100/services,2) if services else 0,
        pregnancy_rate=round(len(pregnant)*100/total,2) if total else 0,
        services_per_conception=round(services/len(pregnant),2) if pregnant else 0,
        upcoming_actions=sorted(upcoming, key=lambda x:x["due_at"]),
    )


@router.post("/health", response_model=HealthEventResponse, status_code=201)
def add_health_event(
    payload: HealthEventCreateRequest,
    principal: Principal = Depends(require_permission("health.write")),
    db: Session = Depends(get_db),
) -> HealthEvent:
    _farm_allowed(principal, payload.farm_id)
    if not payload.animal_id and not payload.lot_id:
        raise HTTPException(status_code=422, detail="Informe animal_id ou lot_id.")
    if payload.animal_id:
        animal = _animal(db, principal, payload.animal_id)
        if animal.farm_id != payload.farm_id:
            raise HTTPException(status_code=422, detail="Animal pertence a outra fazenda.")
    if payload.lot_id:
        lot = _lot(db, principal, payload.lot_id)
        if lot.farm_id != payload.farm_id:
            raise HTTPException(status_code=422, detail="Lote pertence a outra fazenda.")
    item = HealthEvent(
        id=new_id("health"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        created_by=principal.user.id,
        occurred_at=payload.occurred_at or datetime.now(timezone.utc),
        **payload.model_dump(exclude={"occurred_at"}),
    )
    db.add(item)
    occurred_at = item.occurred_at
    if payload.inventory_product_id and payload.inventory_quantity > 0:
        product = _inventory_product(db, principal, payload.inventory_product_id)
        if product.farm_id != payload.farm_id:
            raise HTTPException(status_code=422, detail="Produto pertence a outra fazenda.")
        _apply_stock_movement(
            db=db, principal=principal, product=product,
            movement_type="health_consumption", quantity=payload.inventory_quantity,
            unit_cost=product.average_cost, reason=f"Evento sanitário: {payload.event_type}",
            product_batch=payload.product_batch, reference_type="health_event",
            reference_id=item.id, occurred_at=occurred_at,
        )
        if item.treatment_cost <= 0:
            item.treatment_cost = payload.inventory_quantity * product.average_cost
    if item.treatment_cost > 0:
        db.add(FinancialEntry(
            id=new_id("finance"), tenant_id=principal.company.tenant_id,
            company_id=principal.company.id, farm_id=payload.farm_id,
            animal_id=payload.animal_id, lot_id=payload.lot_id, entry_type="expense",
            category="health", cost_center="Sanidade",
            description=f"Evento sanitário: {payload.event_type}", amount=item.treatment_cost,
            status="paid", competence_date=occurred_at, paid_at=occurred_at,
            reference_type="health_event", reference_id=item.id,
            created_by=principal.user.id,
        ))
    subject = payload.animal_id or payload.lot_id or "manejo sanitário"
    _sync_operational_task(
        db=db, principal=principal, farm_id=payload.farm_id,
        source_type="health_event", source_id=item.id,
        title=f"Retorno sanitário — {payload.event_type}",
        description=f"Retorno programado para {subject}.",
        due_at=payload.next_date, priority="high" if payload.is_quarantine else "medium",
    )
    db.commit()
    db.refresh(item)
    return item


@router.patch("/health/{event_id}", response_model=HealthEventResponse)
def update_health_event(
    event_id: str,
    payload: HealthEventUpdateRequest,
    principal: Principal = Depends(require_permission("health.write")),
    db: Session = Depends(get_db),
) -> HealthEvent:
    item = db.scalar(
        select(HealthEvent).where(
            HealthEvent.id == event_id,
            HealthEvent.company_id == principal.company.id,
        )
    )
    if item is None:
        raise HTTPException(status_code=404, detail="Evento sanitário não encontrado.")
    _farm_allowed(principal, item.farm_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(item, field, value)
    _sync_operational_task(
        db=db, principal=principal, farm_id=item.farm_id,
        source_type="health_event", source_id=item.id,
        title=f"Retorno sanitário — {item.event_type}",
        description=f"Retorno programado para {item.animal_id or item.lot_id or 'manejo sanitário'}.",
        due_at=item.next_date, priority="high" if item.is_quarantine else "medium",
    )
    db.commit(); db.refresh(item)
    return item


@router.delete(
    "/health/{event_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    response_model=None,
)
def delete_health_event(
    event_id: str,
    principal: Principal = Depends(require_permission("health.write")),
    db: Session = Depends(get_db),
) -> Response:
    item = db.scalar(
        select(HealthEvent).where(
            HealthEvent.id == event_id,
            HealthEvent.company_id == principal.company.id,
        )
    )
    if item is None:
        raise HTTPException(status_code=404, detail="Evento sanitário não encontrado.")
    _farm_allowed(principal, item.farm_id)

    original_movement = db.scalar(
        select(InventoryMovement).where(
            InventoryMovement.company_id == principal.company.id,
            InventoryMovement.reference_type == "health_event",
            InventoryMovement.reference_id == item.id,
            InventoryMovement.movement_type == "health_consumption",
        )
    )
    reversal = db.scalar(
        select(InventoryMovement).where(
            InventoryMovement.company_id == principal.company.id,
            InventoryMovement.reference_type == "health_event_reversal",
            InventoryMovement.reference_id == item.id,
        )
    )
    if original_movement is not None and reversal is None:
        product = _inventory_product(db, principal, original_movement.product_id)
        product.quantity += original_movement.quantity
        db.add(
            InventoryMovement(
                id=new_id("stock_move"),
                tenant_id=principal.company.tenant_id,
                company_id=principal.company.id,
                farm_id=product.farm_id,
                product_id=product.id,
                movement_type="return",
                quantity=original_movement.quantity,
                unit_cost=original_movement.unit_cost,
                balance_after=product.quantity,
                reason=f"Estorno do evento sanitário {item.event_type}",
                document_number=f"ESTORNO-{item.id}",
                product_batch=original_movement.product_batch,
                reference_type="health_event_reversal",
                reference_id=item.id,
                occurred_at=datetime.now(timezone.utc),
                created_by=principal.user.id,
            )
        )

    linked_finance = db.scalars(
        select(FinancialEntry).where(
            FinancialEntry.company_id == principal.company.id,
            FinancialEntry.reference_type == "health_event",
            FinancialEntry.reference_id == item.id,
        )
    ).all()
    for entry in linked_finance:
        db.delete(entry)
    _delete_source_tasks(
        db=db, principal=principal, source_type="health_event", source_id=item.id
    )
    db.delete(item)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/health", response_model=list[HealthEventResponse])
def list_health_events(
    farm_id: str,
    animal_id: str | None = None,
    lot_id: str | None = None,
    principal: Principal = Depends(require_permission("health.read")),
    db: Session = Depends(get_db),
) -> list[HealthEvent]:
    _farm_allowed(principal, farm_id)
    query = select(HealthEvent).where(
        HealthEvent.company_id == principal.company.id,
        HealthEvent.farm_id == farm_id,
    )
    if animal_id:
        query = query.where(HealthEvent.animal_id == animal_id)
    if lot_id:
        query = query.where(HealthEvent.lot_id == lot_id)
    return list(db.scalars(query.order_by(HealthEvent.occurred_at.desc())).all())


@router.post("/health/protocols", response_model=HealthProtocolResponse, status_code=201)
def create_health_protocol(payload: HealthProtocolCreateRequest, principal: Principal = Depends(require_permission("health.write")), db: Session = Depends(get_db)) -> HealthProtocol:
    _farm_allowed(principal, payload.farm_id)
    item = HealthProtocol(id=new_id("health_protocol"), tenant_id=principal.company.tenant_id, company_id=principal.company.id, created_by=principal.user.id, **payload.model_dump())
    db.add(item); db.commit(); db.refresh(item); return item


@router.get("/health/protocols", response_model=list[HealthProtocolResponse])
def list_health_protocols(farm_id: str, principal: Principal = Depends(require_permission("health.read")), db: Session = Depends(get_db)) -> list[HealthProtocol]:
    _farm_allowed(principal, farm_id)
    return list(db.scalars(select(HealthProtocol).where(HealthProtocol.company_id == principal.company.id, HealthProtocol.farm_id == farm_id, HealthProtocol.active.is_(True))).all())


@router.post("/health/protocols/{protocol_id}/apply", response_model=list[HealthEventResponse], status_code=201)
def apply_health_protocol(protocol_id: str, payload: HealthProtocolApplyRequest, principal: Principal = Depends(require_permission("health.write")), db: Session = Depends(get_db)) -> list[HealthEvent]:
    protocol = db.scalar(select(HealthProtocol).where(HealthProtocol.id == protocol_id, HealthProtocol.company_id == principal.company.id))
    if protocol is None: raise HTTPException(status_code=404, detail="Protocolo não encontrado.")
    _farm_allowed(principal, protocol.farm_id)
    animal_ids = list(payload.animal_ids)
    if payload.lot_id:
        lot = _lot(db, principal, payload.lot_id)
        animal_ids.extend(db.scalars(select(LivestockAnimal.id).where(LivestockAnimal.lot_id == lot.id, LivestockAnimal.status == "active")).all())
    animal_ids = list(dict.fromkeys(animal_ids))
    if not animal_ids: raise HTTPException(status_code=422, detail="Informe animais ou lote.")
    occurred = payload.occurred_at or datetime.now(timezone.utc)
    result=[]
    for animal_id in animal_ids:
        animal=_animal(db, principal, animal_id)
        if animal.farm_id != protocol.farm_id: continue
        event=HealthEvent(id=new_id("health"), tenant_id=principal.company.tenant_id, company_id=principal.company.id, farm_id=protocol.farm_id, animal_id=animal.id, lot_id=animal.lot_id, event_type=protocol.event_type, product_name=protocol.product_name, dosage=protocol.dosage, route=protocol.route, protocol_name=protocol.name, occurred_at=occurred, next_date=occurred + timedelta(days=protocol.recurrence_days) if protocol.recurrence_days else None, withdrawal_meat_until=occurred + timedelta(days=protocol.withdrawal_meat_days) if protocol.withdrawal_meat_days else None, withdrawal_milk_until=occurred + timedelta(days=protocol.withdrawal_milk_days) if protocol.withdrawal_milk_days else None, responsible=payload.responsible, created_by=principal.user.id)
        db.add(event); result.append(event)
    db.commit()
    for item in result: db.refresh(item)
    return result


@router.post("/inventory/products", response_model=InventoryProductResponse, status_code=201)
def create_product(
    payload: InventoryProductCreateRequest,
    principal: Principal = Depends(require_permission("inventory.write")),
    db: Session = Depends(get_db),
) -> InventoryProduct:
    _farm_allowed(principal, payload.farm_id)
    item = InventoryProduct(
        id=new_id("product"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="SKU duplicado.") from exc
    db.refresh(item)
    return item


@router.get("/inventory/products", response_model=list[InventoryProductResponse])
def list_products(
    farm_id: str,
    principal: Principal = Depends(require_permission("inventory.read")),
    db: Session = Depends(get_db),
) -> list[InventoryProduct]:
    _farm_allowed(principal, farm_id)
    return list(
        db.scalars(
            select(InventoryProduct)
            .where(
                InventoryProduct.company_id == principal.company.id,
                InventoryProduct.farm_id == farm_id,
                InventoryProduct.active.is_(True),
            )
            .order_by(InventoryProduct.name)
        ).all()
    )


@router.post("/inventory/products/{product_id}/movements", response_model=InventoryProductResponse)
def move_inventory(
    product_id: str,
    payload: InventoryMovementRequest,
    principal: Principal = Depends(require_permission("inventory.write")),
    db: Session = Depends(get_db),
) -> InventoryProduct:
    product = db.scalar(
        select(InventoryProduct).where(
            InventoryProduct.id == product_id,
            InventoryProduct.company_id == principal.company.id,
        )
    )
    if product is None:
        raise HTTPException(status_code=404, detail="Produto não encontrado.")
    _farm_allowed(principal, product.farm_id)
    delta = payload.quantity if payload.movement_type in {"entry", "adjustment_in"} else -payload.quantity
    if product.quantity + delta < 0:
        raise HTTPException(status_code=422, detail="Estoque insuficiente.")
    product.quantity += delta
    if payload.unit_cost > 0 and delta > 0:
        product.average_cost = payload.unit_cost
    movement = InventoryMovement(
        id=new_id("stock_move"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=product.farm_id,
        product_id=product.id,
        movement_type=payload.movement_type,
        quantity=payload.quantity,
        unit_cost=payload.unit_cost,
        reference_type=payload.reference_type,
        reference_id=payload.reference_id,
        created_by=principal.user.id,
    )
    db.add(movement)
    db.commit()
    db.refresh(product)
    return product


@router.post("/finance", response_model=FinancialEntryResponse, status_code=201)
def create_financial_entry(
    payload: FinancialEntryCreateRequest,
    principal: Principal = Depends(require_permission("finance.write")),
    db: Session = Depends(get_db),
) -> FinancialEntry:
    _farm_allowed(principal, payload.farm_id)
    item = FinancialEntry(
        id=new_id("finance"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        created_by=principal.user.id,
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.get("/finance", response_model=list[FinancialEntryResponse])
def list_financial_entries(
    farm_id: str,
    principal: Principal = Depends(require_permission("finance.read")),
    db: Session = Depends(get_db),
) -> list[FinancialEntry]:
    _farm_allowed(principal, farm_id)
    return list(
        db.scalars(
            select(FinancialEntry)
            .where(
                FinancialEntry.company_id == principal.company.id,
                FinancialEntry.farm_id == farm_id,
            )
            .order_by(FinancialEntry.created_at.desc())
        ).all()
    )


@router.post("/nutrition", response_model=NutritionEventResponse, status_code=201)
def create_nutrition_event(
    payload: NutritionEventCreateRequest,
    principal: Principal = Depends(require_permission("nutrition.write")),
    db: Session = Depends(get_db),
) -> NutritionEvent:
    _farm_allowed(principal, payload.farm_id)
    lot = _lot(db, principal, payload.lot_id)
    if lot.farm_id != payload.farm_id:
        raise HTTPException(status_code=422, detail="Lote pertence a outra fazenda.")

    item = NutritionEvent(
        id=new_id("nutrition"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=payload.farm_id,
        lot_id=payload.lot_id,
        nutrition_plan_id=None,
        product_id=payload.product_id,
        diet_name=payload.diet_name,
        amount_per_animal=payload.quantity_per_head,
        animal_count=0,
        total_quantity=payload.total_quantity,
        planned_quantity=payload.total_quantity,
        estimated_cost=payload.estimated_cost,
        observed_daily_gain_kg=0,
        feed_conversion=0,
        notes=payload.notes,
        occurred_at=payload.occurred_at or datetime.now(timezone.utc),
        created_by=principal.user.id,
    )
    db.add(item)

    if payload.product_id and payload.total_quantity > 0:
        product = db.get(InventoryProduct, payload.product_id)
        if product is None or product.company_id != principal.company.id:
            raise HTTPException(status_code=404, detail="Produto não encontrado.")
        if product.quantity < payload.total_quantity:
            raise HTTPException(status_code=422, detail="Estoque insuficiente para a dieta.")
        product.quantity -= payload.total_quantity
        db.add(
            InventoryMovement(
                id=new_id("stock_move"),
                tenant_id=principal.company.tenant_id,
                company_id=principal.company.id,
                farm_id=payload.farm_id,
                product_id=product.id,
                movement_type="nutrition_consumption",
                quantity=payload.total_quantity,
                unit_cost=product.average_cost,
                reference_type="nutrition_event",
                reference_id=item.id,
                created_by=principal.user.id,
            )
        )

    if payload.estimated_cost > 0:
        db.add(
            FinancialEntry(
                id=new_id("finance"),
                tenant_id=principal.company.tenant_id,
                company_id=principal.company.id,
                farm_id=payload.farm_id,
                entry_type="expense",
                category="nutrition",
                description=f"Dieta: {payload.diet_name}",
                amount=payload.estimated_cost,
                reference_type="nutrition_event",
                reference_id=item.id,
                created_by=principal.user.id,
            )
        )

    db.commit()
    db.refresh(item)
    return item


@router.get("/nutrition", response_model=list[NutritionEventResponse])
def list_nutrition_events(
    farm_id: str,
    lot_id: str | None = None,
    principal: Principal = Depends(require_permission("nutrition.read")),
    db: Session = Depends(get_db),
) -> list[NutritionEvent]:
    _farm_allowed(principal, farm_id)
    query = select(NutritionEvent).where(
        NutritionEvent.company_id == principal.company.id,
        NutritionEvent.farm_id == farm_id,
    )
    if lot_id:
        query = query.where(NutritionEvent.lot_id == lot_id)
    return list(db.scalars(query.order_by(NutritionEvent.occurred_at.desc())).all())


@router.get("/dashboard")
def livestock_dashboard(
    farm_id: str,
    principal: Principal = Depends(require_permission("herd.read")),
    db: Session = Depends(get_db),
) -> dict:
    _farm_allowed(principal, farm_id)
    company_id = principal.company.id
    return {
        "farm_id": farm_id,
        "animals": db.scalar(select(func.count()).select_from(LivestockAnimal).where(
            LivestockAnimal.company_id == company_id,
            LivestockAnimal.farm_id == farm_id,
        )) or 0,
        "lots": db.scalar(select(func.count()).select_from(HerdLot).where(
            HerdLot.company_id == company_id,
            HerdLot.farm_id == farm_id,
        )) or 0,
        "health_events": db.scalar(select(func.count()).select_from(HealthEvent).where(
            HealthEvent.company_id == company_id,
            HealthEvent.farm_id == farm_id,
        )) or 0,
        "inventory_alerts": db.scalar(select(func.count()).select_from(InventoryProduct).where(
            InventoryProduct.company_id == company_id,
            InventoryProduct.farm_id == farm_id,
            InventoryProduct.quantity <= InventoryProduct.minimum_quantity,
        )) or 0,
    }


@router.get("/health/alerts")
def health_alerts(
    farm_id: str,
    days: int = 30,
    principal: Principal = Depends(require_permission("health.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    _farm_allowed(principal, farm_id)
    now = datetime.now(timezone.utc)
    limit = now + timedelta(days=max(0, days))
    events = list(db.scalars(select(HealthEvent).where(
        HealthEvent.company_id == principal.company.id,
        HealthEvent.farm_id == farm_id,
    )).all())
    alerts: list[dict] = []
    for event in events:
        base = {"event_id": event.id, "animal_id": event.animal_id, "lot_id": event.lot_id, "event_type": event.event_type}
        if event.next_date and event.next_date <= limit and event.status not in {"cancelled", "completed_future"}:
            alerts.append({**base, "alert_type": "scheduled_health_action", "due_at": event.next_date.isoformat(), "severity": "high" if event.next_date < now else "medium", "message": "Ação sanitária programada."})
        for kind, value in (("meat_withdrawal", event.withdrawal_meat_until), ("milk_withdrawal", event.withdrawal_milk_until)):
            if value and value >= now:
                alerts.append({**base, "alert_type": kind, "due_at": value.isoformat(), "severity": "high", "message": "Animal dentro do período de carência."})
        if event.is_quarantine and event.status not in {"released", "completed"}:
            alerts.append({**base, "alert_type": "quarantine", "due_at": None, "severity": "critical", "message": "Animal ou lote em quarentena."})
    return alerts


# ---------------------------------------------------------------------------
# FASES 2 E 3 — APIs integradas de nutrição, estoque e financeiro
# ---------------------------------------------------------------------------

def _inventory_product(
    db: Session,
    principal: Principal,
    product_id: str,
    *,
    for_update: bool = False,
) -> InventoryProduct:
    query = select(InventoryProduct).where(
        InventoryProduct.id == product_id,
        InventoryProduct.company_id == principal.company.id,
        InventoryProduct.active.is_(True),
    )
    if for_update:
        query = query.with_for_update()
    product = db.scalar(query)
    if product is None:
        raise HTTPException(status_code=404, detail="Produto de estoque não encontrado.")
    _farm_allowed(principal, product.farm_id)
    return product


def _apply_stock_movement(*, db: Session, principal: Principal, product: InventoryProduct,
                          movement_type: str, quantity: float, unit_cost: float = 0,
                          reason: str = "", document_number: str = "", product_batch: str = "",
                          reference_type: str = "", reference_id: str = "",
                          occurred_at: datetime | None = None) -> InventoryMovement:
    if reference_type and reference_id:
        lock_key = (
            f"inventory:{principal.company.id}:{product.id}:"
            f"{reference_type}:{reference_id}"
        )
        advisory_transaction_lock(db, lock_key)
        existing = db.scalar(
            select(InventoryMovement).where(
                InventoryMovement.company_id == principal.company.id,
                InventoryMovement.product_id == product.id,
                InventoryMovement.reference_type == reference_type,
                InventoryMovement.reference_id == reference_id,
            )
        )
        if existing is not None:
            return existing

    inbound = movement_type in {"entry", "adjustment_in", "return", "transfer_in"}
    outbound = movement_type in {"exit", "adjustment_out", "loss", "transfer_out", "health_consumption", "nutrition_consumption"}
    if not inbound and not outbound:
        raise HTTPException(status_code=422, detail="Tipo de movimentação de estoque inválido.")
    delta = quantity if inbound else -quantity
    if product.quantity + delta < -0.000001:
        raise HTTPException(status_code=422, detail="Estoque insuficiente.")
    previous_qty = product.quantity
    product.quantity = max(0.0, product.quantity + delta)
    if inbound and unit_cost > 0:
        total_value = previous_qty * product.average_cost + quantity * unit_cost
        product.average_cost = total_value / product.quantity if product.quantity > 0 else unit_cost
        product.last_purchase_cost = unit_cost
    movement = InventoryMovement(
        id=new_id("stock_move"), tenant_id=principal.company.tenant_id,
        company_id=principal.company.id, farm_id=product.farm_id, product_id=product.id,
        movement_type=movement_type, quantity=quantity, unit_cost=unit_cost,
        balance_after=product.quantity, reason=reason, document_number=document_number,
        product_batch=product_batch, reference_type=reference_type, reference_id=reference_id,
        occurred_at=occurred_at or datetime.now(timezone.utc), created_by=principal.user.id,
    )
    db.add(movement)
    return movement


@router.post("/inventory/products/v2", response_model=InventoryProductResponse, status_code=201)
def create_inventory_product_v2(payload: InventoryProductPhase2CreateRequest,
    principal: Principal = Depends(require_permission("inventory.write")), db: Session = Depends(get_db)) -> InventoryProduct:
    _farm_allowed(principal, payload.farm_id)
    item=InventoryProduct(id=new_id("product"), tenant_id=principal.company.tenant_id,
        company_id=principal.company.id, **payload.model_dump())
    db.add(item)
    try: db.commit()
    except IntegrityError as exc:
        db.rollback(); raise HTTPException(status_code=409, detail="SKU duplicado.") from exc
    db.refresh(item); return item


@router.post("/inventory/products/{product_id}/movements/v2", response_model=InventoryMovementPhase2Response, status_code=201)
def create_inventory_movement_v2(product_id: str, payload: InventoryMovementPhase2Request,
    principal: Principal = Depends(require_permission("inventory.write")), db: Session = Depends(get_db)) -> InventoryMovement:
    product=_inventory_product(db, principal, product_id, for_update=True)
    movement=_apply_stock_movement(db=db, principal=principal, product=product, **payload.model_dump())
    db.commit(); db.refresh(movement); return movement


@router.get("/inventory/products/{product_id}/movements", response_model=list[InventoryMovementPhase2Response])
def list_inventory_movements(product_id: str,
    principal: Principal = Depends(require_permission("inventory.read")), db: Session = Depends(get_db)) -> list[InventoryMovement]:
    product=_inventory_product(db, principal, product_id)
    return list(db.scalars(select(InventoryMovement).where(
        InventoryMovement.company_id==principal.company.id,
        InventoryMovement.product_id==product.id).order_by(InventoryMovement.occurred_at.desc())).all())


@router.get("/inventory/alerts", response_model=list[InventoryAlertResponse])
def inventory_alerts(farm_id: str, expiry_days: int = 30,
    principal: Principal = Depends(require_permission("inventory.read")), db: Session = Depends(get_db)) -> list[dict]:
    _farm_allowed(principal, farm_id)
    now=datetime.now(timezone.utc); limit=now+timedelta(days=max(0,expiry_days)); alerts=[]
    products=db.scalars(select(InventoryProduct).where(InventoryProduct.company_id==principal.company.id,
        InventoryProduct.farm_id==farm_id, InventoryProduct.active.is_(True))).all()
    for p in products:
        base=dict(product_id=p.id, product_name=p.name, quantity=p.quantity,
                  minimum_quantity=p.minimum_quantity, expiry_date=p.expiry_date)
        if p.quantity <= 0: alerts.append({**base,"alert_type":"out_of_stock","severity":"critical","message":"Produto sem estoque."})
        elif p.quantity <= p.minimum_quantity: alerts.append({**base,"alert_type":"low_stock","severity":"high","message":"Produto atingiu o estoque mínimo."})
        if p.expiry_date and p.expiry_date < now: alerts.append({**base,"alert_type":"expired","severity":"critical","message":"Produto vencido."})
        elif p.expiry_date and p.expiry_date <= limit: alerts.append({**base,"alert_type":"near_expiry","severity":"medium","message":"Produto próximo do vencimento."})
    return alerts


@router.post("/nutrition/ingredients", response_model=NutritionIngredientResponse, status_code=201)
def create_nutrition_ingredient(payload: NutritionIngredientCreateRequest,
    principal: Principal = Depends(require_permission("nutrition.write")), db: Session = Depends(get_db)) -> NutritionIngredient:
    _farm_allowed(principal,payload.farm_id)
    if payload.inventory_product_id:
        product=_inventory_product(db,principal,payload.inventory_product_id)
        if product.farm_id != payload.farm_id: raise HTTPException(status_code=422,detail="Produto pertence a outra fazenda.")
    item=NutritionIngredient(id=new_id("ingredient"),tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,**payload.model_dump())
    db.add(item)
    try: db.commit()
    except IntegrityError as exc:
        db.rollback(); raise HTTPException(status_code=409,detail="Ingrediente já cadastrado nesta fazenda.") from exc
    db.refresh(item); return item


@router.get("/nutrition/ingredients", response_model=list[NutritionIngredientResponse])
def list_nutrition_ingredients(farm_id: str,
    principal: Principal = Depends(require_permission("nutrition.read")), db: Session = Depends(get_db)) -> list[NutritionIngredient]:
    _farm_allowed(principal,farm_id)
    return list(db.scalars(select(NutritionIngredient).where(NutritionIngredient.company_id==principal.company.id,
        NutritionIngredient.farm_id==farm_id,NutritionIngredient.active.is_(True)).order_by(NutritionIngredient.name)).all())


@router.post("/nutrition/plans", response_model=NutritionPlanResponse, status_code=201)
def create_nutrition_plan(payload: NutritionPlanCreateRequest,
    principal: Principal = Depends(require_permission("nutrition.write")), db: Session = Depends(get_db)) -> NutritionPlan:
    _farm_allowed(principal,payload.farm_id); lot=_lot(db,principal,payload.lot_id)
    if lot.farm_id != payload.farm_id: raise HTTPException(status_code=422,detail="Lote pertence a outra fazenda.")
    count=payload.animal_count or (db.scalar(select(func.count()).select_from(LivestockAnimal).where(
        LivestockAnimal.company_id==principal.company.id,LivestockAnimal.lot_id==lot.id,LivestockAnimal.status=="active")) or 0)
    data=payload.model_dump(exclude={"start_date","animal_count"})
    item=NutritionPlan(id=new_id("diet"),tenant_id=principal.company.tenant_id,company_id=principal.company.id,
        animal_count=count,start_date=payload.start_date or datetime.now(timezone.utc),created_by=principal.user.id,**data)
    db.add(item); db.commit(); db.refresh(item); return item


@router.get("/nutrition/plans", response_model=list[NutritionPlanResponse])
def list_nutrition_plans(farm_id: str, lot_id: str | None=None,
    principal: Principal = Depends(require_permission("nutrition.read")), db: Session = Depends(get_db)) -> list[NutritionPlan]:
    _farm_allowed(principal,farm_id)
    q=select(NutritionPlan).where(NutritionPlan.company_id==principal.company.id,NutritionPlan.farm_id==farm_id,NutritionPlan.active.is_(True))
    if lot_id: q=q.where(NutritionPlan.lot_id==lot_id)
    return list(db.scalars(q.order_by(NutritionPlan.start_date.desc())).all())


@router.post("/nutrition/lots/{lot_id}/consumption", response_model=NutritionEventResponse, status_code=201)
def register_nutrition_consumption(lot_id: str, payload: NutritionConsumptionRequest,
    principal: Principal = Depends(require_permission("nutrition.write")), db: Session = Depends(get_db)) -> NutritionEvent:
    lot=_lot(db,principal,lot_id); occurred=payload.occurred_at or datetime.now(timezone.utc)
    plan=None
    if payload.nutrition_plan_id:
        plan=db.scalar(select(NutritionPlan).where(NutritionPlan.id==payload.nutrition_plan_id,
            NutritionPlan.company_id==principal.company.id,NutritionPlan.lot_id==lot.id))
        if plan is None: raise HTTPException(status_code=404,detail="Plano nutricional não encontrado.")
    count=payload.animal_count or (db.scalar(select(func.count()).select_from(LivestockAnimal).where(
        LivestockAnimal.company_id==principal.company.id,LivestockAnimal.lot_id==lot.id,LivestockAnimal.status=="active")) or 0)
    product=None; cost=0.0
    if payload.product_id:
        product=_inventory_product(db,principal,payload.product_id)
        if product.farm_id != lot.farm_id: raise HTTPException(status_code=422,detail="Produto pertence a outra fazenda.")
        cost=payload.total_quantity*product.average_cost
    elif plan: cost=payload.total_quantity*plan.cost_per_kg
    feed_conversion=(payload.total_quantity/max(count,1))/payload.observed_daily_gain_kg if payload.observed_daily_gain_kg>0 else 0
    event=NutritionEvent(id=new_id("nutrition"),tenant_id=principal.company.tenant_id,company_id=principal.company.id,
        farm_id=lot.farm_id,lot_id=lot.id,nutrition_plan_id=payload.nutrition_plan_id,product_id=payload.product_id,
        diet_name=payload.diet_name,amount_per_animal=payload.amount_per_animal,animal_count=count,
        total_quantity=payload.total_quantity,planned_quantity=payload.planned_quantity,estimated_cost=cost,
        observed_daily_gain_kg=payload.observed_daily_gain_kg,feed_conversion=feed_conversion,
        notes=payload.notes,occurred_at=occurred,created_by=principal.user.id)
    db.add(event)
    if product:
        _apply_stock_movement(db=db,principal=principal,product=product,movement_type="nutrition_consumption",
            quantity=payload.total_quantity,unit_cost=product.average_cost,reason=f"Consumo da dieta {payload.diet_name}",
            reference_type="nutrition_event",reference_id=event.id,occurred_at=occurred)
    if cost>0:
        db.add(FinancialEntry(id=new_id("finance"),tenant_id=principal.company.tenant_id,company_id=principal.company.id,
            farm_id=lot.farm_id,lot_id=lot.id,entry_type="expense",category="nutrition",cost_center="Nutrição",
            description=f"Consumo nutricional: {payload.diet_name}",amount=cost,status="paid",paid_at=occurred,
            competence_date=occurred,reference_type="nutrition_event",reference_id=event.id,created_by=principal.user.id))
    db.commit(); db.refresh(event); return event


@router.get("/nutrition/performance")
def nutrition_performance(farm_id: str, lot_id: str | None=None,
    principal: Principal = Depends(require_permission("nutrition.read")), db: Session = Depends(get_db)) -> dict:
    _farm_allowed(principal,farm_id)
    q=select(NutritionEvent).where(NutritionEvent.company_id==principal.company.id,NutritionEvent.farm_id==farm_id)
    if lot_id: q=q.where(NutritionEvent.lot_id==lot_id)
    rows=list(db.scalars(q).all()); total_qty=sum(x.total_quantity for x in rows); total_cost=sum(x.estimated_cost for x in rows)
    avg_gain=sum(x.observed_daily_gain_kg for x in rows if x.observed_daily_gain_kg>0)/max(1,len([x for x in rows if x.observed_daily_gain_kg>0]))
    planned=sum(x.planned_quantity for x in rows); variance=total_qty-planned
    return {"farm_id":farm_id,"lot_id":lot_id,"events":len(rows),"total_quantity":total_qty,
        "planned_quantity":planned,"consumption_variance":variance,"total_cost":total_cost,
        "average_daily_gain_kg":avg_gain,"cost_per_kg_gain": total_cost/(avg_gain*max(1,len(rows))) if avg_gain>0 else 0}


@router.post("/finance/v2", response_model=FinancialEntryPhase3Response, status_code=201)
def create_financial_entry_v2(payload: FinancialEntryPhase3CreateRequest,
    principal: Principal = Depends(require_permission("finance.write")), db: Session = Depends(get_db)) -> FinancialEntry:
    _farm_allowed(principal,payload.farm_id)
    if payload.animal_id:
        animal=_animal(db,principal,payload.animal_id)
        if animal.farm_id!=payload.farm_id: raise HTTPException(status_code=422,detail="Animal pertence a outra fazenda.")
    if payload.lot_id:
        lot=_lot(db,principal,payload.lot_id)
        if lot.farm_id!=payload.farm_id: raise HTTPException(status_code=422,detail="Lote pertence a outra fazenda.")
    data=payload.model_dump()
    if data["paid_at"] and data["status"]=="pending":
        data["status"]="paid"

    if payload.reference_type and payload.reference_id:
        advisory_transaction_lock(
            db,
            (
                f"finance:{principal.company.id}:{payload.farm_id}:"
                f"{payload.reference_type}:{payload.reference_id}"
            ),
        )
        existing = db.scalar(
            select(FinancialEntry).where(
                FinancialEntry.company_id == principal.company.id,
                FinancialEntry.farm_id == payload.farm_id,
                FinancialEntry.reference_type == payload.reference_type,
                FinancialEntry.reference_id == payload.reference_id,
            )
        )
        if existing is not None:
            return existing

    item=FinancialEntry(id=new_id("finance"),tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,created_by=principal.user.id,**data)
    db.add(item); db.commit(); db.refresh(item); return item


@router.patch("/finance/{entry_id}/settle", response_model=FinancialEntryPhase3Response)
def settle_financial_entry(entry_id: str,payload: FinancialSettlementRequest,
    principal: Principal = Depends(require_permission("finance.write")),db: Session=Depends(get_db)) -> FinancialEntry:
    item=db.scalar(select(FinancialEntry).where(FinancialEntry.id==entry_id,FinancialEntry.company_id==principal.company.id))
    if item is None: raise HTTPException(status_code=404,detail="Lançamento não encontrado.")
    _farm_allowed(principal,item.farm_id); item.paid_at=payload.paid_at or datetime.now(timezone.utc); item.status="paid"
    if payload.payment_method: item.payment_method=payload.payment_method
    db.commit(); db.refresh(item); return item


@router.get("/finance/v2", response_model=list[FinancialEntryPhase3Response])
def list_financial_entries_v2(farm_id: str,status: str|None=None,cost_center: str|None=None,lot_id: str|None=None,animal_id: str|None=None,
    principal: Principal=Depends(require_permission("finance.read")),db: Session=Depends(get_db)) -> list[FinancialEntry]:
    _farm_allowed(principal,farm_id); q=select(FinancialEntry).where(FinancialEntry.company_id==principal.company.id,FinancialEntry.farm_id==farm_id)
    if status: q=q.where(FinancialEntry.status==status)
    if cost_center: q=q.where(FinancialEntry.cost_center==cost_center)
    if lot_id: q=q.where(FinancialEntry.lot_id==lot_id)
    if animal_id: q=q.where(FinancialEntry.animal_id==animal_id)
    return list(db.scalars(q.order_by(FinancialEntry.created_at.desc())).all())


@router.get("/finance/summary", response_model=FinancialSummaryResponse)
def financial_summary(farm_id: str,
    principal: Principal=Depends(require_permission("finance.read")),db: Session=Depends(get_db)) -> dict:
    _farm_allowed(principal,farm_id); now=datetime.now(timezone.utc)
    rows=list(db.scalars(select(FinancialEntry).where(FinancialEntry.company_id==principal.company.id,FinancialEntry.farm_id==farm_id)).all())
    income=sum(x.amount for x in rows if x.entry_type=="income"); expense=sum(x.amount for x in rows if x.entry_type=="expense")
    paid_income=sum(x.amount for x in rows if x.entry_type=="income" and x.status=="paid")
    paid_expense=sum(x.amount for x in rows if x.entry_type=="expense" and x.status=="paid")
    receivable=sum(x.amount for x in rows if x.entry_type=="income" and x.status!="paid")
    payable=sum(x.amount for x in rows if x.entry_type=="expense" and x.status!="paid")
    overdue_receivable=sum(x.amount for x in rows if x.entry_type=="income" and x.status!="paid" and x.due_date and x.due_date<now)
    overdue_payable=sum(x.amount for x in rows if x.entry_type=="expense" and x.status!="paid" and x.due_date and x.due_date<now)
    by_center=defaultdict(float); by_lot=defaultdict(float); by_animal=defaultdict(float)
    for x in rows:
        if x.entry_type!="expense": continue
        by_center[x.cost_center or "Geral"]+=x.amount
        if x.lot_id: by_lot[x.lot_id]+=x.amount
        if x.animal_id: by_animal[x.animal_id]+=x.amount
    animals=db.scalar(select(func.count()).select_from(LivestockAnimal).where(LivestockAnimal.company_id==principal.company.id,
        LivestockAnimal.farm_id==farm_id,LivestockAnimal.status=="active")) or 0
    margin=income-expense
    indicators={"gross_margin":margin,"net_margin":margin,"operating_cost":expense,
        "break_even_revenue":expense,"roi_percent":(margin/expense*100) if expense>0 else 0,
        "cost_per_animal":expense/animals if animals else 0}
    return {"farm_id":farm_id,"income":income,"expense":expense,"paid_income":paid_income,"paid_expense":paid_expense,
        "receivable":receivable,"payable":payable,"overdue_receivable":overdue_receivable,"overdue_payable":overdue_payable,
        "balance":paid_income-paid_expense,"projected_balance":income-expense,"cost_by_center":dict(by_center),
        "cost_by_lot":dict(by_lot),"cost_by_animal":dict(by_animal),"indicators":indicators}


@router.get("/finance/cash-flow")
def financial_cash_flow(farm_id: str,days: int=90,
    principal: Principal=Depends(require_permission("finance.read")),db: Session=Depends(get_db)) -> dict:
    _farm_allowed(principal,farm_id); start=datetime.now(timezone.utc); end=start+timedelta(days=max(1,days))
    rows=list(db.scalars(select(FinancialEntry).where(FinancialEntry.company_id==principal.company.id,
        FinancialEntry.farm_id==farm_id,FinancialEntry.due_date>=start,FinancialEntry.due_date<=end).order_by(FinancialEntry.due_date)).all())
    buckets=defaultdict(lambda:{"income":0.0,"expense":0.0})
    for x in rows: buckets[x.due_date.date().isoformat()][x.entry_type]+=x.amount
    balance=0.0; points=[]
    for day in sorted(buckets):
        balance+=buckets[day]["income"]-buckets[day]["expense"]
        points.append({"date":day,**buckets[day],"projected_balance":balance})
    return {"farm_id":farm_id,"days":days,"points":points}


# V1 FINAL — CRUD remoto oficial de piquetes.
@router.get("/paddocks", response_model=list[PaddockResponse])
def list_paddocks(
    farm_id: str,
    principal: Principal = Depends(require_permission("herd.read")),
    db: Session = Depends(get_db),
) -> list[Paddock]:
    _farm_allowed(principal, farm_id)
    return list(db.scalars(
        select(Paddock).where(
            Paddock.company_id == principal.company.id,
            Paddock.farm_id == farm_id,
            Paddock.active.is_(True),
        ).order_by(Paddock.name)
    ).all())


@router.post("/paddocks", response_model=PaddockResponse, status_code=201)
def create_paddock(
    payload: PaddockCreateRequest,
    principal: Principal = Depends(require_permission("herd.write")),
    db: Session = Depends(get_db),
) -> Paddock:
    _farm_allowed(principal, payload.farm_id)
    item = Paddock(
        id=new_id("paddock"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Já existe um piquete com esse nome nesta fazenda.")
    db.refresh(item)
    return item


@router.patch("/paddocks/{paddock_id}", response_model=PaddockResponse)
def update_paddock(
    paddock_id: str,
    payload: PaddockUpdateRequest,
    principal: Principal = Depends(require_permission("herd.write")),
    db: Session = Depends(get_db),
) -> Paddock:
    item = db.scalar(select(Paddock).where(
        Paddock.id == paddock_id,
        Paddock.company_id == principal.company.id,
    ))
    if item is None:
        raise HTTPException(status_code=404, detail="Piquete não encontrado.")
    _farm_allowed(principal, item.farm_id)
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(item, key, value)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Já existe um piquete com esse nome nesta fazenda.")
    db.refresh(item)
    return item


@router.delete("/paddocks/{paddock_id}", status_code=204)
def delete_paddock(
    paddock_id: str,
    principal: Principal = Depends(require_permission("herd.write")),
    db: Session = Depends(get_db),
) -> Response:
    item = db.scalar(select(Paddock).where(
        Paddock.id == paddock_id,
        Paddock.company_id == principal.company.id,
    ))
    if item is None:
        raise HTTPException(status_code=404, detail="Piquete não encontrado.")
    _farm_allowed(principal, item.farm_id)
    item.active = False
    db.commit()
    return Response(status_code=204)


# V1 FINAL — mutações que faltavam para CRUD completo dos módulos centrais.
@router.patch("/inventory/products/{product_id}/v2", response_model=InventoryProductResponse)
def update_inventory_product_v2(
    product_id: str, payload: InventoryProductPhase2CreateRequest,
    principal: Principal = Depends(require_permission("inventory.write")),
    db: Session = Depends(get_db),
) -> InventoryProduct:
    item=_inventory_product(db,principal,product_id)
    _farm_allowed(principal,payload.farm_id)
    for key,value in payload.model_dump().items():
        setattr(item,key,value)
    db.commit(); db.refresh(item); return item

@router.delete("/inventory/products/{product_id}/v2", status_code=204)
def delete_inventory_product_v2(
    product_id: str,
    principal: Principal = Depends(require_permission("inventory.write")),
    db: Session = Depends(get_db),
) -> Response:
    item=_inventory_product(db,principal,product_id)
    item.active=False; db.commit(); return Response(status_code=204)

@router.patch("/nutrition/plans/{plan_id}", response_model=NutritionPlanResponse)
def update_nutrition_plan(
    plan_id: str, payload: NutritionPlanCreateRequest,
    principal: Principal = Depends(require_permission("nutrition.write")),
    db: Session = Depends(get_db),
) -> NutritionPlan:
    item=db.scalar(select(NutritionPlan).where(NutritionPlan.id==plan_id,NutritionPlan.company_id==principal.company.id))
    if item is None: raise HTTPException(status_code=404,detail="Plano nutricional não encontrado.")
    _farm_allowed(principal,item.farm_id)
    for key,value in payload.model_dump().items():
        if value is not None: setattr(item,key,value)
    db.commit(); db.refresh(item); return item

@router.delete("/nutrition/plans/{plan_id}", status_code=204)
def delete_nutrition_plan(
    plan_id: str,
    principal: Principal = Depends(require_permission("nutrition.write")),
    db: Session = Depends(get_db),
) -> Response:
    item=db.scalar(select(NutritionPlan).where(NutritionPlan.id==plan_id,NutritionPlan.company_id==principal.company.id))
    if item is None: raise HTTPException(status_code=404,detail="Plano nutricional não encontrado.")
    _farm_allowed(principal,item.farm_id); item.active=False; db.commit(); return Response(status_code=204)

@router.patch("/finance/v2/{entry_id}", response_model=FinancialEntryPhase3Response)
def update_financial_entry_v2(
    entry_id: str, payload: FinancialEntryPhase3CreateRequest,
    principal: Principal=Depends(require_permission("finance.write")),
    db: Session=Depends(get_db),
) -> FinancialEntry:
    item=db.scalar(select(FinancialEntry).where(FinancialEntry.id==entry_id,FinancialEntry.company_id==principal.company.id))
    if item is None: raise HTTPException(status_code=404,detail="Lançamento não encontrado.")
    _farm_allowed(principal,item.farm_id)
    for key,value in payload.model_dump().items():
        setattr(item,key,value)
    db.commit(); db.refresh(item); return item

@router.delete("/finance/v2/{entry_id}", status_code=204)
def delete_financial_entry_v2(
    entry_id: str,
    principal: Principal=Depends(require_permission("finance.write")),
    db: Session=Depends(get_db),
) -> Response:
    item=db.scalar(select(FinancialEntry).where(FinancialEntry.id==entry_id,FinancialEntry.company_id==principal.company.id))
    if item is None: raise HTTPException(status_code=404,detail="Lançamento não encontrado.")
    _farm_allowed(principal,item.farm_id); db.delete(item); db.commit(); return Response(status_code=204)
