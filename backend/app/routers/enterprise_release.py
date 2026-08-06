from fastapi import APIRouter, Depends

from ..authz import require_permission
from ..dependencies import get_current_context

router = APIRouter(prefix="/enterprise-release", tags=["Enterprise Release"])


@router.get("/readiness")
def readiness(
    _context=Depends(get_current_context),
    _permission=Depends(require_permission("platform.read")),
) -> dict:
    return {
        "domain": "release-engineering",
        "router": "enterprise_release",
        "status": "available",
        "architecture": "domain_router",
    }
