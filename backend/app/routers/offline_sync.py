from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..authz import Principal, require_farm_scope, require_permission
from ..database import get_db
from ..models import EntityState, ProcessedOperation, SyncChange, new_id
from ..offline_models import OfflineDevice, OfflineDiagnostic, SyncConflict
from ..schemas import SyncPushRequest, SyncPushResponse
from ..services.audit import record_audit

router = APIRouter(prefix="/offline", tags=["offline-sync"])


class DeviceRegistration(BaseModel):
    device_key: str = Field(min_length=6, max_length=180)
    name: str = Field(default="Dispositivo", max_length=180)
    platform: str = Field(default="unknown", max_length=40)
    app_version: str = Field(default="", max_length=40)


class DiagnosticRequest(BaseModel):
    device_id: str
    queue_size: int = Field(default=0, ge=0)
    failed_operations: int = Field(default=0, ge=0)
    local_database_bytes: int = Field(default=0, ge=0)
    free_storage_bytes: int = Field(default=0, ge=0)
    clock_offset_seconds: int = 0
    payload: dict[str, Any] = Field(default_factory=dict)


class BatchPushRequest(BaseModel):
    operations: list[SyncPushRequest] = Field(min_length=1, max_length=200)
    stop_on_conflict: bool = False


class ConflictResolutionRequest(BaseModel):
    resolution: Literal["keep_local", "keep_remote", "merge"]
    merged_payload: dict[str, Any] = Field(default_factory=dict)
    note: str = Field(default="", max_length=1000)


def _process_operation(db: Session, principal: Principal, request: SyncPushRequest) -> SyncPushResponse:
    if request.company_id != principal.company.id or request.tenant_id != principal.company.tenant_id:
        return SyncPushResponse(accepted=False, conflict=False, remote_version=0, remote_payload={}, error="Escopo da operação inválido.")
    require_farm_scope(principal, request.farm_id)
    processed = db.get(ProcessedOperation, request.idempotency_key)
    if processed is not None:
        return SyncPushResponse(**processed.result_payload)
    state = db.scalar(select(EntityState).where(EntityState.company_id == principal.company.id, EntityState.entity_type == request.entity_type, EntityState.entity_id == request.entity_id))
    current_version = state.version if state else 0
    if current_version != request.base_version:
        response = SyncPushResponse(accepted=False, conflict=True, remote_version=current_version, remote_payload=state.payload if state else {}, error=f"baseVersion={request.base_version}; remoteVersion={current_version}")
        conflict = db.scalar(select(SyncConflict).where(SyncConflict.company_id == principal.company.id, SyncConflict.operation_id == request.operation_id))
        if conflict is None:
            db.add(SyncConflict(tenant_id=principal.company.tenant_id, company_id=principal.company.id, farm_id=request.farm_id, user_id=principal.user.id, device_id=request.device_id, operation_id=request.operation_id, entity_type=request.entity_type, entity_id=request.entity_id, local_version=request.base_version, remote_version=current_version, local_payload=request.payload, remote_payload=state.payload if state else {}))
        db.add(ProcessedOperation(idempotency_key=request.idempotency_key, company_id=principal.company.id, operation_id=request.operation_id, result_payload=response.model_dump()))
        return response
    next_version = current_version + 1
    deleted = request.operation_type == "delete"
    if state is None:
        state = EntityState(id=new_id("entity"), tenant_id=principal.company.tenant_id, company_id=principal.company.id, farm_id=request.farm_id, entity_type=request.entity_type, entity_id=request.entity_id, version=next_version, payload=request.payload, deleted=deleted, updated_by=principal.user.id)
        db.add(state)
    else:
        state.farm_id = request.farm_id
        state.version = next_version
        state.payload = request.payload
        state.deleted = deleted
        state.updated_by = principal.user.id
    change = SyncChange(tenant_id=principal.company.tenant_id, company_id=principal.company.id, farm_id=request.farm_id, entity_type=request.entity_type, entity_id=request.entity_id, version=next_version, payload=request.payload, deleted=deleted)
    db.add(change)
    response = SyncPushResponse(accepted=True, conflict=False, remote_version=next_version, remote_payload=request.payload, error="")
    db.add(ProcessedOperation(idempotency_key=request.idempotency_key, company_id=principal.company.id, operation_id=request.operation_id, result_payload=response.model_dump()))
    return response


@router.post("/devices/register")
def register_device(payload: DeviceRegistration, principal: Principal = Depends(require_permission("sync.manage")), db: Session = Depends(get_db)) -> dict:
    device = db.scalar(select(OfflineDevice).where(OfflineDevice.company_id == principal.company.id, OfflineDevice.device_key == payload.device_key))
    if device is None:
        device = OfflineDevice(tenant_id=principal.company.tenant_id, company_id=principal.company.id, user_id=principal.user.id, device_key=payload.device_key, name=payload.name, platform=payload.platform, app_version=payload.app_version)
        db.add(device)
    else:
        device.user_id = principal.user.id
        device.name = payload.name
        device.platform = payload.platform
        device.app_version = payload.app_version
        device.active = True
        device.last_seen_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(device)
    return {"id": device.id, "device_key": device.device_key, "active": device.active, "last_cursor": device.last_cursor}


@router.post("/push-batch")
def push_batch(payload: BatchPushRequest, principal: Principal = Depends(require_permission("sync.manage")), db: Session = Depends(get_db)) -> dict:
    results: list[dict] = []
    accepted = conflicts = rejected = 0
    for operation in payload.operations:
        result = _process_operation(db, principal, operation)
        results.append({"operation_id": operation.operation_id, **result.model_dump()})
        if result.accepted: accepted += 1
        elif result.conflict: conflicts += 1
        else: rejected += 1
        if payload.stop_on_conflict and result.conflict: break
    record_audit(db, principal=principal, action="offline_push_batch", module="sync", entity_type="sync_batch", entity_id=new_id("batch"), description="Lote offline processado.", after={"accepted": accepted, "conflicts": conflicts, "rejected": rejected})
    db.commit()
    return {"accepted": accepted, "conflicts": conflicts, "rejected": rejected, "results": results}


@router.get("/pull-page")
def pull_page(cursor: int = Query(default=0, ge=0), limit: int = Query(default=250, ge=1, le=1000), farm_id: str | None = None, principal: Principal = Depends(require_permission("sync.read")), db: Session = Depends(get_db)) -> dict:
    if farm_id is not None: require_farm_scope(principal, farm_id)
    clauses = [SyncChange.company_id == principal.company.id, SyncChange.tenant_id == principal.company.tenant_id, SyncChange.cursor > cursor]
    if farm_id is not None: clauses.append(SyncChange.farm_id == farm_id)
    changes = db.scalars(select(SyncChange).where(*clauses).order_by(SyncChange.cursor.asc()).limit(limit + 1)).all()
    has_more = len(changes) > limit
    page = changes[:limit]
    next_cursor = page[-1].cursor if page else cursor
    return {"cursor": cursor, "next_cursor": next_cursor, "has_more": has_more, "changes": [{"entity_type": item.entity_type, "entity_id": item.entity_id, "version": item.version, "payload": item.payload, "deleted": item.deleted, "cursor": item.cursor} for item in page]}


@router.get("/conflicts")
def list_conflicts(status: str = Query(default="open"), principal: Principal = Depends(require_permission("sync.read")), db: Session = Depends(get_db)) -> list[dict]:
    items = db.scalars(select(SyncConflict).where(SyncConflict.company_id == principal.company.id, SyncConflict.status == status).order_by(SyncConflict.created_at.desc())).all()
    return [{"id": item.id, "farm_id": item.farm_id, "operation_id": item.operation_id, "entity_type": item.entity_type, "entity_id": item.entity_id, "local_version": item.local_version, "remote_version": item.remote_version, "local_payload": item.local_payload, "remote_payload": item.remote_payload, "status": item.status, "created_at": item.created_at} for item in items]


@router.post("/conflicts/{conflict_id}/resolve")
def resolve_conflict(conflict_id: str, payload: ConflictResolutionRequest, principal: Principal = Depends(require_permission("sync.manage")), db: Session = Depends(get_db)) -> dict:
    conflict = db.scalar(select(SyncConflict).where(SyncConflict.id == conflict_id, SyncConflict.company_id == principal.company.id))
    if conflict is None: raise HTTPException(status_code=404, detail="Conflito não encontrado.")
    if conflict.status != "open": raise HTTPException(status_code=409, detail="Conflito já resolvido.")
    if payload.resolution == "keep_local": resolved = conflict.local_payload
    elif payload.resolution == "keep_remote": resolved = conflict.remote_payload
    else:
        if not payload.merged_payload: raise HTTPException(status_code=422, detail="merged_payload é obrigatório para merge.")
        resolved = payload.merged_payload
    state = db.scalar(select(EntityState).where(EntityState.company_id == principal.company.id, EntityState.entity_type == conflict.entity_type, EntityState.entity_id == conflict.entity_id))
    next_version = (state.version if state else conflict.remote_version) + 1
    if state is None:
        state = EntityState(id=new_id("entity"), tenant_id=principal.company.tenant_id, company_id=principal.company.id, farm_id=conflict.farm_id, entity_type=conflict.entity_type, entity_id=conflict.entity_id, version=next_version, payload=resolved, deleted=False, updated_by=principal.user.id)
        db.add(state)
    else:
        state.version = next_version; state.payload = resolved; state.deleted = False; state.updated_by = principal.user.id
    db.add(SyncChange(tenant_id=principal.company.tenant_id, company_id=principal.company.id, farm_id=conflict.farm_id, entity_type=conflict.entity_type, entity_id=conflict.entity_id, version=next_version, payload=resolved, deleted=False))
    conflict.status = "resolved"; conflict.resolution = payload.resolution; conflict.resolved_payload = resolved; conflict.resolution_note = payload.note; conflict.resolved_at = datetime.now(timezone.utc)
    record_audit(db, principal=principal, action="sync_conflict_resolved", module="sync", entity_type=conflict.entity_type, entity_id=conflict.entity_id, description="Conflito offline resolvido.", farm_id=conflict.farm_id, before=conflict.remote_payload, after=resolved, justification=payload.note)
    db.commit()
    return {"id": conflict.id, "status": conflict.status, "resolution": conflict.resolution, "version": next_version, "payload": resolved}


@router.post("/diagnostics")
def save_diagnostic(payload: DiagnosticRequest, principal: Principal = Depends(require_permission("sync.manage")), db: Session = Depends(get_db)) -> dict:
    item = OfflineDiagnostic(tenant_id=principal.company.tenant_id, company_id=principal.company.id, user_id=principal.user.id, device_id=payload.device_id, queue_size=payload.queue_size, failed_operations=payload.failed_operations, local_database_bytes=payload.local_database_bytes, free_storage_bytes=payload.free_storage_bytes, clock_offset_seconds=payload.clock_offset_seconds, payload=payload.payload)
    db.add(item); db.commit(); db.refresh(item)
    return {"id": item.id, "reported_at": item.reported_at}


@router.get("/status")
def offline_status(principal: Principal = Depends(require_permission("sync.read")), db: Session = Depends(get_db)) -> dict:
    open_conflicts = db.scalar(select(func.count()).select_from(SyncConflict).where(SyncConflict.company_id == principal.company.id, SyncConflict.status == "open")) or 0
    devices = db.scalar(select(func.count()).select_from(OfflineDevice).where(OfflineDevice.company_id == principal.company.id, OfflineDevice.active.is_(True))) or 0
    latest_cursor = db.scalar(select(func.max(SyncChange.cursor)).where(SyncChange.company_id == principal.company.id)) or 0
    return {"status": "ready", "active_devices": devices, "open_conflicts": open_conflicts, "latest_cursor": latest_cursor, "max_batch_size": 200, "max_pull_page": 1000}
