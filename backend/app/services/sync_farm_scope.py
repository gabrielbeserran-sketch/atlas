from sqlalchemy import or_

from ..authz import Principal
from ..models import EntityState
from ..schemas import SyncPushRequest, SyncPushResponse


def visible_farm_clause(principal: Principal, farm_column):
    """Match the farm scope used for writes, including company-wide records."""
    allowed = principal.membership.farm_ids or []
    if not allowed:
        return None
    return or_(farm_column.is_(None), farm_column.in_(allowed))


def reject_cross_farm_state(
    state: EntityState | None,
    request: SyncPushRequest,
) -> SyncPushResponse | None:
    if state is None or state.farm_id == request.farm_id:
        return None
    return SyncPushResponse(
        accepted=False,
        conflict=False,
        remote_version=0,
        remote_payload={},
        error="Entidade vinculada a outra fazenda.",
    )
