from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..authz import Principal, require_farm_scope, require_permission
from ..database import get_db
from ..models import AuditLog, EntityState, Farm, SyncChange, new_id
from ..schemas import (
    AnimalCreateRequest,
    AnimalGenealogyNodeResponse,
    AnimalGenealogyResponse,
    AnimalHistoryResponse,
    AnimalResponse,
    AnimalTimelineResponse,
    AnimalUpdateRequest,
)
from ..services.audit import record_audit

router = APIRouter(prefix="/animals", tags=["animals"])


def _farm_for_principal(
    db: Session,
    principal: Principal,
    farm_id: str,
) -> Farm:
    farm = db.scalar(
        select(Farm).where(
            Farm.id == farm_id,
            Farm.company_id == principal.company.id,
            Farm.tenant_id == principal.company.tenant_id,
            Farm.active.is_(True),
        )
    )
    if farm is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Fazenda não encontrada na empresa ativa.",
        )
    require_farm_scope(principal, farm.id)
    return farm


def _animal_for_principal(
    db: Session,
    principal: Principal,
    animal_id: str,
) -> EntityState:
    animal = db.scalar(
        select(EntityState).where(
            EntityState.entity_type == "animal",
            EntityState.entity_id == animal_id,
            EntityState.company_id == principal.company.id,
            EntityState.tenant_id == principal.company.tenant_id,
            EntityState.deleted.is_(False),
        )
    )
    if animal is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Animal não encontrado na empresa ativa.",
        )
    require_farm_scope(principal, animal.farm_id)
    return animal


def _response(entity: EntityState) -> AnimalResponse:
    payload = dict(entity.payload or {})
    return AnimalResponse(
        id=entity.entity_id,
        tenant_id=entity.tenant_id,
        company_id=entity.company_id,
        farm_id=entity.farm_id or "",
        group_name=str(payload.get("group_name", "")),
        tag=str(payload.get("tag", "")),
        name=str(payload.get("name", "")),
        sisbov=str(payload.get("sisbov", "")),
        category=str(payload.get("category", "Não informada")),
        sex=str(payload.get("sex", "Fêmea")),
        breed=str(payload.get("breed", "Não informada")),
        birth_date=str(payload.get("birth_date", "")),
        weight=float(payload.get("weight", 0) or 0),
        body_condition_score=float(payload.get("body_condition_score", 0) or 0),
        status=str(payload.get("status", "Ativo")),
        mother_tag=str(payload.get("mother_tag", "")),
        father_tag=str(payload.get("father_tag", "")),
        origin=str(payload.get("origin", "")),
        photo_reference=str(payload.get("photo_reference", "")),
        notes=str(payload.get("notes", "")),
        acquisition_type=str(payload.get("acquisition_type", "Nascido na fazenda")),
        acquisition_date=str(payload.get("acquisition_date", "")),
        acquisition_value=float(payload.get("acquisition_value", 0) or 0),
        acquisition_counterparty=str(payload.get("acquisition_counterparty", "")),
        acquisition_document=str(payload.get("acquisition_document", "")),
        sale_date=str(payload.get("sale_date", "")),
        sale_value=float(payload.get("sale_value", 0) or 0),
        sale_counterparty=str(payload.get("sale_counterparty", "")),
        sale_document=str(payload.get("sale_document", "")),
        active=bool(payload.get("active", True)),
        version=entity.version,
        updated_at=entity.updated_at,
    )


def _record_change(db: Session, entity: EntityState) -> None:
    db.add(
        SyncChange(
            tenant_id=entity.tenant_id,
            company_id=entity.company_id,
            farm_id=entity.farm_id,
            entity_type="animal",
            entity_id=entity.entity_id,
            version=entity.version,
            payload=dict(entity.payload or {}),
            deleted=entity.deleted,
        )
    )


@router.get("", response_model=list[AnimalResponse])
def list_animals(
    farm_id: str = Query(...),
    group_name: str | None = Query(default=None),
    principal: Principal = Depends(require_permission("animals.read")),
    db: Session = Depends(get_db),
) -> list[AnimalResponse]:
    _farm_for_principal(db, principal, farm_id)

    entities = db.scalars(
        select(EntityState).where(
            EntityState.entity_type == "animal",
            EntityState.farm_id == farm_id,
            EntityState.company_id == principal.company.id,
            EntityState.tenant_id == principal.company.tenant_id,
            EntityState.deleted.is_(False),
        )
    ).all()

    responses = [_response(entity) for entity in entities]
    responses = [item for item in responses if item.active]

    if group_name is not None and group_name.strip():
        expected = group_name.strip()
        responses = [item for item in responses if item.group_name == expected]

    responses.sort(key=lambda item: (item.tag.lower(), item.name.lower()))
    return responses


def _genealogy_node(
    entity: EntityState | None,
    *,
    relation: str,
    fallback_tag: str = "",
) -> AnimalGenealogyNodeResponse | None:
    if entity is None:
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

    payload = dict(entity.payload or {})
    return AnimalGenealogyNodeResponse(
        id=entity.entity_id,
        farm_id=entity.farm_id or "",
        group_name=str(payload.get("group_name", "")),
        tag=str(payload.get("tag", "")),
        name=str(payload.get("name", "")),
        sex=str(payload.get("sex", "")),
        breed=str(payload.get("breed", "")),
        category=str(payload.get("category", "")),
        birth_date=str(payload.get("birth_date", "")),
        status=str(payload.get("status", "Ativo")),
        relation=relation,
        registered=True,
    )


@router.get(
    "/{animal_id}/genealogy",
    response_model=AnimalGenealogyResponse,
)
def animal_genealogy(
    animal_id: str,
    principal: Principal = Depends(
        require_permission("animals.read")
    ),
    db: Session = Depends(get_db),
) -> AnimalGenealogyResponse:
    animal = _animal_for_principal(db, principal, animal_id)

    allowed_farms = set(principal.membership.farm_ids or [])

    entities = db.scalars(
        select(EntityState).where(
            EntityState.entity_type == "animal",
            EntityState.company_id == principal.company.id,
            EntityState.tenant_id == principal.company.tenant_id,
            EntityState.deleted.is_(False),
        )
    ).all()

    if allowed_farms:
        entities = [
            entity
            for entity in entities
            if entity.farm_id in allowed_farms
        ]

    active_entities = [
        entity
        for entity in entities
        if bool((entity.payload or {}).get("active", True))
    ]

    by_tag: dict[str, EntityState] = {}
    for entity in active_entities:
        tag = str((entity.payload or {}).get("tag", "")).strip()
        if tag:
            by_tag[tag.casefold()] = entity

    payload = dict(animal.payload or {})
    animal_tag = str(payload.get("tag", "")).strip()
    father_tag = str(payload.get("father_tag", "")).strip()
    mother_tag = str(payload.get("mother_tag", "")).strip()

    father = by_tag.get(father_tag.casefold()) if father_tag else None
    mother = by_tag.get(mother_tag.casefold()) if mother_tag else None

    def parent_of(
        parent: EntityState | None,
        key: str,
    ) -> tuple[EntityState | None, str]:
        if parent is None:
            return None, ""

        parent_payload = dict(parent.payload or {})
        tag = str(parent_payload.get(key, "")).strip()
        if not tag:
            return None, ""

        return by_tag.get(tag.casefold()), tag

    paternal_grandfather, paternal_grandfather_tag = parent_of(
        father,
        "father_tag",
    )
    paternal_grandmother, paternal_grandmother_tag = parent_of(
        father,
        "mother_tag",
    )
    maternal_grandfather, maternal_grandfather_tag = parent_of(
        mother,
        "father_tag",
    )
    maternal_grandmother, maternal_grandmother_tag = parent_of(
        mother,
        "mother_tag",
    )

    children_entities: list[EntityState] = []
    full_siblings: list[EntityState] = []
    half_siblings: list[EntityState] = []

    father_key = father_tag.casefold()
    mother_key = mother_tag.casefold()
    animal_key = animal_tag.casefold()

    for candidate in active_entities:
        if candidate.entity_id == animal.entity_id:
            continue

        candidate_payload = dict(candidate.payload or {})
        candidate_father = str(
            candidate_payload.get("father_tag", "")
        ).strip().casefold()
        candidate_mother = str(
            candidate_payload.get("mother_tag", "")
        ).strip().casefold()

        if animal_key and (
            candidate_father == animal_key
            or candidate_mother == animal_key
        ):
            children_entities.append(candidate)

        shared_father = bool(
            father_key and candidate_father == father_key
        )
        shared_mother = bool(
            mother_key and candidate_mother == mother_key
        )

        if shared_father and shared_mother:
            full_siblings.append(candidate)
        elif shared_father or shared_mother:
            half_siblings.append(candidate)

    descendants: list[
        tuple[EntityState, int]
    ] = []
    visited = {animal.entity_id}
    current_generation = [(child, 1) for child in children_entities]

    while current_generation:
        descendant, generation = current_generation.pop(0)

        if descendant.entity_id in visited:
            continue

        visited.add(descendant.entity_id)
        descendants.append((descendant, generation))

        descendant_tag = str(
            (descendant.payload or {}).get("tag", "")
        ).strip().casefold()

        if not descendant_tag or generation >= 5:
            continue

        for candidate in active_entities:
            if candidate.entity_id in visited:
                continue

            candidate_payload = dict(candidate.payload or {})
            candidate_father = str(
                candidate_payload.get("father_tag", "")
            ).strip().casefold()
            candidate_mother = str(
                candidate_payload.get("mother_tag", "")
            ).strip().casefold()

            if (
                candidate_father == descendant_tag
                or candidate_mother == descendant_tag
            ):
                current_generation.append(
                    (candidate, generation + 1)
                )

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
        if generation == 1:
            return "Filho(a)"
        if generation == 2:
            return "Neto(a)"
        if generation == 3:
            return "Bisneto(a)"
        return f"Descendente — geração {generation}"

    return AnimalGenealogyResponse(
        animal=_genealogy_node(
            animal,
            relation="Animal selecionado",
        ),
        father=_genealogy_node(
            father,
            relation="Pai",
            fallback_tag=father_tag,
        ),
        mother=_genealogy_node(
            mother,
            relation="Mãe",
            fallback_tag=mother_tag,
        ),
        paternal_grandfather=_genealogy_node(
            paternal_grandfather,
            relation="Avô paterno",
            fallback_tag=paternal_grandfather_tag,
        ),
        paternal_grandmother=_genealogy_node(
            paternal_grandmother,
            relation="Avó paterna",
            fallback_tag=paternal_grandmother_tag,
        ),
        maternal_grandfather=_genealogy_node(
            maternal_grandfather,
            relation="Avô materno",
            fallback_tag=maternal_grandfather_tag,
        ),
        maternal_grandmother=_genealogy_node(
            maternal_grandmother,
            relation="Avó materna",
            fallback_tag=maternal_grandmother_tag,
        ),
        siblings=[
            _genealogy_node(
                sibling,
                relation="Irmão(ã)",
            )
            for sibling in sorted(
                full_siblings,
                key=lambda item: str(
                    (item.payload or {}).get("tag", "")
                ).casefold(),
            )
        ],
        half_siblings=[
            _genealogy_node(
                sibling,
                relation="Meio-irmão(ã)",
            )
            for sibling in sorted(
                half_siblings,
                key=lambda item: str(
                    (item.payload or {}).get("tag", "")
                ).casefold(),
            )
        ],
        children=[
            _genealogy_node(
                child,
                relation="Filho(a)",
            )
            for child in sorted(
                children_entities,
                key=lambda item: str(
                    (item.payload or {}).get("tag", "")
                ).casefold(),
            )
        ],
        descendants=[
            _genealogy_node(
                descendant,
                relation=descendant_relation(generation),
            )
            for descendant, generation in descendants
        ],
        unresolved_tags=unresolved_tags,
    )


@router.get(
    "/{animal_id}/history",
    response_model=list[AnimalHistoryResponse],
)
def animal_history(
    animal_id: str,
    principal: Principal = Depends(
        require_permission("animals.read")
    ),
    db: Session = Depends(get_db),
) -> list[AnimalHistoryResponse]:
    animal = _animal_for_principal(db, principal, animal_id)

    changes = db.scalars(
        select(SyncChange)
        .where(
            SyncChange.entity_type == "animal",
            SyncChange.entity_id == animal.entity_id,
            SyncChange.company_id == principal.company.id,
            SyncChange.tenant_id == principal.company.tenant_id,
        )
        .order_by(
            SyncChange.version.desc(),
            SyncChange.changed_at.desc(),
        )
    ).all()

    return [
        AnimalHistoryResponse(
            version=change.version,
            payload=dict(change.payload or {}),
            deleted=change.deleted,
            changed_at=change.changed_at,
        )
        for change in changes
    ]


@router.get(
    "/{animal_id}/timeline",
    response_model=list[AnimalTimelineResponse],
)
def animal_timeline(
    animal_id: str,
    principal: Principal = Depends(
        require_permission("animals.read")
    ),
    db: Session = Depends(get_db),
) -> list[AnimalTimelineResponse]:
    animal = _animal_for_principal(db, principal, animal_id)

    records = db.scalars(
        select(AuditLog)
        .where(
            AuditLog.entity_type == "animal",
            AuditLog.entity_id == animal.entity_id,
            AuditLog.company_id == principal.company.id,
            AuditLog.tenant_id == principal.company.tenant_id,
        )
        .order_by(AuditLog.occurred_at.desc())
    ).all()

    def category(action: str) -> str:
        if action == "create":
            return "Cadastro"
        if action == "update":
            return "Atualizações"
        if action == "delete":
            return "Exclusão"
        return "Auditoria"

    def title(record: AuditLog) -> str:
        if record.action == "create":
            return "Animal cadastrado"
        if record.action == "update":
            return "Dados do animal atualizados"
        if record.action == "delete":
            return "Animal excluído"
        return record.description or "Evento auditado"

    return [
        AnimalTimelineResponse(
            id=record.id,
            action=record.action,
            category=category(record.action),
            title=title(record),
            description=record.description,
            before=dict(record.before or {}),
            after=dict(record.after or {}),
            user_id=record.user_id,
            occurred_at=record.occurred_at,
        )
        for record in records
    ]


@router.get("/{animal_id}", response_model=AnimalResponse)
def get_animal(
    animal_id: str,
    principal: Principal = Depends(require_permission("animals.read")),
    db: Session = Depends(get_db),
) -> AnimalResponse:
    return _response(_animal_for_principal(db, principal, animal_id))


@router.post("", response_model=AnimalResponse)
def create_animal(
    request: AnimalCreateRequest,
    principal: Principal = Depends(require_permission("animals.create")),
    db: Session = Depends(get_db),
) -> AnimalResponse:
    _farm_for_principal(db, principal, request.farm_id)

    tag = request.tag.strip()
    if not tag:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="O brinco do animal é obrigatório.",
        )

    existing = db.scalars(
        select(EntityState).where(
            EntityState.entity_type == "animal",
            EntityState.farm_id == request.farm_id,
            EntityState.company_id == principal.company.id,
            EntityState.deleted.is_(False),
        )
    ).all()
    if any(
        str((item.payload or {}).get("tag", "")).strip().lower() == tag.lower()
        for item in existing
    ):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Já existe um animal com esse brinco na fazenda.",
        )

    animal_id = new_id("animal")
    payload = request.model_dump()
    payload["tag"] = tag
    payload["active"] = True
    payload["state_version"] = 1

    entity = EntityState(
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=request.farm_id,
        entity_type="animal",
        entity_id=animal_id,
        version=1,
        payload=payload,
        deleted=False,
        updated_by=principal.user.id,
    )
    db.add(entity)
    _record_change(db, entity)
    record_audit(
        db,
        principal=principal,
        action="create",
        module="animals",
        entity_type="animal",
        entity_id=animal_id,
        description=f'Animal "{tag}" cadastrado.',
        farm_id=request.farm_id,
        after=payload,
    )
    db.commit()
    db.refresh(entity)
    return _response(entity)


@router.patch("/{animal_id}", response_model=AnimalResponse)
def update_animal(
    animal_id: str,
    request: AnimalUpdateRequest,
    principal: Principal = Depends(require_permission("animals.update")),
    db: Session = Depends(get_db),
) -> AnimalResponse:
    entity = _animal_for_principal(db, principal, animal_id)
    before = dict(entity.payload or {})
    payload = dict(before)

    changes = request.model_dump(exclude_unset=True)
    if "tag" in changes:
        tag = str(changes["tag"] or "").strip()
        if not tag:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="O brinco do animal é obrigatório.",
            )
        changes["tag"] = tag

    payload.update(changes)
    entity.version += 1
    payload["state_version"] = entity.version
    entity.payload = payload
    entity.updated_by = principal.user.id

    _record_change(db, entity)
    record_audit(
        db,
        principal=principal,
        action="update",
        module="animals",
        entity_type="animal",
        entity_id=entity.entity_id,
        description=f'Animal "{payload.get("tag", animal_id)}" atualizado.',
        farm_id=entity.farm_id,
        before=before,
        after=payload,
    )
    db.commit()
    db.refresh(entity)
    return _response(entity)


@router.delete("/{animal_id}", response_model=AnimalResponse)
def delete_animal(
    animal_id: str,
    principal: Principal = Depends(require_permission("animals.delete")),
    db: Session = Depends(get_db),
) -> AnimalResponse:
    entity = _animal_for_principal(db, principal, animal_id)
    before = dict(entity.payload or {})
    response = _response(entity)

    payload = dict(before)
    payload["active"] = False
    entity.version += 1
    payload["state_version"] = entity.version
    entity.payload = payload
    entity.deleted = True
    entity.updated_by = principal.user.id

    _record_change(db, entity)
    record_audit(
        db,
        principal=principal,
        action="delete",
        module="animals",
        entity_type="animal",
        entity_id=entity.entity_id,
        description=f'Animal "{payload.get("tag", animal_id)}" removido.',
        farm_id=entity.farm_id,
        before=before,
        after=payload,
    )
    db.commit()
    return response
