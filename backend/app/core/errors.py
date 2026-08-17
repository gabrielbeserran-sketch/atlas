import logging
from dataclasses import dataclass
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy.exc import IntegrityError, SQLAlchemyError

logger = logging.getLogger("atlas.errors")


@dataclass
class AtlasError(Exception):
    message: str
    code: str = "atlas_error"
    status_code: int = 400


def install_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(AtlasError)
    async def atlas_error_handler(request: Request, exc: AtlasError):
        return JSONResponse(exc.status_code, {"error": exc.code, "message": exc.message, "request_id": getattr(request.state, "request_id", "")})

    @app.exception_handler(RequestValidationError)
    async def validation_handler(request: Request, exc: RequestValidationError):
        return JSONResponse(422, {"error": "validation_error", "message": "Dados inválidos", "details": exc.errors(), "request_id": getattr(request.state, "request_id", "")})

    @app.exception_handler(IntegrityError)
    async def integrity_handler(request: Request, exc: IntegrityError):
        return JSONResponse(409, {"error": "integrity_error", "message": "Conflito de integridade", "request_id": getattr(request.state, "request_id", "")})

    @app.exception_handler(SQLAlchemyError)
    async def database_handler(request: Request, exc: SQLAlchemyError):
        return JSONResponse(503, {"error": "database_error", "message": "Banco indisponível", "request_id": getattr(request.state, "request_id", "")})


    @app.exception_handler(Exception)
    async def unhandled_handler(request: Request, exc: Exception):
        request_id = getattr(request.state, "request_id", "")
        logger.exception("Unhandled Atlas error request_id=%s", request_id, exc_info=exc)
        return JSONResponse(
            500,
            {
                "error": "internal_error",
                "message": "Erro interno do servidor.",
                "request_id": request_id,
            },
        )
