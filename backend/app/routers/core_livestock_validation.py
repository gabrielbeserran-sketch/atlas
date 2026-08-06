from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..database import get_db
from ..services.core_livestock_validation import ValidationContext, validate_all

router = APIRouter(prefix="/core-validation", tags=["core-validation"])


@router.get("/farms/{farm_id}")
def validate_farm_core(
    farm_id: str,
    principal: Principal = Depends(require_permission("platform.read")),
    db: Session = Depends(get_db),
) -> dict:
    if principal.membership.role not in {"owner", "admin"}:
        allowed = set(principal.membership.farm_ids or [])
        if farm_id not in allowed:
            raise HTTPException(status_code=403, detail="Fazenda não autorizada.")
    return validate_all(
        db,
        ValidationContext(company_id=principal.company.id, farm_id=farm_id),
    )
