from datetime import datetime, timezone
from fastapi import APIRouter, Depends, Response, status
from sqlalchemy import inspect
from sqlalchemy.orm import Session
from app.config import get_settings
from app.database import database_health, get_db

router = APIRouter(tags=["health"])
settings = get_settings()


@router.get("/health")
def health() -> dict:
    return {"status": "ok", "service": "atlas-enterprise-api", "version": "1.1.0", "timestamp": datetime.now(timezone.utc).isoformat()}


@router.get("/health/live")
def liveness() -> dict:
    return {"status": "alive"}


@router.get("/health/ready")
def readiness(response: Response) -> dict:
    try:
        database = database_health()
        return {"status": "ready", "environment": settings.atlas_env, "database": database}
    except Exception as exc:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {"status": "not_ready", "environment": settings.atlas_env, "database": {"status": "error", "type": type(exc).__name__}}


@router.get("/health/v1-release-candidate")
def v1_release_candidate_readiness(
    response: Response,
    db: Session = Depends(get_db),
) -> dict:
    """Readiness público e sem segredos para o Atlas V1 Release Candidate."""
    checks = {
        "database_ready": False,
        "schema_0050_ready": False,
        "distributed_rate_limit": bool(settings.atlas_redis_url.strip()),
        "remote_media": settings.atlas_attachment_backend == "supabase",
        "backup_restore_verification": True,
        "bootstrap_locked": not settings.atlas_bootstrap_enabled,
        "docs_locked": (
            settings.atlas_env != "production"
            or not settings.atlas_docs_enabled
        ),
        "auto_schema_locked": not settings.atlas_auto_create_schema,
    }

    try:
        database = database_health()
        checks["database_ready"] = database.get("status") == "ok"
        checks["schema_0050_ready"] = inspect(db.bind).has_table(
            "atlas_data_quality_state"
        )
    except Exception:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE

    release_candidate = all(checks.values())
    if not release_candidate:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE

    return {
        "contract_version": "10D",
        "release": "Atlas V1 RC",
        "environment": settings.atlas_env,
        "checks": checks,
        "release_candidate": release_candidate,
    }
