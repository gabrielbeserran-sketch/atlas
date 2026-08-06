from datetime import datetime, timezone
from fastapi import APIRouter, Response, status
from sqlalchemy import inspect

from app.config import get_settings
from app.core.constants import SERVICE_NAME, SERVICE_VERSION
from app.database import Base, database_health, engine
from app.services.observability import metrics

router = APIRouter(prefix="/quality", tags=["quality"])
settings = get_settings()


@router.get("/version")
def version() -> dict:
    return {
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
        "environment": settings.atlas_env,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/diagnostics")
def diagnostics() -> dict:
    inspector = inspect(engine)
    database_tables = set(inspector.get_table_names())
    metadata_tables = set(Base.metadata.tables)
    return {
        "database": database_health(),
        "metrics": metrics.snapshot(),
        "schema": {
            "metadata_tables": len(metadata_tables),
            "database_tables": len(database_tables),
            "missing_in_database": sorted(metadata_tables - database_tables),
            "unexpected_in_database": sorted(database_tables - metadata_tables),
        },
    }


@router.get("/ready")
def quality_readiness(response: Response) -> dict:
    try:
        payload = diagnostics()
        missing = payload["schema"]["missing_in_database"]
        ready = not missing
        if not ready:
            response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {"status": "ready" if ready else "not_ready", **payload}
    except Exception as exc:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {
            "status": "not_ready",
            "error": type(exc).__name__,
            "environment": settings.atlas_env,
        }
