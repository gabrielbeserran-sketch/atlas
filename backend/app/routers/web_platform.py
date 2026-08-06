from fastapi import APIRouter, Depends

from ..authz import require_permission
from ..dependencies import get_current_context

router = APIRouter(prefix="/web-platform", tags=["Web Platform"])


@router.get("/readiness")
def readiness(
    _context=Depends(get_current_context),
    _permission=Depends(require_permission("platform.read")),
) -> dict:
    return {
        "domain": "platform",
        "router": "web_platform",
        "status": "available",
        "architecture": "domain_router",
    }
