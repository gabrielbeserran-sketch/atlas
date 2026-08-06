import time
from collections import defaultdict, deque
from threading import Lock

from fastapi import Request
from fastapi.responses import JSONResponse

from app.config import get_settings

settings = get_settings()


class InMemoryRateLimiter:
    def __init__(self, limit: int, window_seconds: int) -> None:
        self.limit = limit
        self.window_seconds = window_seconds
        self._events: dict[str, deque[float]] = defaultdict(deque)
        self._lock = Lock()

    def allow(self, key: str) -> bool:
        now = time.time()
        cutoff = now - self.window_seconds
        with self._lock:
            events = self._events[key]
            while events and events[0] < cutoff:
                events.popleft()
            if len(events) >= self.limit:
                return False
            events.append(now)
            return True


limiter = InMemoryRateLimiter(
    limit=settings.atlas_rate_limit_per_minute,
    window_seconds=60,
)


async def security_middleware(request: Request, call_next):
    forwarded = request.headers.get("x-forwarded-for", "")
    client_ip = (
        forwarded.split(",")[0].strip()
        if forwarded
        else (request.client.host if request.client else "unknown")
    )
    key = f"{client_ip}:{request.url.path}"
    if not limiter.allow(key):
        return JSONResponse(
            status_code=429,
            content={"detail": "Limite de requisições excedido."},
            headers={"Retry-After": "60"},
        )

    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
    response.headers["Cache-Control"] = "no-store"
    if settings.is_production_like:
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    return response
