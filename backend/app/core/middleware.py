from uuid import uuid4
from fastapi import Request
from app.core.request_context import request_id_context


async def request_context_middleware(request: Request, call_next):
    request_id = request.headers.get("x-request-id") or uuid4().hex
    token = request_id_context.set(request_id)
    request.state.request_id = request_id
    try:
        response = await call_next(request)
        response.headers["x-request-id"] = request_id
        return response
    finally:
        request_id_context.reset(token)
