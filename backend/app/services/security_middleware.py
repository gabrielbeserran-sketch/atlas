from __future__ import annotations

import time
from collections import defaultdict, deque
from ipaddress import ip_address, ip_network
from threading import Lock

from fastapi import Request
from fastapi.responses import JSONResponse
from redis.asyncio import Redis
from redis.exceptions import RedisError

from app.config import Settings, get_settings

settings = get_settings()


class InMemoryRateLimiter:
    """Fallback somente para development/test sem Redis."""

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


class DistributedRateLimiter:
    def __init__(
        self,
        *,
        limit: int,
        window_seconds: int,
        redis_url: str,
    ) -> None:
        self.limit = limit
        self.window_seconds = window_seconds
        self.redis_url = redis_url.strip()
        self._redis: Redis | None = (
            Redis.from_url(
                self.redis_url,
                encoding="utf-8",
                decode_responses=True,
            )
            if self.redis_url
            else None
        )
        self._local = InMemoryRateLimiter(limit, window_seconds)

    @property
    def distributed(self) -> bool:
        return self._redis is not None

    async def allow(self, key: str) -> bool:
        if self._redis is None:
            return self._local.allow(key)

        redis_key = f"atlas:rate:{key}"
        try:
            async with self._redis.pipeline(transaction=True) as pipe:
                pipe.incr(redis_key)
                pipe.expire(redis_key, self.window_seconds, nx=True)
                count, _ = await pipe.execute()
            return int(count) <= self.limit
        except RedisError:
            # Em produção não fazemos fail-open: perder o rate limiter
            # distribuído é uma degradação de segurança.
            if settings.is_production_like:
                raise
            return self._local.allow(key)


limiter = DistributedRateLimiter(
    limit=settings.atlas_rate_limit_per_minute,
    window_seconds=60,
    redis_url=settings.atlas_redis_url,
)


def _valid_ip(value: str) -> str | None:
    candidate = value.strip()
    if not candidate:
        return None
    try:
        return str(ip_address(candidate))
    except ValueError:
        return None


def _peer_is_trusted_proxy(
    remote_host: str,
    config: Settings,
) -> bool:
    valid_remote = _valid_ip(remote_host)
    if valid_remote is None:
        return False

    remote_ip = ip_address(valid_remote)
    for cidr in config.trusted_proxy_cidrs:
        try:
            if remote_ip in ip_network(cidr, strict=False):
                return True
        except ValueError:
            continue

    return False


def resolve_client_ip(
    *,
    remote_host: str,
    forwarded_for: str,
    config: Settings | None = None,
) -> str:
    active = config or settings
    direct_ip = _valid_ip(remote_host) or "unknown"

    if not active.atlas_trust_proxy_headers:
        return direct_ip

    if not _peer_is_trusted_proxy(remote_host, active):
        return direct_ip

    forwarded_client = _valid_ip(forwarded_for.split(",")[0])
    return forwarded_client or direct_ip


async def security_middleware(request: Request, call_next):
    remote_host = request.client.host if request.client else ""
    client_ip = resolve_client_ip(
        remote_host=remote_host,
        forwarded_for=request.headers.get("x-forwarded-for", ""),
    )

    key = f"{client_ip}:{request.url.path}"
    try:
        allowed = await limiter.allow(key)
    except RedisError:
        return JSONResponse(
            status_code=503,
            content={
                "detail": (
                    "Proteção de rate limit temporariamente indisponível."
                )
            },
            headers={"Retry-After": "5"},
        )

    if not allowed:
        return JSONResponse(
            status_code=429,
            content={"detail": "Limite de requisições excedido."},
            headers={"Retry-After": "60"},
        )

    response = await call_next(request)

    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = (
        "camera=(), microphone=(), geolocation=()"
    )
    response.headers["X-Permitted-Cross-Domain-Policies"] = "none"
    response.headers["Cache-Control"] = "no-store"

    if settings.is_production_like:
        response.headers["Strict-Transport-Security"] = (
            "max-age=31536000; includeSubDomains"
        )

    return response
