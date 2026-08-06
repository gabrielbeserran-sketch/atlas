from contextvars import ContextVar

request_id_context: ContextVar[str] = ContextVar("request_id", default="")
tenant_id_context: ContextVar[str] = ContextVar("tenant_id", default="")
