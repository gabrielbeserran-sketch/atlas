
from __future__ import annotations

from collections import defaultdict

from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import func, or_, select, text
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.orm import Session

from app.services.concurrency import advisory_transaction_lock

from ..authz import Principal, get_principal, require_permission
from ..database import get_db
from ..models import (
    AnimalMovement,
    FinancialEntry,
    Farm,
    FarmHandlingOperation,
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
    FarmHandlingBatchRequest,
    FarmHandlingBatchResponse,
    FarmHandlingOperationHistoryResponse,
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
    WeightUpdateRequest,
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
    AnimalGenealogyNodeResponse,
    AnimalGenealogyResponse,
)

router = APIRouter(prefix="/livestock", tags=["livestock"])


def _farm_allowed(
    db: Session,
    principal: Principal,
    farm_id: str,
) -> None:
    farm = db.scalar(
        select(Farm).where(
            Farm.id == farm_id,
            Farm.company_id == principal.company.id,
            Farm.tenant_id == principal.company.tenant_id,
        )
    )
    if farm is None:
        raise HTTPException(status_code=404, detail="Fazenda não encontrada.")

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
    _farm_allowed(db, principal, item.farm_id)
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



def _sync_weight_schedule_task(
    *,
    db: Session,
    principal: Principal,
    animal: LivestockAnimal,
    interval_days: int = 30,
) -> OperationalTask | None:
    latest = db.scalar(
        select(WeightRecord)
        .where(
            WeightRecord.company_id == principal.company.id,
            WeightRecord.animal_id == animal.id,
        )
        .order_by(WeightRecord.measured_at.desc(), WeightRecord.id.desc())
        .limit(1)
    )
    due_at = (
        latest.measured_at + timedelta(days=max(1, interval_days))
        if latest is not None
        else datetime.now(timezone.utc)
    )
    return _sync_operational_task(
        db=db,
        principal=principal,
        farm_id=animal.farm_id,
        source_type="weight_schedule",
        source_id=animal.id,
        title=f"Nova pesagem — {animal.name or animal.tag or animal.id}",
        description=(
            "Atualizar peso, escore corporal e indicadores de desempenho "
            "do animal."
        ),
        due_at=due_at,
        priority="medium",
    )


def _sync_nutrition_plan_task(
    *,
    db: Session,
    principal: Principal,
    plan: NutritionPlan,
) -> OperationalTask | None:
    due_at = plan.end_date if plan.active else None
    return _sync_operational_task(
        db=db,
        principal=principal,
        farm_id=plan.farm_id,
        source_type="nutrition_plan",
        source_id=plan.id,
        title=f"Revisar dieta — {plan.name}",
        description=(
            "Reavaliar consumo, GMD, custo da dieta e necessidade de "
            "renovação do plano nutricional."
        ),
        due_at=due_at,
        priority="medium",
    )


def _sync_existing_smart_agenda(
    *,
    db: Session,
    principal: Principal,
    farm_id: str,
) -> dict[str, int]:
    """Reconcilia Agenda Inteligente a partir dos dados oficiais.

    É idempotente: cada fonte possui source_type/source_id estáveis e
    _sync_operational_task cancela duplicidades históricas.
    """
    _farm_allowed(db, principal, farm_id)
    counters = defaultdict(int)

    animals = list(
        db.scalars(
            select(LivestockAnimal).where(
                LivestockAnimal.company_id == principal.company.id,
                LivestockAnimal.farm_id == farm_id,
                LivestockAnimal.status.in_(["active", "Ativo"]),
            )
        ).all()
    )
    for animal in animals:
        _sync_weight_schedule_task(db=db, principal=principal, animal=animal)
        counters["weight_schedule"] += 1

    plans = list(
        db.scalars(
            select(NutritionPlan).where(
                NutritionPlan.company_id == principal.company.id,
                NutritionPlan.farm_id == farm_id,
                NutritionPlan.active.is_(True),
            )
        ).all()
    )
    for plan in plans:
        _sync_nutrition_plan_task(db=db, principal=principal, plan=plan)
        counters["nutrition_plan"] += 1

    health_events = list(
        db.scalars(
            select(HealthEvent).where(
                HealthEvent.company_id == principal.company.id,
                HealthEvent.farm_id == farm_id,
            )
        ).all()
    )
    for event in health_events:
        _sync_operational_task(
            db=db,
            principal=principal,
            farm_id=event.farm_id,
            source_type="health_event",
            source_id=event.id,
            title=f"Retorno sanitário — {event.event_type}",
            description=(
                "Retorno programado para "
                f"{event.animal_id or event.lot_id or 'manejo sanitário'}."
            ),
            due_at=event.next_date,
            priority="high" if event.is_quarantine else "medium",
        )
        if event.next_date is not None:
            counters["health_event"] += 1

    reproduction_events = list(
        db.scalars(
            select(ReproductionEvent).where(
                ReproductionEvent.company_id == principal.company.id,
                ReproductionEvent.farm_id == farm_id,
            )
        ).all()
    )
    for event in reproduction_events:
        animal = db.scalar(
            select(LivestockAnimal).where(
                LivestockAnimal.id == event.animal_id,
                LivestockAnimal.company_id == principal.company.id,
            )
        )
        if animal is None:
            continue
        _sync_operational_task(
            db=db,
            principal=principal,
            farm_id=farm_id,
            source_type="reproduction_event",
            source_id=event.id,
            title=f"{event.event_type} — {animal.name or animal.tag or animal.id}",
            description=(
                f"Retorno reprodutivo de "
                f"{animal.name or animal.tag or animal.id}."
            ),
            due_at=event.expected_date,
            priority=(
                "high"
                if event.event_code == "pregnancy_diagnosis"
                else "medium"
            ),
        )
        if event.expected_date is not None:
            counters["reproduction_event"] += 1

    return dict(counters)


def _refresh_animal_weight_state(
    *,
    db: Session,
    animal: LivestockAnimal,
) -> None:
    latest = db.scalar(
        select(WeightRecord)
        .where(
            WeightRecord.company_id == animal.company_id,
            WeightRecord.animal_id == animal.id,
        )
        .order_by(WeightRecord.measured_at.desc(), WeightRecord.id.desc())
        .limit(1)
    )
    if latest is None:
        animal.current_weight = 0
        animal.body_condition_score = 0
        return
    animal.current_weight = latest.weight
    animal.body_condition_score = latest.body_condition_score


def _refresh_animal_reproduction_state(
    *,
    db: Session,
    animal: LivestockAnimal,
) -> None:
    latest = db.scalar(
        select(ReproductionEvent)
        .where(
            ReproductionEvent.company_id == animal.company_id,
            ReproductionEvent.animal_id == animal.id,
        )
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
    _farm_allowed(db, principal, item.farm_id)
    return item


@router.post("/lots", response_model=HerdLotResponse, status_code=201)
def create_lot(
    payload: HerdLotCreateRequest,
    principal: Principal = Depends(require_permission("herd.write")),
    db: Session = Depends(get_db),
) -> HerdLot:
    _farm_allowed(db, principal, payload.farm_id)
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
    _farm_allowed(db, principal, farm_id)
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
    _farm_allowed(db, principal, payload.farm_id)
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
    _farm_allowed(db, principal, farm_id)
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



def _livestock_genealogy_node(
    animal: LivestockAnimal | None,
    *,
    relation: str,
    fallback_tag: str = "",
) -> AnimalGenealogyNodeResponse | None:
    if animal is None:
        tag = fallback_tag.strip()
        if not tag:
            return None
        return AnimalGenealogyNodeResponse(
            id="",
            farm_id="",
            group_name="",
            tag=tag,
            name="",
            sex="",
            breed="",
            category="",
            birth_date="",
            status="Não localizado",
            relation=relation,
            registered=False,
        )

    return AnimalGenealogyNodeResponse(
        id=animal.id,
        farm_id=animal.farm_id,
        group_name="",
        tag=animal.tag,
        name=animal.name,
        sex=animal.sex,
        breed=animal.breed,
        category=animal.category,
        birth_date=animal.birth_date,
        status=animal.status,
        relation=relation,
        registered=True,
    )


def _livestock_parent_reference(
    animal: LivestockAnimal,
    *,
    id_field: str,
    metadata_field: str,
) -> tuple[str, str]:
    parent_id = str(getattr(animal, id_field) or "").strip()
    metadata = dict(animal.metadata_json or {})
    parent_tag = str(metadata.get(metadata_field, "")).strip()
    return parent_id, parent_tag


@router.get(
    "/animals/{animal_id}/genealogy",
    response_model=AnimalGenealogyResponse,
)
def livestock_animal_genealogy(
    animal_id: str,
    principal: Principal = Depends(require_permission("animals.read")),
    db: Session = Depends(get_db),
) -> AnimalGenealogyResponse:
    """Genealogia do animal canônico do Rebanho.

    A Central do Animal trabalha com ``livestock_animals``. A rota histórica
    ``/animals/{id}/genealogy`` consulta ``EntityState`` e por isso devolvia
    404 para animais válidos criados pelo módulo Rebanho. Esta rota usa a
    mesma autoridade do restante da Central do Animal e aceita tanto os
    vínculos ``mother_id``/``father_id`` quanto os tags legados guardados em
    ``metadata_json``.
    """
    animal = _animal(db, principal, animal_id)

    query = select(LivestockAnimal).where(
        LivestockAnimal.company_id == principal.company.id,
        LivestockAnimal.tenant_id == principal.company.tenant_id,
        LivestockAnimal.status != "Excluído",
    )
    entities = list(db.scalars(query).all())

    allowed_farms = set(principal.membership.farm_ids or [])
    if allowed_farms and principal.membership.role not in {"owner", "admin"}:
        entities = [item for item in entities if item.farm_id in allowed_farms]

    by_id = {item.id: item for item in entities}
    by_tag = {
        item.tag.strip().casefold(): item
        for item in entities
        if item.tag.strip()
    }

    father_id, father_tag = _livestock_parent_reference(
        animal,
        id_field="father_id",
        metadata_field="father_tag",
    )
    mother_id, mother_tag = _livestock_parent_reference(
        animal,
        id_field="mother_id",
        metadata_field="mother_tag",
    )

    def resolve(parent_id: str, parent_tag: str) -> LivestockAnimal | None:
        if parent_id and parent_id in by_id:
            return by_id[parent_id]
        if parent_tag:
            return by_tag.get(parent_tag.casefold())
        return None

    father = resolve(father_id, father_tag)
    mother = resolve(mother_id, mother_tag)

    def parent_of(
        parent: LivestockAnimal | None,
        *,
        id_field: str,
        metadata_field: str,
    ) -> tuple[LivestockAnimal | None, str]:
        if parent is None:
            return None, ""
        parent_id, parent_tag = _livestock_parent_reference(
            parent,
            id_field=id_field,
            metadata_field=metadata_field,
        )
        return resolve(parent_id, parent_tag), parent_tag

    paternal_grandfather, paternal_grandfather_tag = parent_of(
        father,
        id_field="father_id",
        metadata_field="father_tag",
    )
    paternal_grandmother, paternal_grandmother_tag = parent_of(
        father,
        id_field="mother_id",
        metadata_field="mother_tag",
    )
    maternal_grandfather, maternal_grandfather_tag = parent_of(
        mother,
        id_field="father_id",
        metadata_field="father_tag",
    )
    maternal_grandmother, maternal_grandmother_tag = parent_of(
        mother,
        id_field="mother_id",
        metadata_field="mother_tag",
    )

    def parent_matches(
        candidate: LivestockAnimal,
        *,
        parent: LivestockAnimal,
    ) -> bool:
        if candidate.father_id == parent.id or candidate.mother_id == parent.id:
            return True
        metadata = dict(candidate.metadata_json or {})
        father_candidate = str(metadata.get("father_tag", "")).strip().casefold()
        mother_candidate = str(metadata.get("mother_tag", "")).strip().casefold()
        parent_tag_key = parent.tag.strip().casefold()
        return bool(
            parent_tag_key
            and (father_candidate == parent_tag_key or mother_candidate == parent_tag_key)
        )

    children = [
        candidate
        for candidate in entities
        if candidate.id != animal.id and parent_matches(candidate, parent=animal)
    ]

    def parent_key(parent_id: str, parent_tag: str) -> str:
        resolved = resolve(parent_id, parent_tag)
        if resolved is not None:
            return f"id:{resolved.id}"
        if parent_id:
            return f"id:{parent_id}"
        if parent_tag:
            return f"tag:{parent_tag.casefold()}"
        return ""

    def candidate_parent_keys(candidate: LivestockAnimal) -> tuple[str, str]:
        metadata = dict(candidate.metadata_json or {})
        candidate_father_id = str(candidate.father_id or "").strip()
        candidate_mother_id = str(candidate.mother_id or "").strip()
        candidate_father_tag = str(metadata.get("father_tag", "")).strip()
        candidate_mother_tag = str(metadata.get("mother_tag", "")).strip()
        return (
            parent_key(candidate_father_id, candidate_father_tag),
            parent_key(candidate_mother_id, candidate_mother_tag),
        )

    focal_father_key = parent_key(father_id, father_tag)
    focal_mother_key = parent_key(mother_id, mother_tag)
    siblings: list[LivestockAnimal] = []
    half_siblings: list[LivestockAnimal] = []
    for candidate in entities:
        if candidate.id == animal.id:
            continue
        candidate_father, candidate_mother = candidate_parent_keys(candidate)
        same_father = bool(focal_father_key and candidate_father == focal_father_key)
        same_mother = bool(focal_mother_key and candidate_mother == focal_mother_key)
        if same_father and same_mother:
            siblings.append(candidate)
        elif same_father or same_mother:
            half_siblings.append(candidate)

    descendants: list[tuple[LivestockAnimal, int]] = []
    visited = {animal.id}
    queue: list[tuple[LivestockAnimal, int]] = [(item, 1) for item in children]
    while queue:
        descendant, generation = queue.pop(0)
        if descendant.id in visited:
            continue
        visited.add(descendant.id)
        descendants.append((descendant, generation))
        if generation >= 5:
            continue
        for candidate in entities:
            if candidate.id in visited:
                continue
            if parent_matches(candidate, parent=descendant):
                queue.append((candidate, generation + 1))

    unresolved_tags = sorted(
        {
            tag
            for tag in [
                father_tag,
                mother_tag,
                paternal_grandfather_tag,
                paternal_grandmother_tag,
                maternal_grandfather_tag,
                maternal_grandmother_tag,
            ]
            if tag and tag.casefold() not in by_tag
        },
        key=str.casefold,
    )

    def descendant_relation(generation: int) -> str:
        return {
            1: "Filho(a)",
            2: "Neto(a)",
            3: "Bisneto(a)",
        }.get(generation, f"Descendente — geração {generation}")

    return AnimalGenealogyResponse(
        animal=_livestock_genealogy_node(animal, relation="Animal selecionado"),
        father=_livestock_genealogy_node(father, relation="Pai", fallback_tag=father_tag),
        mother=_livestock_genealogy_node(mother, relation="Mãe", fallback_tag=mother_tag),
        paternal_grandfather=_livestock_genealogy_node(
            paternal_grandfather,
            relation="Avô paterno",
            fallback_tag=paternal_grandfather_tag,
        ),
        paternal_grandmother=_livestock_genealogy_node(
            paternal_grandmother,
            relation="Avó paterna",
            fallback_tag=paternal_grandmother_tag,
        ),
        maternal_grandfather=_livestock_genealogy_node(
            maternal_grandfather,
            relation="Avô materno",
            fallback_tag=maternal_grandfather_tag,
        ),
        maternal_grandmother=_livestock_genealogy_node(
            maternal_grandmother,
            relation="Avó materna",
            fallback_tag=maternal_grandmother_tag,
        ),
        siblings=[
            _livestock_genealogy_node(item, relation="Irmão(ã)")
            for item in sorted(siblings, key=lambda value: value.tag.casefold())
        ],
        half_siblings=[
            _livestock_genealogy_node(item, relation="Meio-irmão(ã)")
            for item in sorted(half_siblings, key=lambda value: value.tag.casefold())
        ],
        children=[
            _livestock_genealogy_node(item, relation="Filho(a)")
            for item in sorted(children, key=lambda value: value.tag.casefold())
        ],
        descendants=[
            _livestock_genealogy_node(
                item,
                relation=descendant_relation(generation),
            )
            for item, generation in descendants
        ],
        unresolved_tags=unresolved_tags,
    )



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


@router.get("/data-quality/deployment-readiness")
def livestock_data_quality_deployment_readiness(
    db: Session = Depends(get_db),
) -> dict[str, object]:
    """Contrato público, sem dados de negócio, para provar o Macro 10C."""
    state = db.execute(
        text(
            "SELECT version, sanitized_at FROM atlas_data_quality_state "
            "WHERE id = 'global' LIMIT 1"
        )
    ).mappings().first()

    if state is None:
        return {
            "contract_version": "10C",
            "schema_ready": False,
            "utf8_sanitized": False,
            "runtime_normalization": True,
            "animal_traceability": True,
            "farm_scope_guard": True,
        }

    return {
        "contract_version": "10C",
        "schema_ready": state.get("version") == "10C",
        "utf8_sanitized": state.get("version") == "10C",
        "runtime_normalization": True,
        "animal_traceability": True,
        "farm_scope_guard": True,
        "sanitized_at": state.get("sanitized_at"),
    }


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
    previous_lot_id = item.lot_id
    requested_lot_id = changes.get("lot_id", previous_lot_id)
    if requested_lot_id:
        lot = _lot(db, principal, requested_lot_id)
        if lot.farm_id != item.farm_id:
            raise HTTPException(status_code=422, detail="Lote pertence a outra fazenda.")
        if lot.status != "active":
            raise HTTPException(status_code=422, detail="Lote de destino está inativo.")
    for field, value in changes.items():
        setattr(item, field, value.strip() if isinstance(value, str) else value)
    if "lot_id" in changes and requested_lot_id != previous_lot_id:
        db.add(
            AnimalMovement(
                id=new_id("movement"),
                tenant_id=principal.company.tenant_id,
                company_id=principal.company.id,
                farm_id=item.farm_id,
                animal_id=item.id,
                movement_type="lot_change",
                from_lot_id=previous_lot_id,
                to_lot_id=requested_lot_id,
                occurred_at=datetime.now(timezone.utc),
                reason="Alteração cadastral de lote",
                document_reference=f"AUTO-PATCH-{item.id}",
                created_by=principal.user.id,
            )
        )
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



def _require_handling_permission(principal: Principal, permission: str) -> None:
    if permission not in principal.permissions:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Permissão necessária: {permission}.",
        )


def _handling_animals(
    db: Session,
    principal: Principal,
    *,
    farm_id: str,
    animal_ids: list[str],
) -> list[LivestockAnimal]:
    _farm_allowed(db, principal, farm_id)
    unique_ids = list(
        dict.fromkeys(value.strip() for value in animal_ids if value.strip())
    )
    if not unique_ids:
        raise HTTPException(status_code=422, detail="Selecione ao menos um animal.")
    animals = list(
        db.scalars(
            select(LivestockAnimal).where(
                LivestockAnimal.company_id == principal.company.id,
                LivestockAnimal.farm_id == farm_id,
                LivestockAnimal.id.in_(unique_ids),
            )
        ).all()
    )
    found = {item.id for item in animals}
    missing = [animal_id for animal_id in unique_ids if animal_id not in found]
    if missing:
        raise HTTPException(
            status_code=422,
            detail=f"{len(missing)} animal(is) não pertencem à fazenda ativa.",
        )

    inactive = [
        item
        for item in animals
        if item.status.strip().lower() not in {"active", "ativo"}
    ]
    if inactive:
        raise HTTPException(
            status_code=409,
            detail=(
                f"{len(inactive)} animal(is) já estão inativos/baixados. "
                "Atualize a seleção antes de confirmar o manejo."
            ),
        )
    return animals


def _handling_response_from_operation(
    operation: FarmHandlingOperation,
    *,
    repeated: bool,
) -> FarmHandlingBatchResponse:
    return FarmHandlingBatchResponse(
        handling_id=operation.id,
        repeated=repeated,
        farm_id=operation.farm_id,
        action=operation.action,
        affected_count=operation.affected_count,
        animal_ids=list(operation.animal_ids_json or []),
        created_ids=list(operation.created_ids_json or []),
        finance_entry_id=operation.finance_entry_id or None,
        summary=operation.summary,
    )


@router.get("/handling/deployment-readiness")
def farm_handling_deployment_readiness(
    db: Session = Depends(get_db),
) -> dict:
    try:
        db.scalar(select(func.count(FarmHandlingOperation.id)))
    except SQLAlchemyError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Schema do manejo coletivo ainda não está disponível.",
        ) from exc

    return {
        "status": "ready",
        "schema_ready": True,
        "idempotency": True,
        "history": True,
        "active_animal_guard": True,
    }


@router.get(
    "/handling/history",
    response_model=list[FarmHandlingOperationHistoryResponse],
)
def farm_handling_history(
    farm_id: str,
    limit: int = Query(default=30, ge=1, le=100),
    principal: Principal = Depends(get_principal),
    db: Session = Depends(get_db),
) -> list[FarmHandlingOperationHistoryResponse]:
    _require_handling_permission(principal, "herd.read")
    _farm_allowed(db, principal, farm_id)

    items = list(
        db.scalars(
            select(FarmHandlingOperation)
            .where(
                FarmHandlingOperation.company_id == principal.company.id,
                FarmHandlingOperation.farm_id == farm_id,
            )
            .order_by(
                FarmHandlingOperation.occurred_at.desc(),
                FarmHandlingOperation.created_at.desc(),
            )
            .limit(limit)
        ).all()
    )
    return [
        FarmHandlingOperationHistoryResponse(
            id=item.id,
            farm_id=item.farm_id,
            action=item.action,
            status=item.status,
            affected_count=item.affected_count,
            summary=item.summary,
            responsible=item.responsible,
            occurred_at=item.occurred_at,
            finance_entry_id=item.finance_entry_id or "",
        )
        for item in items
    ]


@router.post(
    "/handling/batch",
    response_model=FarmHandlingBatchResponse,
    status_code=201,
)
def execute_farm_handling_batch(
    payload: FarmHandlingBatchRequest,
    principal: Principal = Depends(get_principal),
    db: Session = Depends(get_db),
) -> FarmHandlingBatchResponse:
    action = payload.action.strip().lower()
    supported = {
        "sale_or_exit",
        "lot_movement",
        "weighing",
        "health",
        "reproduction",
        "category_change",
    }
    if action not in supported:
        raise HTTPException(status_code=422, detail="Tipo de manejo não suportado.")

    idempotency_key = payload.idempotency_key.strip()
    advisory_transaction_lock(
        db,
        (
            f"farm-handling:{principal.company.id}:"
            f"{payload.farm_id}:{idempotency_key}"
        ),
    )
    existing_operation = db.scalar(
        select(FarmHandlingOperation).where(
            FarmHandlingOperation.company_id == principal.company.id,
            FarmHandlingOperation.farm_id == payload.farm_id,
            FarmHandlingOperation.idempotency_key == idempotency_key,
        )
    )
    if existing_operation is not None:
        if existing_operation.action != action:
            raise HTTPException(
                status_code=409,
                detail=(
                    "A chave desta operação já foi usada em outro tipo de manejo."
                ),
            )
        return _handling_response_from_operation(
            existing_operation,
            repeated=True,
        )

    required_permission = {
        "sale_or_exit": "herd.write",
        "lot_movement": "herd.write",
        "weighing": "herd.write",
        "health": "health.write",
        "reproduction": "reproduction.write",
        "category_change": "herd.write",
    }[action]
    _require_handling_permission(principal, required_permission)

    animals = _handling_animals(
        db,
        principal,
        farm_id=payload.farm_id,
        animal_ids=payload.animal_ids,
    )
    occurred_at = payload.occurred_at or datetime.now(timezone.utc)
    handling_id = new_id("handling")
    created_ids: list[str] = []
    finance_entry_id: str | None = None

    if action in {"sale_or_exit", "lot_movement"}:
        target_lot: HerdLot | None = None
        if action == "lot_movement":
            if not payload.to_lot_id:
                raise HTTPException(status_code=422, detail="Selecione o lote de destino.")
            target_lot = _lot(db, principal, payload.to_lot_id)
            if target_lot.farm_id != payload.farm_id:
                raise HTTPException(status_code=422, detail="Lote de destino pertence a outra fazenda.")
            if target_lot.status != "active":
                raise HTTPException(status_code=422, detail="Lote de destino está inativo.")

        for animal in animals:
            movement = AnimalMovement(
                id=new_id("movement"),
                tenant_id=principal.company.tenant_id,
                company_id=principal.company.id,
                farm_id=payload.farm_id,
                animal_id=animal.id,
                movement_type="sale" if action == "sale_or_exit" else "lot_change",
                from_lot_id=animal.lot_id,
                to_lot_id=target_lot.id if target_lot else None,
                occurred_at=occurred_at,
                reason=payload.reason or payload.notes,
                document_reference=payload.document_reference or payload.sale_document,
                created_by=principal.user.id,
            )
            db.add(movement)
            created_ids.append(movement.id)
            if action == "sale_or_exit":
                animal.lot_id = None
                animal.status = "sale"
                metadata = dict(animal.metadata_json or {})
                metadata["sale"] = {
                    "handling_id": handling_id,
                    "occurred_at": occurred_at.isoformat(),
                    "counterparty": payload.sale_counterparty,
                    "document": payload.sale_document,
                    "total_batch_amount": payload.sale_total_amount,
                    "estimated_amount_per_animal": (
                        payload.sale_total_amount / len(animals)
                        if animals and payload.sale_total_amount > 0
                        else 0
                    ),
                }
                animal.metadata_json = metadata
            else:
                animal.lot_id = target_lot.id
                animal.status = "active"

        if action == "sale_or_exit" and payload.sale_total_amount > 0:
            finance_entry_id = new_id("finance")
            db.add(
                FinancialEntry(
                    id=finance_entry_id,
                    tenant_id=principal.company.tenant_id,
                    company_id=principal.company.id,
                    farm_id=payload.farm_id,
                    entry_type="income",
                    category="livestock_sale",
                    cost_center="Rebanho",
                    description=f"Venda de {len(animals)} animal(is)",
                    amount=payload.sale_total_amount,
                    status="pending",
                    competence_date=occurred_at,
                    due_date=occurred_at,
                    counterparty=payload.sale_counterparty,
                    document_number=payload.sale_document,
                    reference_type="farm_handling",
                    reference_id=handling_id,
                    notes=payload.notes,
                    created_by=principal.user.id,
                )
            )

    elif action == "category_change":
        category = payload.category.strip()
        if not category:
            raise HTTPException(status_code=422, detail="Informe a nova categoria.")
        for animal in animals:
            previous = animal.category
            animal.category = category
            movement = AnimalMovement(
                id=new_id("movement"),
                tenant_id=principal.company.tenant_id,
                company_id=principal.company.id,
                farm_id=payload.farm_id,
                animal_id=animal.id,
                movement_type="category_change",
                from_lot_id=animal.lot_id,
                to_lot_id=animal.lot_id,
                occurred_at=occurred_at,
                reason=payload.reason or f"Categoria: {previous} → {category}",
                document_reference=payload.document_reference,
                created_by=principal.user.id,
            )
            db.add(movement)
            created_ids.append(movement.id)

    elif action == "weighing":
        by_animal = {entry.animal_id: entry for entry in payload.weights}
        if any(animal.id not in by_animal for animal in animals):
            raise HTTPException(
                status_code=422,
                detail="Informe o peso de todos os animais selecionados.",
            )
        for animal in animals:
            entry = by_animal[animal.id]
            item = WeightRecord(
                id=new_id("weight"),
                tenant_id=principal.company.tenant_id,
                company_id=principal.company.id,
                farm_id=payload.farm_id,
                animal_id=animal.id,
                weight=entry.weight,
                body_condition_score=entry.body_condition_score,
                source="farm_handling",
                equipment="",
                measured_at=occurred_at,
                notes=payload.notes,
                created_by=principal.user.id,
            )
            db.add(item)
            created_ids.append(item.id)
            animal.current_weight = entry.weight
            animal.body_condition_score = entry.body_condition_score
            _sync_weight_schedule_task(db=db, principal=principal, animal=animal)

    elif action == "health":
        event_type = payload.health_event_type.strip()
        if not event_type:
            raise HTTPException(status_code=422, detail="Informe o tipo de evento sanitário.")
        for animal in animals:
            item = HealthEvent(
                id=new_id("health"),
                tenant_id=principal.company.tenant_id,
                company_id=principal.company.id,
                farm_id=payload.farm_id,
                animal_id=animal.id,
                lot_id=animal.lot_id,
                event_type=event_type,
                product_name=payload.health_product_name,
                dosage=payload.health_dosage,
                route=payload.health_route,
                occurred_at=occurred_at,
                responsible=payload.responsible,
                notes=payload.notes,
                next_date=payload.health_next_date,
                status="completed",
                treatment_cost=payload.health_treatment_cost_per_animal,
                created_by=principal.user.id,
            )
            db.add(item)
            created_ids.append(item.id)
            if payload.health_treatment_cost_per_animal > 0:
                db.add(
                    FinancialEntry(
                        id=new_id("finance"),
                        tenant_id=principal.company.tenant_id,
                        company_id=principal.company.id,
                        farm_id=payload.farm_id,
                        animal_id=animal.id,
                        lot_id=animal.lot_id,
                        entry_type="expense",
                        category="health",
                        cost_center="Sanidade",
                        description=f"Evento sanitário: {event_type}",
                        amount=payload.health_treatment_cost_per_animal,
                        status="paid",
                        competence_date=occurred_at,
                        paid_at=occurred_at,
                        reference_type="health_event",
                        reference_id=item.id,
                        notes=payload.notes,
                        created_by=principal.user.id,
                    )
                )
            _sync_operational_task(
                db=db,
                principal=principal,
                farm_id=payload.farm_id,
                source_type="health_event",
                source_id=item.id,
                title=f"Retorno sanitário — {event_type}",
                description=f"Retorno programado para {animal.name or animal.tag or animal.id}.",
                due_at=payload.health_next_date,
                priority="medium",
            )

    elif action == "reproduction":
        event_type = payload.reproduction_event_type.strip()
        if not event_type:
            raise HTTPException(status_code=422, detail="Informe o tipo de evento reprodutivo.")
        probe = ReproductionEventCreateRequest(
            event_type=event_type,
            event_code=payload.reproduction_event_code,
            protocol_name=payload.reproduction_protocol_name,
            sire_reference=payload.reproduction_sire_reference,
            result=payload.reproduction_result,
            responsible=payload.responsible,
            occurred_at=occurred_at,
            expected_date=payload.reproduction_expected_date,
            notes=payload.notes,
        )
        status_value = _derive_reproductive_status(probe)
        event_code = payload.reproduction_event_code or REPRODUCTION_CODES.get(
            event_type,
            "observation",
        )
        for animal in animals:
            item = ReproductionEvent(
                id=new_id("reproduction"),
                tenant_id=principal.company.tenant_id,
                company_id=principal.company.id,
                farm_id=payload.farm_id,
                animal_id=animal.id,
                event_type=event_type,
                event_code=event_code,
                protocol_name=payload.reproduction_protocol_name,
                sire_reference=payload.reproduction_sire_reference,
                result=payload.reproduction_result,
                reproductive_status=status_value,
                responsible=payload.responsible,
                occurred_at=occurred_at,
                expected_date=payload.reproduction_expected_date,
                notes=payload.notes,
                created_by=principal.user.id,
            )
            db.add(item)
            created_ids.append(item.id)
            animal.last_reproduction_event_at = occurred_at
            if status_value:
                animal.reproductive_status = status_value
            if event_code == "pregnancy_diagnosis" and status_value == "pregnant":
                animal.expected_calving_at = payload.reproduction_expected_date
            elif event_code in {"calving", "abortion", "reproductive_cull"}:
                animal.expected_calving_at = None
            _sync_operational_task(
                db=db,
                principal=principal,
                farm_id=payload.farm_id,
                source_type="reproduction_event",
                source_id=item.id,
                title=f"{event_type} — {animal.name or animal.tag or animal.id}",
                description=f"Retorno reprodutivo de {animal.name or animal.tag or animal.id}.",
                due_at=payload.reproduction_expected_date,
                priority="medium",
            )

    summaries = {
        "sale_or_exit": f"{len(animals)} animal(is) baixados por venda/saída.",
        "lot_movement": f"{len(animals)} animal(is) movimentados de lote.",
        "weighing": f"{len(animals)} pesagem(ns) registrada(s).",
        "health": f"{len(animals)} evento(s) sanitário(s) registrado(s).",
        "reproduction": f"{len(animals)} evento(s) reprodutivo(s) registrado(s).",
        "category_change": f"{len(animals)} animal(is) tiveram a categoria atualizada.",
    }

    operation = FarmHandlingOperation(
        id=handling_id,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=payload.farm_id,
        idempotency_key=idempotency_key,
        action=action,
        status="completed",
        affected_count=len(animals),
        animal_ids_json=[animal.id for animal in animals],
        created_ids_json=created_ids,
        finance_entry_id=finance_entry_id or "",
        summary=summaries[action],
        responsible=payload.responsible,
        notes=payload.notes,
        occurred_at=occurred_at,
        created_by=principal.user.id,
    )
    db.add(operation)
    db.commit()
    db.refresh(operation)
    return _handling_response_from_operation(operation, repeated=False)


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

    _sync_weight_schedule_task(
        db=db,
        principal=principal,
        animal=animal,
    )
    db.commit()
    db.refresh(item)
    return item


@router.patch("/animals/{animal_id}/weights/{weight_id}", response_model=WeightResponse)
def update_weight(
    animal_id: str,
    weight_id: str,
    payload: WeightUpdateRequest,
    principal: Principal = Depends(require_permission("herd.write")),
    db: Session = Depends(get_db),
) -> WeightRecord:
    animal = _animal(db, principal, animal_id)
    item = db.scalar(
        select(WeightRecord).where(
            WeightRecord.id == weight_id,
            WeightRecord.company_id == principal.company.id,
            WeightRecord.animal_id == animal.id,
        )
    )
    if item is None:
        raise HTTPException(status_code=404, detail="Pesagem não encontrada.")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(item, field, value)
    db.flush()
    _refresh_animal_weight_state(db=db, animal=animal)
    _sync_weight_schedule_task(
        db=db,
        principal=principal,
        animal=animal,
    )
    db.commit()
    db.refresh(item)
    return item


@router.delete(
    "/animals/{animal_id}/weights/{weight_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    response_class=Response,
    response_model=None,
)
def delete_weight(
    animal_id: str,
    weight_id: str,
    principal: Principal = Depends(require_permission("herd.write")),
    db: Session = Depends(get_db),
) -> Response:
    animal = _animal(db, principal, animal_id)
    item = db.scalar(
        select(WeightRecord).where(
            WeightRecord.id == weight_id,
            WeightRecord.company_id == principal.company.id,
            WeightRecord.animal_id == animal.id,
        )
    )
    if item is None:
        raise HTTPException(status_code=404, detail="Pesagem não encontrada.")
    db.delete(item)
    db.flush()
    _refresh_animal_weight_state(db=db, animal=animal)
    _sync_weight_schedule_task(
        db=db,
        principal=principal,
        animal=animal,
    )
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


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
    _farm_allowed(db, principal, farm_id)
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
    upcoming = [{"event_id": e.id, "animal_id": e.animal_id, "type": e.event_type, "due_at": e.expected_date.isoformat()} for e in events if e.expected_date and _v10_utc(e.expected_date) >= now][:100]
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
    _farm_allowed(db, principal, payload.farm_id)
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
    _farm_allowed(db, principal, item.farm_id)
    changes = payload.model_dump(exclude_unset=True)
    stock_fields_changed = bool({"inventory_product_id", "inventory_quantity"} & set(changes))
    cost_fields_changed = stock_fields_changed or "treatment_cost" in changes

    if stock_fields_changed:
        consumed = list(
            db.scalars(
                select(InventoryMovement).where(
                    InventoryMovement.company_id == principal.company.id,
                    InventoryMovement.reference_type.in_({"health_event", "health_event_adjusted"}),
                    InventoryMovement.reference_id.like(f"{item.id}%"),
                    InventoryMovement.movement_type == "health_consumption",
                )
            ).all()
        )
        reversals = list(
            db.scalars(
                select(InventoryMovement).where(
                    InventoryMovement.company_id == principal.company.id,
                    InventoryMovement.reference_type == "health_event_reversal",
                    InventoryMovement.reference_id.like(f"{item.id}%"),
                )
            ).all()
        )
        consumed_by_product: dict[str, float] = defaultdict(float)
        reversed_by_product: dict[str, float] = defaultdict(float)
        unit_cost_by_product: dict[str, float] = {}
        for movement in consumed:
            consumed_by_product[movement.product_id] += movement.quantity
            unit_cost_by_product[movement.product_id] = movement.unit_cost
        for movement in reversals:
            reversed_by_product[movement.product_id] += movement.quantity
        for product_id, consumed_qty in consumed_by_product.items():
            outstanding_qty = max(
                0.0,
                consumed_qty - reversed_by_product.get(product_id, 0.0),
            )
            if outstanding_qty <= 0:
                continue
            original_product = _inventory_product(
                db, principal, product_id, for_update=True
            )
            _apply_stock_movement(
                db=db, principal=principal, product=original_product,
                movement_type="return", quantity=outstanding_qty,
                unit_cost=unit_cost_by_product.get(product_id, 0),
                reason=f"Ajuste do evento sanitário {item.event_type}",
                reference_type="health_event_reversal",
                reference_id=f"{item.id}:patch:{product_id}:{len(consumed)}",
                occurred_at=datetime.now(timezone.utc),
            )

    for field, value in changes.items():
        setattr(item, field, value)

    if stock_fields_changed and item.inventory_product_id and item.inventory_quantity > 0:
        product = _inventory_product(db, principal, item.inventory_product_id, for_update=True)
        if product.farm_id != item.farm_id:
            raise HTTPException(status_code=422, detail="Produto pertence a outra fazenda.")
        _apply_stock_movement(
            db=db, principal=principal, product=product,
            movement_type="health_consumption", quantity=item.inventory_quantity,
            unit_cost=product.average_cost, reason=f"Evento sanitário: {item.event_type}",
            product_batch=item.product_batch, reference_type="health_event_adjusted",
            reference_id=f"{item.id}:{datetime.now(timezone.utc).timestamp()}",
            occurred_at=item.occurred_at,
        )
        if "treatment_cost" not in changes or item.treatment_cost <= 0:
            item.treatment_cost = item.inventory_quantity * product.average_cost

    if cost_fields_changed:
        linked_finance = db.scalars(
            select(FinancialEntry).where(
                FinancialEntry.company_id == principal.company.id,
                FinancialEntry.reference_type == "health_event",
                FinancialEntry.reference_id == item.id,
            )
        ).all()
        for entry in linked_finance:
            db.delete(entry)
        if item.treatment_cost > 0:
            db.add(FinancialEntry(
                id=new_id("finance"), tenant_id=principal.company.tenant_id,
                company_id=principal.company.id, farm_id=item.farm_id,
                animal_id=item.animal_id, lot_id=item.lot_id, entry_type="expense",
                category="health", cost_center="Sanidade",
                description=f"Evento sanitário: {item.event_type}", amount=item.treatment_cost,
                status="paid", competence_date=item.occurred_at, paid_at=item.occurred_at,
                reference_type="health_event", reference_id=item.id,
                created_by=principal.user.id,
            ))

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
    _farm_allowed(db, principal, item.farm_id)

    consumption_movements = list(
        db.scalars(
            select(InventoryMovement).where(
                InventoryMovement.company_id == principal.company.id,
                InventoryMovement.reference_id.like(f"{item.id}%"),
                InventoryMovement.movement_type == "health_consumption",
            )
        ).all()
    )
    reversal_movements = list(
        db.scalars(
            select(InventoryMovement).where(
                InventoryMovement.company_id == principal.company.id,
                InventoryMovement.reference_type == "health_event_reversal",
                InventoryMovement.reference_id.like(f"{item.id}%"),
            )
        ).all()
    )
    consumed_by_product: dict[str, float] = defaultdict(float)
    reversed_by_product: dict[str, float] = defaultdict(float)
    last_cost: dict[str, float] = {}
    for movement in consumption_movements:
        consumed_by_product[movement.product_id] += movement.quantity
        last_cost[movement.product_id] = movement.unit_cost
    for movement in reversal_movements:
        reversed_by_product[movement.product_id] += movement.quantity
    for product_id, consumed_qty in consumed_by_product.items():
        outstanding = max(0.0, consumed_qty - reversed_by_product.get(product_id, 0.0))
        if outstanding <= 0:
            continue
        product = _inventory_product(db, principal, product_id, for_update=True)
        _apply_stock_movement(
            db=db, principal=principal, product=product,
            movement_type="return", quantity=outstanding,
            unit_cost=last_cost.get(product_id, 0),
            reason=f"Estorno do evento sanitário {item.event_type}",
            reference_type="health_event_reversal",
            reference_id=f"{item.id}:delete:{product_id}",
            occurred_at=datetime.now(timezone.utc),
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
    _farm_allowed(db, principal, farm_id)
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
    _farm_allowed(db, principal, payload.farm_id)
    item = HealthProtocol(id=new_id("health_protocol"), tenant_id=principal.company.tenant_id, company_id=principal.company.id, created_by=principal.user.id, **payload.model_dump())
    db.add(item); db.commit(); db.refresh(item); return item


@router.get("/health/protocols", response_model=list[HealthProtocolResponse])
def list_health_protocols(farm_id: str, principal: Principal = Depends(require_permission("health.read")), db: Session = Depends(get_db)) -> list[HealthProtocol]:
    _farm_allowed(db, principal, farm_id)
    return list(db.scalars(select(HealthProtocol).where(HealthProtocol.company_id == principal.company.id, HealthProtocol.farm_id == farm_id, HealthProtocol.active.is_(True))).all())


@router.post("/health/protocols/{protocol_id}/apply", response_model=list[HealthEventResponse], status_code=201)
def apply_health_protocol(protocol_id: str, payload: HealthProtocolApplyRequest, principal: Principal = Depends(require_permission("health.write")), db: Session = Depends(get_db)) -> list[HealthEvent]:
    protocol = db.scalar(select(HealthProtocol).where(HealthProtocol.id == protocol_id, HealthProtocol.company_id == principal.company.id))
    if protocol is None: raise HTTPException(status_code=404, detail="Protocolo não encontrado.")
    _farm_allowed(db, principal, protocol.farm_id)
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
    _farm_allowed(db, principal, payload.farm_id)
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
    _farm_allowed(db, principal, farm_id)
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
    _farm_allowed(db, principal, product.farm_id)
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
    _farm_allowed(db, principal, payload.farm_id)
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
    _farm_allowed(db, principal, farm_id)
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
    _farm_allowed(db, principal, payload.farm_id)
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
    _farm_allowed(db, principal, farm_id)
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
    _farm_allowed(db, principal, farm_id)
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
    _farm_allowed(db, principal, farm_id)
    now = datetime.now(timezone.utc)
    limit = now + timedelta(days=max(0, days))
    events = list(db.scalars(select(HealthEvent).where(
        HealthEvent.company_id == principal.company.id,
        HealthEvent.farm_id == farm_id,
    )).all())
    alerts: list[dict] = []
    for event in events:
        base = {"event_id": event.id, "animal_id": event.animal_id, "lot_id": event.lot_id, "event_type": event.event_type}
        if event.next_date and _v10_utc(event.next_date) <= limit and event.status not in {"cancelled", "completed_future"}:
            alerts.append({**base, "alert_type": "scheduled_health_action", "due_at": event.next_date.isoformat(), "severity": "high" if _v10_utc(event.next_date) < now else "medium", "message": "Ação sanitária programada."})
        for kind, value in (("meat_withdrawal", event.withdrawal_meat_until), ("milk_withdrawal", event.withdrawal_milk_until)):
            if value and _v10_utc(value) >= now:
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
    _farm_allowed(db, principal, product.farm_id)
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
    _farm_allowed(db, principal, payload.farm_id)
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
    _farm_allowed(db, principal, farm_id)
    now=datetime.now(timezone.utc); limit=now+timedelta(days=max(0,expiry_days)); alerts=[]
    products=db.scalars(select(InventoryProduct).where(InventoryProduct.company_id==principal.company.id,
        InventoryProduct.farm_id==farm_id, InventoryProduct.active.is_(True))).all()
    for p in products:
        base=dict(product_id=p.id, product_name=p.name, quantity=p.quantity,
                  minimum_quantity=p.minimum_quantity, expiry_date=p.expiry_date)
        if p.quantity <= 0: alerts.append({**base,"alert_type":"out_of_stock","severity":"critical","message":"Produto sem estoque."})
        elif p.quantity <= p.minimum_quantity: alerts.append({**base,"alert_type":"low_stock","severity":"high","message":"Produto atingiu o estoque mínimo."})
        if p.expiry_date and _v10_utc(p.expiry_date) < now: alerts.append({**base,"alert_type":"expired","severity":"critical","message":"Produto vencido."})
        elif p.expiry_date and _v10_utc(p.expiry_date) <= limit: alerts.append({**base,"alert_type":"near_expiry","severity":"medium","message":"Produto próximo do vencimento."})
    return alerts


@router.post("/nutrition/ingredients", response_model=NutritionIngredientResponse, status_code=201)
def create_nutrition_ingredient(payload: NutritionIngredientCreateRequest,
    principal: Principal = Depends(require_permission("nutrition.write")), db: Session = Depends(get_db)) -> NutritionIngredient:
    _farm_allowed(db, principal,payload.farm_id)
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
    _farm_allowed(db, principal,farm_id)
    return list(db.scalars(select(NutritionIngredient).where(NutritionIngredient.company_id==principal.company.id,
        NutritionIngredient.farm_id==farm_id,NutritionIngredient.active.is_(True)).order_by(NutritionIngredient.name)).all())


@router.post("/nutrition/plans", response_model=NutritionPlanResponse, status_code=201)
def create_nutrition_plan(payload: NutritionPlanCreateRequest,
    principal: Principal = Depends(require_permission("nutrition.write")), db: Session = Depends(get_db)) -> NutritionPlan:
    _farm_allowed(db, principal,payload.farm_id); lot=_lot(db,principal,payload.lot_id)
    if lot.farm_id != payload.farm_id: raise HTTPException(status_code=422,detail="Lote pertence a outra fazenda.")
    count=payload.animal_count or (db.scalar(select(func.count()).select_from(LivestockAnimal).where(
        LivestockAnimal.company_id==principal.company.id,LivestockAnimal.lot_id==lot.id,LivestockAnimal.status=="active")) or 0)
    data=payload.model_dump(exclude={"start_date","animal_count"})
    item=NutritionPlan(id=new_id("diet"),tenant_id=principal.company.tenant_id,company_id=principal.company.id,
        animal_count=count,start_date=payload.start_date or datetime.now(timezone.utc),created_by=principal.user.id,**data)
    db.add(item)
    db.flush()
    _sync_nutrition_plan_task(
        db=db,
        principal=principal,
        plan=item,
    )
    db.commit()
    db.refresh(item)
    return item


@router.get("/nutrition/plans", response_model=list[NutritionPlanResponse])
def list_nutrition_plans(farm_id: str, lot_id: str | None=None,
    principal: Principal = Depends(require_permission("nutrition.read")), db: Session = Depends(get_db)) -> list[NutritionPlan]:
    _farm_allowed(db, principal,farm_id)
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


@router.delete("/nutrition/events/{event_id}", status_code=204)
def delete_nutrition_event(
    event_id: str,
    principal: Principal = Depends(require_permission("nutrition.write")),
    db: Session = Depends(get_db),
) -> Response:
    event = db.scalar(
        select(NutritionEvent).where(
            NutritionEvent.id == event_id,
            NutritionEvent.company_id == principal.company.id,
        )
    )
    if event is None:
        raise HTTPException(status_code=404, detail="Evento nutricional não encontrado.")
    _farm_allowed(db, principal, event.farm_id)

    consumptions = list(
        db.scalars(
            select(InventoryMovement).where(
                InventoryMovement.company_id == principal.company.id,
                InventoryMovement.reference_type == "nutrition_event",
                InventoryMovement.reference_id == event.id,
                InventoryMovement.movement_type == "nutrition_consumption",
            )
        ).all()
    )
    existing_returns = list(
        db.scalars(
            select(InventoryMovement).where(
                InventoryMovement.company_id == principal.company.id,
                InventoryMovement.reference_type == "nutrition_event_reversal",
                InventoryMovement.reference_id == event.id,
            )
        ).all()
    )
    returned = sum(m.quantity for m in existing_returns)
    consumed = sum(m.quantity for m in consumptions)
    outstanding = max(0.0, consumed - returned)
    if outstanding > 0 and consumptions:
        product = _inventory_product(db, principal, consumptions[-1].product_id, for_update=True)
        _apply_stock_movement(
            db=db, principal=principal, product=product, movement_type="return",
            quantity=outstanding, unit_cost=consumptions[-1].unit_cost,
            reason=f"Estorno do consumo nutricional {event.diet_name}",
            reference_type="nutrition_event_reversal", reference_id=event.id,
            occurred_at=datetime.now(timezone.utc),
        )

    linked_finance = db.scalars(
        select(FinancialEntry).where(
            FinancialEntry.company_id == principal.company.id,
            FinancialEntry.reference_type == "nutrition_event",
            FinancialEntry.reference_id == event.id,
        )
    ).all()
    for entry in linked_finance:
        db.delete(entry)
    db.delete(event)
    db.commit()
    return Response(status_code=204)


@router.get("/nutrition/performance")
def nutrition_performance(farm_id: str, lot_id: str | None=None,
    principal: Principal = Depends(require_permission("nutrition.read")), db: Session = Depends(get_db)) -> dict:
    _farm_allowed(db, principal,farm_id)
    q=select(NutritionEvent).where(NutritionEvent.company_id==principal.company.id,NutritionEvent.farm_id==farm_id)
    if lot_id: q=q.where(NutritionEvent.lot_id==lot_id)
    rows=list(db.scalars(q).all()); total_qty=sum(x.total_quantity for x in rows); total_cost=sum(x.estimated_cost for x in rows)
    avg_gain=sum(x.observed_daily_gain_kg for x in rows if x.observed_daily_gain_kg>0)/max(1,len([x for x in rows if x.observed_daily_gain_kg>0]))
    planned=sum(x.planned_quantity for x in rows); variance=total_qty-planned
    return {"farm_id":farm_id,"lot_id":lot_id,"events":len(rows),"total_quantity":total_qty,
        "planned_quantity":planned,"consumption_variance":variance,"total_cost":total_cost,
        "average_daily_gain_kg":avg_gain,"cost_per_kg_gain": total_cost/(avg_gain*max(1,len(rows))) if avg_gain>0 else 0}


@router.get("/integrity/reconciliation")
def operational_integrity_reconciliation(
    farm_id: str,
    principal: Principal = Depends(require_permission("livestock.read")),
    db: Session = Depends(get_db),
) -> dict:
    """Read-only cross-module reconciliation for one farm.

    This endpoint never mutates production data. It detects orphaned automatic
    finance entries, orphaned inventory movements/tasks, stale animal weight or
    reproductive state, and duplicate source references.
    """
    _farm_allowed(db, principal, farm_id)
    company_id = principal.company.id

    animals = list(db.scalars(select(LivestockAnimal).where(
        LivestockAnimal.company_id == company_id,
        LivestockAnimal.farm_id == farm_id,
    )).all())
    health_events = list(db.scalars(select(HealthEvent).where(
        HealthEvent.company_id == company_id,
        HealthEvent.farm_id == farm_id,
    )).all())
    nutrition_events = list(db.scalars(select(NutritionEvent).where(
        NutritionEvent.company_id == company_id,
        NutritionEvent.farm_id == farm_id,
    )).all())
    finance = list(db.scalars(select(FinancialEntry).where(
        FinancialEntry.company_id == company_id,
        FinancialEntry.farm_id == farm_id,
    )).all())
    movements = list(db.scalars(select(InventoryMovement).where(
        InventoryMovement.company_id == company_id,
        InventoryMovement.farm_id == farm_id,
    )).all())
    tasks = list(db.scalars(select(OperationalTask).where(
        OperationalTask.company_id == company_id,
        OperationalTask.farm_id == farm_id,
    )).all())

    health_ids = {x.id for x in health_events}
    nutrition_ids = {x.id for x in nutrition_events}
    reproduction_ids = set(db.scalars(select(ReproductionEvent.id).where(
        ReproductionEvent.company_id == company_id,
        ReproductionEvent.farm_id == farm_id,
    )).all())

    issues: list[dict] = []
    seen_finance_refs: set[tuple[str, str]] = set()
    for entry in finance:
        key = (entry.reference_type or "", entry.reference_id or "")
        if all(key) and key in seen_finance_refs:
            issues.append({"code":"duplicate_finance_reference","entity_id":entry.id,"reference_type":key[0],"reference_id":key[1]})
        if all(key): seen_finance_refs.add(key)
        if entry.reference_type == "health_event" and entry.reference_id not in health_ids:
            issues.append({"code":"orphan_finance_health","entity_id":entry.id,"reference_id":entry.reference_id})
        if entry.reference_type == "nutrition_event" and entry.reference_id not in nutrition_ids:
            issues.append({"code":"orphan_finance_nutrition","entity_id":entry.id,"reference_id":entry.reference_id})

    for movement in movements:
        if movement.reference_type in {"health_event", "health_event_adjusted"}:
            source_id = (movement.reference_id or "").split(":",1)[0]
            if source_id and source_id not in health_ids:
                issues.append({"code":"orphan_stock_health","entity_id":movement.id,"reference_id":movement.reference_id})
        if movement.reference_type == "nutrition_event" and movement.reference_id not in nutrition_ids:
            issues.append({"code":"orphan_stock_nutrition","entity_id":movement.id,"reference_id":movement.reference_id})

    for task in tasks:
        if task.source_type == "health_event" and task.source_id not in health_ids:
            issues.append({"code":"orphan_task_health","entity_id":task.id,"source_id":task.source_id})
        if task.source_type == "reproduction_event" and task.source_id not in reproduction_ids:
            issues.append({"code":"orphan_task_reproduction","entity_id":task.id,"source_id":task.source_id})

    for animal in animals:
        latest_weight = db.scalar(select(WeightRecord).where(
            WeightRecord.company_id == company_id,
            WeightRecord.animal_id == animal.id,
        ).order_by(WeightRecord.measured_at.desc(), WeightRecord.id.desc()).limit(1))
        expected_weight = latest_weight.weight if latest_weight else 0
        if abs((animal.current_weight or 0) - expected_weight) > 0.001:
            issues.append({"code":"stale_animal_weight","entity_id":animal.id,"stored":animal.current_weight or 0,"expected":expected_weight})

        latest_repro = db.scalar(select(ReproductionEvent).where(
            ReproductionEvent.company_id == company_id,
            ReproductionEvent.animal_id == animal.id,
        ).order_by(ReproductionEvent.occurred_at.desc(), ReproductionEvent.id.desc()).limit(1))
        expected_status = latest_repro.reproductive_status if latest_repro else ""
        if (animal.reproductive_status or "") != (expected_status or ""):
            issues.append({"code":"stale_reproductive_status","entity_id":animal.id,"stored":animal.reproductive_status or "","expected":expected_status or ""})

    counts = defaultdict(int)
    for issue in issues: counts[issue["code"]] += 1
    return {
        "farm_id": farm_id,
        "status": "ok" if not issues else "attention",
        "issue_count": len(issues),
        "counts": dict(sorted(counts.items())),
        "issues": issues,
        "checked": {
            "animals": len(animals), "health_events": len(health_events),
            "nutrition_events": len(nutrition_events), "financial_entries": len(finance),
            "inventory_movements": len(movements), "operational_tasks": len(tasks),
        },
    }




@router.post("/intelligence/smart-agenda/reconcile")
def smart_agenda_reconcile(
    farm_id: str,
    principal: Principal = Depends(require_permission("automation.manage")),
    db: Session = Depends(get_db),
) -> dict:
    """V14 — sincroniza a Agenda Inteligente com os módulos operacionais."""
    counters = _sync_existing_smart_agenda(
        db=db,
        principal=principal,
        farm_id=farm_id,
    )
    db.commit()

    open_tasks = db.scalar(
        select(func.count(OperationalTask.id)).where(
            OperationalTask.company_id == principal.company.id,
            OperationalTask.farm_id == farm_id,
            OperationalTask.status.in_(["open", "in_progress"]),
        )
    ) or 0

    return {
        "farm_id": farm_id,
        "status": "synchronized",
        "sources": counters,
        "open_tasks": int(open_tasks),
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def _v10_utc(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


@router.get("/intelligence/operational-alerts")
def operational_intelligence_alerts(
    farm_id: str,
    principal: Principal = Depends(require_permission("livestock.read")),
    db: Session = Depends(get_db),
) -> dict:
    """Motor V10 de alertas operacionais, calculado em tempo real e read-only.

    Os alertas são derivados dos dados oficiais de Rebanho, Sanidade,
    Reprodução, Nutrição, Estoque, Financeiro, Agenda e da reconciliação V9.
    Nenhum registro é criado, editado ou excluído por este endpoint.
    """
    _farm_allowed(db, principal, farm_id)
    company_id = principal.company.id
    now = datetime.now(timezone.utc)

    animals = list(db.scalars(select(LivestockAnimal).where(
        LivestockAnimal.company_id == company_id,
        LivestockAnimal.farm_id == farm_id,
    )).all())
    products = list(db.scalars(select(InventoryProduct).where(
        InventoryProduct.company_id == company_id,
        InventoryProduct.farm_id == farm_id,
    )).all())
    health_events = list(db.scalars(select(HealthEvent).where(
        HealthEvent.company_id == company_id,
        HealthEvent.farm_id == farm_id,
    )).all())
    plans = list(db.scalars(select(NutritionPlan).where(
        NutritionPlan.company_id == company_id,
        NutritionPlan.farm_id == farm_id,
    )).all())
    finance = list(db.scalars(select(FinancialEntry).where(
        FinancialEntry.company_id == company_id,
        FinancialEntry.farm_id == farm_id,
    )).all())
    tasks = list(db.scalars(select(OperationalTask).where(
        OperationalTask.company_id == company_id,
        OperationalTask.farm_id == farm_id,
    )).all())

    alerts: list[dict] = []

    severity_score = {
        "critical": 100,
        "high": 80,
        "medium": 55,
        "low": 30,
    }

    def add_alert(
        *,
        code: str,
        area: str,
        severity: str,
        title: str,
        description: str,
        entity_type: str = "",
        entity_id: str = "",
        due_at: datetime | None = None,
        action: str = "",
        score_bonus: int = 0,
    ) -> None:
        normalized_due = _v10_utc(due_at)
        score = min(
            100,
            severity_score.get(severity, 30) + max(0, score_bonus),
        )
        alerts.append({
            "id": f"v10:{code}:{entity_id or len(alerts) + 1}",
            "code": code,
            "area": area,
            "severity": severity,
            "priority_score": score,
            "title": title,
            "description": description,
            "entity_type": entity_type,
            "entity_id": entity_id,
            "due_at": normalized_due.isoformat() if normalized_due else None,
            "recommended_action": action,
        })

    # V9 integrity issues become high-priority operational alerts.
    reconciliation = operational_integrity_reconciliation(
        farm_id=farm_id,
        principal=principal,
        db=db,
    )
    for issue in reconciliation["issues"]:
        add_alert(
            code=f"integrity_{issue['code']}",
            area="Integridade",
            severity="high",
            title="Inconsistência entre módulos",
            description=(
                f"O reconciliador V9 detectou {issue['code']} "
                f"no registro {issue.get('entity_id', '')}."
            ),
            entity_type="integrity_issue",
            entity_id=str(issue.get("entity_id", "")),
            action=(
                "Revisar o registro de origem antes de executar novas "
                "operações dependentes."
            ),
            score_bonus=10,
        )

    # Inventory: minimum stock and expiry.
    for product in products:
        quantity = float(product.quantity or 0)
        minimum = float(product.minimum_quantity or 0)
        if quantity <= 0 and minimum > 0:
            add_alert(
                code="stockout",
                area="Estoque",
                severity="critical",
                title=f"{product.name} sem estoque",
                description=(
                    f"Saldo atual {quantity:g} {product.unit}; "
                    f"mínimo configurado {minimum:g} {product.unit}."
                ),
                entity_type="inventory_product",
                entity_id=product.id,
                action="Programar reposição imediata e revisar consumos pendentes.",
            )
        elif minimum > 0 and quantity < minimum:
            add_alert(
                code="stock_below_minimum",
                area="Estoque",
                severity="high",
                title=f"{product.name} abaixo do estoque mínimo",
                description=(
                    f"Saldo {quantity:g} {product.unit}; "
                    f"mínimo {minimum:g} {product.unit}."
                ),
                entity_type="inventory_product",
                entity_id=product.id,
                action="Planejar compra ou transferência de estoque.",
            )

        expiry = _v10_utc(product.expiry_date)
        if expiry is not None:
            days = (expiry - now).total_seconds() / 86400
            if days < 0:
                add_alert(
                    code="stock_expired",
                    area="Estoque",
                    severity="critical",
                    title=f"{product.name} vencido",
                    description=f"Vencimento em {expiry.date().isoformat()}.",
                    entity_type="inventory_product",
                    entity_id=product.id,
                    due_at=expiry,
                    action="Bloquear uso, segregar lote e registrar destinação.",
                )
            elif days <= 30:
                add_alert(
                    code="stock_expiring",
                    area="Estoque",
                    severity="medium",
                    title=f"{product.name} próximo do vencimento",
                    description=f"Vence em aproximadamente {max(0, int(days))} dia(s).",
                    entity_type="inventory_product",
                    entity_id=product.id,
                    due_at=expiry,
                    action="Priorizar uso seguro ou replanejar estoque.",
                    score_bonus=10 if days <= 7 else 0,
                )

    # Health: follow-up dates and active withdrawal periods.
    for event in health_events:
        next_date = _v10_utc(event.next_date)
        if next_date is not None and event.status not in {"cancelled", "canceled"}:
            days = (next_date - now).total_seconds() / 86400
            if days < 0:
                add_alert(
                    code="health_followup_overdue",
                    area="Sanidade",
                    severity="high",
                    title="Manejo sanitário atrasado",
                    description=(
                        f"{event.event_type} está vencido desde "
                        f"{next_date.date().isoformat()}."
                    ),
                    entity_type="health_event",
                    entity_id=event.id,
                    due_at=next_date,
                    action="Executar ou reprogramar o manejo e registrar evidência.",
                    score_bonus=min(15, max(0, int(abs(days) / 7))),
                )
            elif days <= 7:
                add_alert(
                    code="health_followup_due",
                    area="Sanidade",
                    severity="medium",
                    title="Manejo sanitário próximo",
                    description=(
                        f"{event.event_type} previsto para "
                        f"{next_date.date().isoformat()}."
                    ),
                    entity_type="health_event",
                    entity_id=event.id,
                    due_at=next_date,
                    action="Confirmar produto, responsável e disponibilidade na agenda.",
                )

        withdrawal = _v10_utc(event.withdrawal_until)
        if withdrawal is not None and withdrawal > now:
            add_alert(
                code="withdrawal_active",
                area="Sanidade",
                severity="high",
                title="Período de carência ativo",
                description=(
                    f"Carência ativa até {withdrawal.date().isoformat()} "
                    f"para o evento {event.event_type}."
                ),
                entity_type="health_event",
                entity_id=event.id,
                due_at=withdrawal,
                action="Impedir comercialização/abate até o término da carência.",
            )

    # Animals: body condition, stale weights, weight loss and calving.
    for animal in animals:
        if animal.status not in {"active", "Ativo"}:
            continue

        bcs = float(animal.body_condition_score or 0)
        if bcs > 0 and bcs < 2.5:
            add_alert(
                code="low_body_condition",
                area="Rebanho",
                severity="high" if bcs < 2 else "medium",
                title=f"ECC baixo — {animal.tag}",
                description=f"Escore corporal atual {bcs:g}.",
                entity_type="animal",
                entity_id=animal.id,
                action="Reavaliar dieta, sanidade e condição produtiva do animal.",
                score_bonus=10 if bcs < 2 else 0,
            )

        latest_two = list(db.scalars(
            select(WeightRecord).where(
                WeightRecord.company_id == company_id,
                WeightRecord.farm_id == farm_id,
                WeightRecord.animal_id == animal.id,
            ).order_by(
                WeightRecord.measured_at.desc(),
                WeightRecord.id.desc(),
            ).limit(2)
        ).all())

        if not latest_two:
            age_days = (
                now - _v10_utc(animal.created_at)
            ).total_seconds() / 86400
            if age_days >= 30:
                add_alert(
                    code="animal_without_weight",
                    area="Rebanho",
                    severity="medium",
                    title=f"Animal sem pesagem — {animal.tag}",
                    description="Não há pesagem registrada para este animal ativo.",
                    entity_type="animal",
                    entity_id=animal.id,
                    action="Programar pesagem e atualizar escore corporal.",
                )
        else:
            latest_date = _v10_utc(latest_two[0].measured_at)
            stale_days = (now - latest_date).total_seconds() / 86400
            if stale_days > 60:
                add_alert(
                    code="weight_stale",
                    area="Rebanho",
                    severity="medium",
                    title=f"Pesagem desatualizada — {animal.tag}",
                    description=f"Última pesagem há {int(stale_days)} dia(s).",
                    entity_type="animal",
                    entity_id=animal.id,
                    due_at=latest_date,
                    action="Programar nova pesagem para atualizar desempenho.",
                )

            if len(latest_two) == 2:
                current, previous = latest_two[0], latest_two[1]
                days = (
                    _v10_utc(current.measured_at)
                    - _v10_utc(previous.measured_at)
                ).total_seconds() / 86400
                if days > 0:
                    gmd = (float(current.weight) - float(previous.weight)) / days
                    if gmd < 0:
                        add_alert(
                            code="negative_daily_gain",
                            area="Nutrição",
                            severity="high",
                            title=f"Perda de peso — {animal.tag}",
                            description=f"GMD recente {gmd:.3f} kg/dia.",
                            entity_type="animal",
                            entity_id=animal.id,
                            action=(
                                "Investigar consumo, disponibilidade de dieta, "
                                "sanidade e competição no lote."
                            ),
                            score_bonus=10 if gmd < -0.2 else 0,
                        )

        calving = _v10_utc(animal.expected_calving_at)
        if calving is not None and animal.reproductive_status in {
            "pregnant", "prenhe", "gestante",
        }:
            days = (calving - now).total_seconds() / 86400
            if days < -3:
                add_alert(
                    code="calving_overdue",
                    area="Reprodução",
                    severity="high",
                    title=f"Parto previsto ultrapassado — {animal.tag}",
                    description=f"Data prevista {calving.date().isoformat()}.",
                    entity_type="animal",
                    entity_id=animal.id,
                    due_at=calving,
                    action="Verificar matriz e atualizar desfecho reprodutivo.",
                )
            elif days <= 14:
                add_alert(
                    code="calving_due",
                    area="Reprodução",
                    severity="medium",
                    title=f"Parto próximo — {animal.tag}",
                    description=f"Previsão em aproximadamente {max(0, int(days))} dia(s).",
                    entity_type="animal",
                    entity_id=animal.id,
                    due_at=calving,
                    action="Preparar lote maternidade e acompanhamento da matriz.",
                    score_bonus=10 if days <= 7 else 0,
                )

    # Nutrition plans: expiration and target performance.
    for plan in plans:
        end_date = _v10_utc(plan.end_date)
        if end_date is not None:
            days = (end_date - now).total_seconds() / 86400
            if days < 0:
                add_alert(
                    code="nutrition_plan_expired",
                    area="Nutrição",
                    severity="high",
                    title=f"Plano nutricional vencido — {plan.name}",
                    description=f"Plano encerrou em {end_date.date().isoformat()}.",
                    entity_type="nutrition_plan",
                    entity_id=plan.id,
                    due_at=end_date,
                    action="Reformular ou renovar o plano do lote.",
                )
            elif days <= 14:
                add_alert(
                    code="nutrition_plan_ending",
                    area="Nutrição",
                    severity="medium",
                    title=f"Plano nutricional próximo do fim — {plan.name}",
                    description=f"Restam aproximadamente {max(0, int(days))} dia(s).",
                    entity_type="nutrition_plan",
                    entity_id=plan.id,
                    due_at=end_date,
                    action="Preparar avaliação de desempenho e próximo plano.",
                )

    # Finance: overdue obligations/receivables, without exposing broad ledger.
    for entry in finance:
        due = _v10_utc(entry.due_date)
        if due is None or entry.status == "paid":
            continue
        if due < now:
            area_label = "pagar" if entry.entry_type == "expense" else "receber"
            add_alert(
                code=f"finance_overdue_{entry.entry_type}",
                area="Financeiro",
                severity="high",
                title=f"Conta a {area_label} vencida",
                description=(
                    f"{entry.description} — vencimento "
                    f"{due.date().isoformat()}."
                ),
                entity_type="financial_entry",
                entity_id=entry.id,
                due_at=due,
                action="Regularizar ou reprogramar o lançamento financeiro.",
            )

    # Agenda/tasks: due soon and overdue.
    for task in tasks:
        if task.status in {"completed", "cancelled", "canceled"}:
            continue
        due = _v10_utc(task.due_at)
        if due is None:
            continue
        days = (due - now).total_seconds() / 86400
        if days < 0:
            add_alert(
                code="task_overdue",
                area="Agenda",
                severity="high",
                title=f"Tarefa atrasada — {task.title}",
                description=f"Prazo expirou em {due.date().isoformat()}.",
                entity_type="operational_task",
                entity_id=task.id,
                due_at=due,
                action="Concluir, registrar evidência ou reprogramar a tarefa.",
                score_bonus=min(15, max(0, int(abs(days) / 7))),
            )
        elif days <= 3:
            add_alert(
                code="task_due",
                area="Agenda",
                severity="medium",
                title=f"Tarefa próxima — {task.title}",
                description=f"Prazo em aproximadamente {max(0, int(days))} dia(s).",
                entity_type="operational_task",
                entity_id=task.id,
                due_at=due,
                action="Confirmar responsável e recursos para execução.",
            )

    alerts.sort(
        key=lambda item: (
            -int(item["priority_score"]),
            item["due_at"] or "9999-12-31T00:00:00+00:00",
            item["area"],
            item["title"],
        )
    )

    by_severity: dict[str, int] = defaultdict(int)
    by_area: dict[str, int] = defaultdict(int)
    for alert in alerts:
        by_severity[alert["severity"]] += 1
        by_area[alert["area"]] += 1

    return {
        "contract_version": "10B",
        "farm_id": farm_id,
        "generated_at": now.isoformat(),
        "status": (
            "critical"
            if by_severity["critical"]
            else "attention"
            if by_severity["high"]
            else "watch"
            if by_severity["medium"]
            else "ok"
        ),
        "alert_count": len(alerts),
        "critical_count": by_severity["critical"],
        "high_count": by_severity["high"],
        "medium_count": by_severity["medium"],
        "low_count": by_severity["low"],
        "by_area": dict(sorted(by_area.items())),
        "alerts": alerts,
    }


@router.get("/intelligence/deployment-readiness")
def operational_intelligence_deployment_readiness() -> dict:
    """Contrato público e sem dados da consolidação operacional do 10B."""
    return {
        "status": "ready",
        "contract_version": "10B",
        "single_source": True,
        "farm_context_guard": True,
        "priority_position_contract": True,
        "global_integrity_audit": True,
        "migration": "0049",
    }


@router.get("/intelligence/operational-summary")
def operational_intelligence_summary(
    farm_id: str,
    principal: Principal = Depends(require_permission("livestock.read")),
    db: Session = Depends(get_db),
) -> dict:
    """Resumo executivo V10 baseado no motor de alertas operacionais."""
    _farm_allowed(db, principal, farm_id)
    company_id = principal.company.id

    alerts = operational_intelligence_alerts(
        farm_id=farm_id,
        principal=principal,
        db=db,
    )

    animals = list(db.scalars(select(LivestockAnimal).where(
        LivestockAnimal.company_id == company_id,
        LivestockAnimal.farm_id == farm_id,
    )).all())
    active_animals = [
        item for item in animals if item.status in {"active", "Ativo"}
    ]

    lots_count = db.scalar(select(func.count(HerdLot.id)).where(
        HerdLot.company_id == company_id,
        HerdLot.farm_id == farm_id,
    )) or 0

    income = db.scalar(select(func.coalesce(func.sum(FinancialEntry.amount), 0)).where(
        FinancialEntry.company_id == company_id,
        FinancialEntry.farm_id == farm_id,
        FinancialEntry.entry_type == "income",
    )) or 0
    expense = db.scalar(select(func.coalesce(func.sum(FinancialEntry.amount), 0)).where(
        FinancialEntry.company_id == company_id,
        FinancialEntry.farm_id == farm_id,
        FinancialEntry.entry_type == "expense",
    )) or 0

    score = 100
    score -= min(40, alerts["critical_count"] * 20)
    score -= min(30, alerts["high_count"] * 8)
    score -= min(20, alerts["medium_count"] * 3)
    score = max(0, score)

    if score >= 90:
        level = "excellent"
    elif score >= 75:
        level = "good"
    elif score >= 55:
        level = "attention"
    else:
        level = "critical"

    top_actions = [
        {
            "position": index + 1,
            # Compatibilidade com clientes V10-V15 que consumiam `priority`.
            "priority": index + 1,
            "area": alert["area"],
            "severity": alert["severity"],
            "title": alert["title"],
            "recommended_action": alert["recommended_action"],
            "entity_type": alert["entity_type"],
            "entity_id": alert["entity_id"],
            "due_at": alert["due_at"],
        }
        for index, alert in enumerate(alerts["alerts"][:5])
    ]


    # V15 — indicadores executivos realmente operacionais.
    females = [
        animal
        for animal in active_animals
        if (animal.sex or "").lower() in {"fêmea", "femea", "female"}
    ]
    pregnant = [
        animal
        for animal in females
        if (animal.reproductive_status or "").lower()
        in {"pregnant", "prenhe"}
    ]
    pregnancy_rate = (
        len(pregnant) / len(females) * 100
        if females
        else 0.0
    )

    current_weights = [
        float(animal.current_weight or 0)
        for animal in active_animals
        if float(animal.current_weight or 0) > 0
    ]
    average_weight = (
        sum(current_weights) / len(current_weights)
        if current_weights
        else 0.0
    )

    gmd_values: list[float] = []
    for animal in active_animals:
        recent = list(
            db.scalars(
                select(WeightRecord)
                .where(
                    WeightRecord.company_id == company_id,
                    WeightRecord.animal_id == animal.id,
                )
                .order_by(
                    WeightRecord.measured_at.desc(),
                    WeightRecord.id.desc(),
                )
                .limit(2)
            ).all()
        )
        if len(recent) < 2:
            continue
        latest, previous = recent[0], recent[1]
        days = (
            _v10_utc(latest.measured_at)
            - _v10_utc(previous.measured_at)
        ).total_seconds() / 86400
        if days > 0:
            gmd_values.append(
                (float(latest.weight) - float(previous.weight)) / days
            )
    average_gmd = (
        sum(gmd_values) / len(gmd_values)
        if gmd_values
        else 0.0
    )

    products = list(
        db.scalars(
            select(InventoryProduct).where(
                InventoryProduct.company_id == company_id,
                InventoryProduct.farm_id == farm_id,
                InventoryProduct.active.is_(True),
            )
        ).all()
    )
    critical_stock = sum(
        1
        for product in products
        if float(product.quantity or 0)
        <= float(product.minimum_quantity or 0)
    )

    now = datetime.now(timezone.utc)
    open_tasks = list(
        db.scalars(
            select(OperationalTask).where(
                OperationalTask.company_id == company_id,
                OperationalTask.farm_id == farm_id,
                OperationalTask.status.in_(["open", "in_progress"]),
            )
        ).all()
    )
    overdue_tasks = sum(
        1
        for task in open_tasks
        if _v10_utc(task.due_at) is not None
        and _v10_utc(task.due_at) < now
    )

    active_plans = list(
        db.scalars(
            select(NutritionPlan).where(
                NutritionPlan.company_id == company_id,
                NutritionPlan.farm_id == farm_id,
                NutritionPlan.active.is_(True),
            )
        ).all()
    )
    nutrition_monthly_cost = sum(
        float(plan.daily_amount_per_animal_kg or 0)
        * max(0, int(plan.animal_count or 0))
        * float(plan.cost_per_kg or 0)
        * 30
        for plan in active_plans
    )

    cost_per_active_animal = (
        float(expense) / len(active_animals)
        if active_animals
        else 0.0
    )

    return {
        "contract_version": "10B",
        "farm_id": farm_id,
        "generated_at": alerts["generated_at"],
        "operational_score": score,
        "operational_level": level,
        "herd": {
            "animals": len(animals),
            "active_animals": len(active_animals),
            "lots": int(lots_count),
        },
        "finance": {
            "income": float(income),
            "expense": float(expense),
            "balance": float(income) - float(expense),
        },
        "alerts": {
            "total": alerts["alert_count"],
            "critical": alerts["critical_count"],
            "high": alerts["high_count"],
            "medium": alerts["medium_count"],
            "low": alerts["low_count"],
            "by_area": alerts["by_area"],
        },
        "executive": {
            "pregnancy_rate_percent": round(pregnancy_rate, 2),
            "pregnant_females": len(pregnant),
            "eligible_females": len(females),
            "average_weight_kg": round(average_weight, 2),
            "average_gmd_kg_day": round(average_gmd, 3),
            "cost_per_active_animal": round(cost_per_active_animal, 2),
            "critical_stock_items": critical_stock,
            "open_tasks": len(open_tasks),
            "overdue_tasks": overdue_tasks,
            "nutrition_monthly_cost": round(nutrition_monthly_cost, 2),
        },
        "top_actions": top_actions,
    }


@router.post("/finance/v2", response_model=FinancialEntryPhase3Response, status_code=201)
def create_financial_entry_v2(payload: FinancialEntryPhase3CreateRequest,
    principal: Principal = Depends(require_permission("finance.write")), db: Session = Depends(get_db)) -> FinancialEntry:
    _farm_allowed(db, principal,payload.farm_id)
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
    _farm_allowed(db, principal,item.farm_id); item.paid_at=payload.paid_at or datetime.now(timezone.utc); item.status="paid"
    if payload.payment_method: item.payment_method=payload.payment_method
    db.commit(); db.refresh(item); return item


@router.get("/finance/v2", response_model=list[FinancialEntryPhase3Response])
def list_financial_entries_v2(farm_id: str,status: str|None=None,cost_center: str|None=None,lot_id: str|None=None,animal_id: str|None=None,
    principal: Principal=Depends(require_permission("finance.read")),db: Session=Depends(get_db)) -> list[FinancialEntry]:
    _farm_allowed(db, principal,farm_id); q=select(FinancialEntry).where(FinancialEntry.company_id==principal.company.id,FinancialEntry.farm_id==farm_id)
    if status: q=q.where(FinancialEntry.status==status)
    if cost_center: q=q.where(FinancialEntry.cost_center==cost_center)
    if lot_id: q=q.where(FinancialEntry.lot_id==lot_id)
    if animal_id: q=q.where(FinancialEntry.animal_id==animal_id)
    return list(db.scalars(q.order_by(FinancialEntry.created_at.desc())).all())


@router.get("/finance/summary", response_model=FinancialSummaryResponse)
def financial_summary(farm_id: str,
    principal: Principal=Depends(require_permission("finance.read")),db: Session=Depends(get_db)) -> dict:
    _farm_allowed(db, principal,farm_id); now=datetime.now(timezone.utc)
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
    _farm_allowed(db, principal,farm_id); start=datetime.now(timezone.utc); end=start+timedelta(days=max(1,days))
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
    _farm_allowed(db, principal, farm_id)
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
    _farm_allowed(db, principal, payload.farm_id)
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
    _farm_allowed(db, principal, item.farm_id)
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
    _farm_allowed(db, principal, item.farm_id)
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
    _farm_allowed(db, principal,item.farm_id)
    if payload.farm_id != item.farm_id:
        raise HTTPException(status_code=409, detail="A fazenda do produto não pode ser alterada.")
    if abs(payload.quantity - item.quantity) > 0.000001:
        raise HTTPException(
            status_code=409,
            detail="A quantidade deve ser alterada por uma movimentação de estoque.",
        )
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
    if item.quantity > 0.000001:
        raise HTTPException(status_code=409, detail="Zere o estoque antes de inativar o produto.")
    item.active=False; db.commit(); return Response(status_code=204)

@router.patch("/nutrition/plans/{plan_id}", response_model=NutritionPlanResponse)
def update_nutrition_plan(
    plan_id: str, payload: NutritionPlanCreateRequest,
    principal: Principal = Depends(require_permission("nutrition.write")),
    db: Session = Depends(get_db),
) -> NutritionPlan:
    item=db.scalar(select(NutritionPlan).where(NutritionPlan.id==plan_id,NutritionPlan.company_id==principal.company.id))
    if item is None: raise HTTPException(status_code=404,detail="Plano nutricional não encontrado.")
    _farm_allowed(db, principal,item.farm_id)
    if payload.farm_id != item.farm_id:
        raise HTTPException(status_code=409, detail="A fazenda do plano não pode ser alterada.")
    lot = _lot(db, principal, payload.lot_id)
    if lot.farm_id != item.farm_id:
        raise HTTPException(status_code=422, detail="Lote pertence a outra fazenda.")
    for key,value in payload.model_dump().items():
        if value is not None:
            setattr(item,key,value)
    db.flush()
    _sync_nutrition_plan_task(
        db=db,
        principal=principal,
        plan=item,
    )
    db.commit()
    db.refresh(item)
    return item

@router.delete("/nutrition/plans/{plan_id}", status_code=204)
def delete_nutrition_plan(
    plan_id: str,
    principal: Principal = Depends(require_permission("nutrition.write")),
    db: Session = Depends(get_db),
) -> Response:
    item=db.scalar(select(NutritionPlan).where(NutritionPlan.id==plan_id,NutritionPlan.company_id==principal.company.id))
    if item is None: raise HTTPException(status_code=404,detail="Plano nutricional não encontrado.")
    _farm_allowed(db, principal,item.farm_id)
    item.active=False
    _sync_nutrition_plan_task(
        db=db,
        principal=principal,
        plan=item,
    )
    db.commit()
    return Response(status_code=204)

@router.patch("/finance/v2/{entry_id}", response_model=FinancialEntryPhase3Response)
def update_financial_entry_v2(
    entry_id: str, payload: FinancialEntryPhase3CreateRequest,
    principal: Principal=Depends(require_permission("finance.write")),
    db: Session=Depends(get_db),
) -> FinancialEntry:
    item=db.scalar(select(FinancialEntry).where(FinancialEntry.id==entry_id,FinancialEntry.company_id==principal.company.id))
    if item is None: raise HTTPException(status_code=404,detail="Lançamento não encontrado.")
    _farm_allowed(db, principal,item.farm_id)
    if item.reference_type in {"health_event", "nutrition_event"}:
        raise HTTPException(
            status_code=409,
            detail="Lançamento integrado deve ser alterado no módulo de origem.",
        )
    if payload.farm_id != item.farm_id:
        raise HTTPException(status_code=409, detail="A fazenda do lançamento não pode ser alterada.")
    if payload.animal_id:
        animal = _animal(db, principal, payload.animal_id)
        if animal.farm_id != item.farm_id:
            raise HTTPException(status_code=422, detail="Animal pertence a outra fazenda.")
    if payload.lot_id:
        lot = _lot(db, principal, payload.lot_id)
        if lot.farm_id != item.farm_id:
            raise HTTPException(status_code=422, detail="Lote pertence a outra fazenda.")
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
    _farm_allowed(db, principal,item.farm_id)
    if item.reference_type in {"health_event", "nutrition_event"}:
        raise HTTPException(
            status_code=409,
            detail="Lançamento integrado deve ser excluído no módulo de origem.",
        )
    db.delete(item); db.commit(); return Response(status_code=204)
