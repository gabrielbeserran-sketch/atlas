from datetime import datetime, timezone

from fastapi import APIRouter, Depends

from ..authz import Principal, require_permission
from ..schemas import BackupResponse
from ..services.audit import record_audit
from ..services.backup import BackupService
from ..database import get_db
from sqlalchemy.orm import Session

router = APIRouter(prefix="/backups", tags=["backups"])
service = BackupService()


def _response(path) -> BackupResponse:
    return BackupResponse(
        filename=path.name,
        created_at=datetime.fromtimestamp(
            path.stat().st_mtime,
            tz=timezone.utc,
        ),
        size_bytes=path.stat().st_size,
        engine="postgresql"
        if path.suffix == ".dump"
        else "sqlite",
    )


@router.get("", response_model=list[BackupResponse])
def list_backups(
    principal: Principal = Depends(
        require_permission("backup.read")
    ),
) -> list[BackupResponse]:
    return [_response(path) for path in service.list_backups()]


@router.post("/run", response_model=BackupResponse)
def run_backup(
    principal: Principal = Depends(
        require_permission("backup.run")
    ),
    db: Session = Depends(get_db),
) -> BackupResponse:
    path = service.run()
    record_audit(
        db,
        principal=principal,
        action="backup_run",
        module="backup",
        entity_type="database",
        entity_id=path.name,
        description="Backup automático/manual executado.",
        after={
            "filename": path.name,
            "size_bytes": path.stat().st_size,
        },
    )
    db.commit()
    return _response(path)
