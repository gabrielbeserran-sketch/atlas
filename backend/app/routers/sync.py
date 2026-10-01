from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..authz import Principal, require_farm_scope, require_permission
from ..database import get_db
from ..models import (
    EntityState,
    ProcessedOperation,
    SyncChange,
    new_id,
)
from ..schemas import (
    SyncChangeResponse,
    SyncPushRequest,
    SyncPushResponse,
)
from ..services.audit import record_audit
from ..services.sync_dairy_contract import validate_dairy_push
from ..services.sync_farm_scope import reject_cross_farm_state, visible_farm_clause
from ..services.sync_idempotency import replay_processed_operation, stored_result
from ..services.sync_transaction_lock import lock_sync_requests

router = APIRouter(prefix="/sync", tags=["sync"])


@router.post("/push", response_model=SyncPushResponse)
def push(
    request: SyncPushRequest,
    principal: Principal = Depends(
        require_permission("sync.manage")
    ),
    db: Session = Depends(get_db),
) -> SyncPushResponse:
    if request.company_id != principal.company.id:
        return SyncPushResponse(
            accepted=False,
            conflict=False,
            remote_version=0,
            remote_payload={},
            error="company_id fora da sessão autenticada.",
        )

    if request.tenant_id != principal.company.tenant_id:
        return SyncPushResponse(
            accepted=False,
            conflict=False,
            remote_version=0,
            remote_payload={},
            error="tenant_id fora da sessão autenticada.",
        )

    require_farm_scope(principal, request.farm_id)

    dairy_error = validate_dairy_push(request)
    if dairy_error is not None:
        return SyncPushResponse(
            accepted=False, conflict=False, remote_version=0,
            remote_payload={}, error=dairy_error,
        )

    lock_sync_requests(db, [request])

    processed = db.get(
        ProcessedOperation,
        request.idempotency_key,
    )
    state = db.scalar(
        select(EntityState).where(
            EntityState.company_id == principal.company.id,
            EntityState.entity_type == request.entity_type,
            EntityState.entity_id == request.entity_id,
        )
    )
    cross_farm = reject_cross_farm_state(state, request)
    if cross_farm is not None:
        return cross_farm
    replay = replay_processed_operation(processed, request, state)
    if replay is not None:
        return replay

    current_version = state.version if state else 0

    if current_version != request.base_version:
        response = SyncPushResponse(
            accepted=False,
            conflict=True,
            remote_version=current_version,
            remote_payload=state.payload if state else {},
            error=(
                f"baseVersion={request.base_version}; "
                f"remoteVersion={current_version}"
            ),
        )
        db.add(
            ProcessedOperation(
                idempotency_key=request.idempotency_key,
                company_id=principal.company.id,
                operation_id=request.operation_id,
                result_payload=stored_result(request, response),
            )
        )
        record_audit(
            db,
            principal=principal,
            action="sync_conflict",
            module="sync",
            entity_type=request.entity_type,
            entity_id=request.entity_id,
            description="Conflito de versão detectado no servidor.",
            farm_id=request.farm_id,
            before=state.payload if state else {},
            after=request.payload,
            result="conflict",
        )
        db.commit()
        return response

    next_version = current_version + 1
    deleted = request.operation_type == "delete"

    if state is None:
        state = EntityState(
            id=new_id("entity"),
            tenant_id=principal.company.tenant_id,
            company_id=principal.company.id,
            farm_id=request.farm_id,
            entity_type=request.entity_type,
            entity_id=request.entity_id,
            version=next_version,
            payload=request.payload,
            deleted=deleted,
            updated_by=principal.user.id,
        )
        db.add(state)
    else:
        state.farm_id = request.farm_id
        state.version = next_version
        state.payload = request.payload
        state.deleted = deleted
        state.updated_by = principal.user.id

    change = SyncChange(
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=request.farm_id,
        entity_type=request.entity_type,
        entity_id=request.entity_id,
        version=next_version,
        payload=request.payload,
        deleted=deleted,
    )
    db.add(change)
    db.flush()

    response = SyncPushResponse(
        accepted=True,
        conflict=False,
        remote_version=next_version,
        remote_payload=request.payload,
        error="",
    )

    db.add(
        ProcessedOperation(
            idempotency_key=request.idempotency_key,
            company_id=principal.company.id,
            operation_id=request.operation_id,
            result_payload=stored_result(request, response),
        )
    )

    record_audit(
        db,
        principal=principal,
        action="sync_push",
        module="sync",
        entity_type=request.entity_type,
        entity_id=request.entity_id,
        description="Alteração sincronizada no servidor.",
        farm_id=request.farm_id,
        before={},
        after=request.payload,
    )

    db.commit()
    return response


@router.get("/pull", response_model=list[SyncChangeResponse])
def pull(
    cursor: int = Query(default=0, ge=0),
    principal: Principal = Depends(
        require_permission("sync.read")
    ),
    db: Session = Depends(get_db),
) -> list[SyncChangeResponse]:
    clauses = [
        SyncChange.company_id == principal.company.id,
        SyncChange.tenant_id == principal.company.tenant_id,
        SyncChange.cursor > cursor,
    ]
    farm_clause = visible_farm_clause(principal, SyncChange.farm_id)
    if farm_clause is not None:
        clauses.append(farm_clause)
    query = (
        select(SyncChange)
        .where(*clauses)
        .order_by(SyncChange.cursor.asc())
        .limit(1000)
    )
    changes = db.scalars(query).all()

    return [
        SyncChangeResponse(
            tenant_id=item.tenant_id,
            farm_id=item.farm_id,
            entity_type=item.entity_type,
            entity_id=item.entity_id,
            version=item.version,
            payload=item.payload,
            deleted=item.deleted,
            cursor=str(item.cursor),
        )
        for item in changes
    ]
