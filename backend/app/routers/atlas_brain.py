from fastapi import APIRouter, Depends

from ..authz import require_permission
from ..dependencies import get_current_context

router = APIRouter(prefix="/atlas-brain", tags=["Atlas Brain"])


@router.get("/readiness")
def readiness(
    _context=Depends(get_current_context),
    _permission=Depends(require_permission("platform.read")),
) -> dict:
    return {
        "domain": "platform",
        "router": "atlas_brain",
        "status": "available",
        "architecture": "domain_router",
    }
