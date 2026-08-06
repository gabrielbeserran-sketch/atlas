from fastapi import APIRouter, Depends

from ..authz import require_permission
from ..dependencies import get_current_context

router = APIRouter(prefix="/machine-learning-registry", tags=["Machine Learning Registry"])


@router.get("/readiness")
def readiness(
    _context=Depends(get_current_context),
    _permission=Depends(require_permission("platform.read")),
) -> dict:
    return {
        "domain": "ml",
        "router": "machine_learning_registry",
        "status": "available",
        "architecture": "domain_router",
    }
