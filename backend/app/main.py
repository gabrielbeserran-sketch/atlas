from contextlib import asynccontextmanager
import asyncio
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .bootstrap import bootstrap
from .config import get_settings
from .core.constants import API_PREFIX, SERVICE_NAME, SERVICE_VERSION
from .core.errors import install_exception_handlers
from .core.middleware import request_context_middleware
from .core.openapi import install_openapi
from .database import (
    Base, SessionLocal, engine, database_health,
    ensure_development_schema_compatibility,
)
from .routers import (
    release_engineering,
    security_enterprise,
    integrations,
    governance,
    automation,
    ai,
    analytics,
    animals,
    atlas_ai_enterprise,
    audit,
    auth,
    backups,
    commercial,
    companies,
    farms,
    health,
    iot,
    livestock,
    members,
    ml,
    operations,
    realtime,
    sync,
    system,
    platform,
    advanced,
    business,
    atlas_brain,
    atlas_vision,
    iot_platform,
    cloud_operations,
    web_platform,
    billing,
    public_api,
    enterprise_analytics,
    machine_learning_registry,
    enterprise_release,
    precision_livestock,
    reproduction_advanced,
    health_intelligence,
    nutrition_intelligence,
    farm_operations,
    innovation_platform,
    enterprise_product,
    finance_enterprise,
    inventory_enterprise,
    ecosystem,
    corporate_intelligence,
    global_platform,
    quality,
    core_livestock_validation,
    offline_sync,
    ai_operational,
    precision_hub,
    enterprise_operations,
    saas_growth,
    data_platform,
    security_compliance,
    release_growth,
    animal_media,
    bulletins,
    security_camera,
)
from .services.observability import observability_middleware
from .services.security_middleware import security_middleware
from .services.bulletin_scheduler import bulletin_scheduler_loop

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    database_health()
    if settings.atlas_auto_create_schema and settings.atlas_env in {"development", "test"}:
        Base.metadata.create_all(bind=engine)
        ensure_development_schema_compatibility()
    if settings.atlas_bootstrap_enabled and settings.atlas_env in {"development", "test"}:
        with SessionLocal() as db:
            bootstrap(db)

    bulletin_task = None
    if settings.atlas_bulletin_scheduler_enabled:
        bulletin_task = asyncio.create_task(bulletin_scheduler_loop())

    try:
        yield
    finally:
        if bulletin_task is not None:
            bulletin_task.cancel()
            try:
                await bulletin_task
            except asyncio.CancelledError:
                pass
        engine.dispose()


app = FastAPI(
    title=SERVICE_NAME,
    version=SERVICE_VERSION,
    description="API multiempresa do Projeto Atlas com JWT, RBAC, isolamento por tenant, sincronização, auditoria e diagnósticos operacionais.",
    lifespan=lifespan,
    docs_url="/docs" if settings.atlas_docs_enabled else None,
    redoc_url="/redoc" if settings.atlas_docs_enabled else None,
    openapi_url="/openapi.json" if settings.atlas_docs_enabled else None,
)
app.middleware("http")(request_context_middleware)
app.middleware("http")(security_middleware)
app.middleware("http")(observability_middleware)
app.add_middleware(CORSMiddleware, allow_origins=settings.cors_origins, allow_credentials=True, allow_methods=["*"], allow_headers=["*"])
install_exception_handlers(app)
install_openapi(app)

for router in (
    health.router,
    auth.router,
    companies.router,
    members.router,
    farms.router,
    animals.router,
    livestock.router,
    operations.router,
    analytics.router,
    ai.router,
    realtime.router,
    iot.router,
    commercial.router,
    ml.router,
    atlas_ai_enterprise.router,
    automation.router,
    governance.router,
    integrations.router,
    security_enterprise.router,
    release_engineering.router,
    sync.router,
    audit.router,
    backups.router,
    system.router,
    platform.router,
    advanced.router,
    business.router,
    atlas_brain.router,
    atlas_vision.router,
    iot_platform.router,
    cloud_operations.router,
    web_platform.router,
    billing.router,
    public_api.router,
    enterprise_analytics.router,
    machine_learning_registry.router,
    enterprise_release.router,
    precision_livestock.router,
    reproduction_advanced.router,
    health_intelligence.router,
    nutrition_intelligence.router,
    farm_operations.router,
    innovation_platform.router,
    enterprise_product.router,
    finance_enterprise.router,
    inventory_enterprise.router,
    ecosystem.router,
    corporate_intelligence.router,
    global_platform.router,
    quality.router,
    core_livestock_validation.router,
    offline_sync.router,
    ai_operational.router,
    precision_hub.router,
    enterprise_operations.router,
    saas_growth.router,
    data_platform.router,
    security_compliance.router,
    release_growth.router,
    animal_media.router,
    bulletins.router,
    security_camera.router,
):
    app.include_router(router, prefix=API_PREFIX)



@app.get("/", tags=["health"])
def root() -> dict:
    payload = {
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
        "health": f"{API_PREFIX}/health",
        "readiness": f"{API_PREFIX}/health/ready",
    }

    if not settings.is_production_like:
        payload["environment"] = settings.atlas_env

    if settings.atlas_docs_enabled:
        payload["docs"] = "/docs"

    return payload
