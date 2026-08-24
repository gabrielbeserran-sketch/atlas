from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from ..authz import Principal, require_farm_scope, require_permission
from ..database import get_db
from ..models import ConsultancyContact, Farm, new_id


router = APIRouter(prefix="/consultancy", tags=["consultancy"])


class ConsultancyContactUpdateRequest(BaseModel):
    display_name: str = Field(min_length=2, max_length=180)
    role: str = Field(
        default="Veterinário responsável",
        min_length=2,
        max_length=120,
    )
    whatsapp_number: str = Field(min_length=10, max_length=30)
    company_label: str = Field(min_length=2, max_length=180)
    active: bool = True


def _farm_for_principal(
    db: Session,
    principal: Principal,
    farm_id: str,
) -> Farm:
    require_farm_scope(principal, farm_id)
    farm = db.get(Farm, farm_id)
    if farm is None or farm.company_id != principal.company.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Fazenda não encontrada.",
        )
    return farm


def _digits(value: str) -> str:
    return "".join(ch for ch in value if ch.isdigit())


def _payload(
    contact: ConsultancyContact | None,
    *,
    farm_id: str,
) -> dict:
    if contact is None:
        return {
            "farm_id": farm_id,
            "configured": False,
            "active": False,
            "display_name": "",
            "role": "Veterinário responsável",
            "whatsapp_number": "",
            "company_label": "",
        }
    return {
        "farm_id": farm_id,
        "configured": bool(
            contact.active
            and contact.display_name.strip()
            and 10 <= len(_digits(contact.whatsapp_number)) <= 15
        ),
        "active": contact.active,
        "display_name": contact.display_name,
        "role": contact.role,
        "whatsapp_number": contact.whatsapp_number,
        "company_label": contact.company_label,
    }


@router.get("/deployment-readiness")
def deployment_readiness(
    db: Session = Depends(get_db),
) -> dict:
    try:
        db.scalar(select(func.count(ConsultancyContact.id)))
    except SQLAlchemyError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Schema do contato da consultoria ainda não está disponível.",
        ) from exc

    return {
        "status": "ready",
        "schema_ready": True,
        "farm_scoped": True,
        "hardcoded_flutter_contact": False,
    }


@router.get("/contact")
def get_contact(
    farm_id: str = Query(min_length=1),
    principal: Principal = Depends(require_permission("farms.read")),
    db: Session = Depends(get_db),
) -> dict:
    _farm_for_principal(db, principal, farm_id)
    contact = db.scalar(
        select(ConsultancyContact).where(
            ConsultancyContact.company_id == principal.company.id,
            ConsultancyContact.farm_id == farm_id,
        )
    )
    return _payload(contact, farm_id=farm_id)


@router.patch("/contact")
def update_contact(
    request: ConsultancyContactUpdateRequest,
    farm_id: str = Query(min_length=1),
    principal: Principal = Depends(require_permission("farms.update")),
    db: Session = Depends(get_db),
) -> dict:
    farm = _farm_for_principal(db, principal, farm_id)
    whatsapp = _digits(request.whatsapp_number)
    if not 10 <= len(whatsapp) <= 15:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="WhatsApp do veterinário responsável inválido.",
        )

    contact = db.scalar(
        select(ConsultancyContact).where(
            ConsultancyContact.company_id == principal.company.id,
            ConsultancyContact.farm_id == farm_id,
        )
    )
    if contact is None:
        contact = ConsultancyContact(
            id=new_id("consultancy_contact"),
            tenant_id=farm.tenant_id,
            company_id=principal.company.id,
            farm_id=farm.id,
        )

    contact.display_name = request.display_name.strip()
    contact.role = request.role.strip()
    contact.whatsapp_number = whatsapp
    contact.company_label = request.company_label.strip()
    contact.active = request.active
    contact.updated_by = principal.user.id

    db.add(contact)
    db.commit()
    db.refresh(contact)
    return _payload(contact, farm_id=farm_id)
