from fastapi import APIRouter, Depends

from ..authz import require_permission
from ..dependencies import get_current_context

router = APIRouter(prefix="/iot-platform", tags=["IoT Platform"])


@router.get("/readiness")
def readiness(
    _context=Depends(get_current_context),
    _permission=Depends(require_permission("platform.read")),
) -> dict:
    return {
        "domain": "iot",
        "router": "iot_platform",
        "status": "available",
        "architecture": "domain_router",
    }
