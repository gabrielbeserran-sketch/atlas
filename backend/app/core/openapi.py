from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi


def install_openapi(app: FastAPI) -> None:
    def custom_openapi():
        if app.openapi_schema: return app.openapi_schema
        schema = get_openapi(title=app.title, version=app.version, description=app.description, routes=app.routes)
        schema.setdefault("components", {}).setdefault("securitySchemes", {})["BearerAuth"] = {
            "type": "http", "scheme": "bearer", "bearerFormat": "JWT"
        }
        for path in schema.get("paths", {}).values():
            for operation in path.values():
                if isinstance(operation, dict) and operation.get("tags") not in (["health"],):
                    operation.setdefault("security", [{"BearerAuth": []}])
        schema["info"]["contact"] = {"name": "Projeto Atlas"}
        schema["info"]["x-api-prefix"] = "/api/v1"
        app.openapi_schema = schema
        return schema
    app.openapi = custom_openapi
