from sqlalchemy.orm import Session

from ..authz import Principal
from ..models import AuditLog, new_id


def record_audit(
    db: Session,
    *,
    principal: Principal,
    action: str,
    module: str,
    entity_type: str,
    entity_id: str,
    description: str,
    farm_id: str | None = None,
    before: dict | None = None,
    after: dict | None = None,
    result: str = "success",
    justification: str = "",
) -> None:
    db.add(
        AuditLog(
            id=new_id("audit"),
            tenant_id=principal.company.tenant_id,
            company_id=principal.company.id,
            farm_id=farm_id,
            user_id=principal.user.id,
            action=action,
            module=module,
            entity_type=entity_type,
            entity_id=entity_id,
            description=description,
            before=before or {},
            after=after or {},
            result=result,
            justification=justification,
        )
    )
