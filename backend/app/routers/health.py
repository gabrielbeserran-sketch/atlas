from datetime import datetime, timezone
from fastapi import APIRouter, Depends, Response, status
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
