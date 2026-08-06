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

    processed = db.get(
        ProcessedOperation,
        request.idempotency_key,
    )
    if processed is not None:
        return SyncPushResponse(**processed.result_payload)

    state = db.scalar(
        select(EntityState).where(
            EntityState.company_id == principal.company.id,
            EntityState.entity_type == request.entity_type,
            EntityState.entity_id == request.entity_id,
        )
    )

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
                result_payload=response.model_dump(),
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
            result_payload=response.model_dump(),
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
    query = (
        select(SyncChange)
        .where(
            SyncChange.company_id == principal.company.id,
            SyncChange.tenant_id == principal.company.tenant_id,
            SyncChange.cursor > cursor,
        )
        .order_by(SyncChange.cursor.asc())
        .limit(1000)
    )
    changes = db.scalars(query).all()

    allowed = principal.membership.farm_ids or []
    if (
        principal.membership.role == "consultant"
        and allowed
    ):
        changes = [
            item
            for item in changes
            if item.farm_id is None or item.farm_id in allowed
        ]

    return [
        SyncChangeResponse(
            entity_type=item.entity_type,
            entity_id=item.entity_id,
            version=item.version,
            payload=item.payload,
            deleted=item.deleted,
            cursor=str(item.cursor),
        )
        for item in changes
    ]
