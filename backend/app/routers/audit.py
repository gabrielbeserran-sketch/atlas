from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..database import get_db
from ..models import AuditLog
from ..schemas import AuditResponse

router = APIRouter(prefix="/audit", tags=["audit"])


@router.get("", response_model=list[AuditResponse])
def list_audit(
    limit: int = Query(default=200, ge=1, le=1000),
    principal: Principal = Depends(
        require_permission("audit.read")
    ),
    db: Session = Depends(get_db),
) -> list[AuditResponse]:
    values = db.scalars(
        select(AuditLog)
        .where(AuditLog.company_id == principal.company.id)
        .order_by(AuditLog.occurred_at.desc())
        .limit(limit)
    ).all()

    return [
        AuditResponse(
            id=item.id,
            company_id=item.company_id,
            farm_id=item.farm_id,
            user_id=item.user_id,
            action=item.action,
            module=item.module,
            entity_type=item.entity_type,
            entity_id=item.entity_id,
            description=item.description,
            before=item.before,
            after=item.after,
            result=item.result,
            justification=item.justification,
            occurred_at=item.occurred_at,
        )
        for item in values
    ]
