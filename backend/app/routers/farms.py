from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..authz import Principal, require_farm_scope, require_permission
from ..database import get_db
from ..models import Farm, new_id
from ..schemas import FarmCreateRequest, FarmResponse, FarmUpdateRequest
from ..services.audit import record_audit

router = APIRouter(prefix="/farms", tags=["farms"])


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
        )
    )

    if farm is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Fazenda não encontrada na empresa ativa.",
        )

    require_farm_scope(principal, farm.id)
    return farm


@router.get("", response_model=list[FarmResponse])
def list_farms(
    principal: Principal = Depends(require_permission("farms.read")),
    db: Session = Depends(get_db),
) -> list[Farm]:
    query = select(Farm).where(
        Farm.company_id == principal.company.id,
        Farm.tenant_id == principal.company.tenant_id,
        Farm.active.is_(True),
    )

    farms = list(db.scalars(query).all())

    allowed = principal.membership.farm_ids or []
    if allowed:
        farms = [farm for farm in farms if farm.id in allowed]

    return farms


@router.get("/{farm_id}", response_model=FarmResponse)
def get_farm(
    farm_id: str,
    principal: Principal = Depends(require_permission("farms.read")),
    db: Session = Depends(get_db),
) -> Farm:
    return _farm_for_principal(db, principal, farm_id)


@router.post("", response_model=FarmResponse)
def create_farm(
    request: FarmCreateRequest,
    principal: Principal = Depends(require_permission("farms.create")),
    db: Session = Depends(get_db),
) -> Farm:
    farm = Farm(
        id=new_id("farm"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        name=request.name.strip(),
        city=request.city.strip(),
        state=request.state.strip().upper(),
        active=True,
    )

    db.add(farm)

    record_audit(
        db,
        principal=principal,
        action="create",
        module="farms",
        entity_type="farm",
        entity_id=farm.id,
        description=f'Fazenda "{farm.name}" criada.',
        farm_id=farm.id,
        after={
            "name": farm.name,
            "city": farm.city,
            "state": farm.state,
        },
    )

    db.commit()
    db.refresh(farm)
    return farm


@router.patch("/{farm_id}", response_model=FarmResponse)
def update_farm(
    farm_id: str,
    request: FarmUpdateRequest,
    principal: Principal = Depends(require_permission("farms.update")),
    db: Session = Depends(get_db),
) -> Farm:
    farm = _farm_for_principal(db, principal, farm_id)

    before = {
        "name": farm.name,
        "city": farm.city,
        "state": farm.state,
        "active": farm.active,
    }

    if request.name is not None:
        farm.name = request.name.strip()
    if request.city is not None:
        farm.city = request.city.strip()
    if request.state is not None:
        farm.state = request.state.strip().upper()
    if request.active is not None:
        farm.active = request.active

    record_audit(
        db,
        principal=principal,
        action="update",
        module="farms",
        entity_type="farm",
        entity_id=farm.id,
        description=f'Fazenda "{farm.name}" atualizada.',
        farm_id=farm.id,
        before=before,
        after={
            "name": farm.name,
            "city": farm.city,
            "state": farm.state,
            "active": farm.active,
        },
    )

    db.commit()
    db.refresh(farm)
    return farm


@router.delete("/{farm_id}", response_model=FarmResponse)
def delete_farm(
    farm_id: str,
    principal: Principal = Depends(require_permission("farms.update")),
    db: Session = Depends(get_db),
) -> Farm:
    farm = _farm_for_principal(db, principal, farm_id)

    before = {
        "name": farm.name,
        "city": farm.city,
        "state": farm.state,
        "active": farm.active,
    }

    farm.active = False

    record_audit(
        db,
        principal=principal,
        action="delete",
        module="farms",
        entity_type="farm",
        entity_id=farm.id,
        description=f'Fazenda "{farm.name}" desativada.',
        farm_id=farm.id,
        before=before,
        after={**before, "active": False},
    )

    db.commit()
    db.refresh(farm)
    return farm
