import json
import logging
import time
from collections import defaultdict
from threading import Lock

from fastapi import Request

from app.core.request_context import request_id_context

logger = logging.getLogger("atlas.enterprise")
logger.setLevel(logging.INFO)
if not logger.handlers:
    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter("%(message)s"))
    logger.addHandler(handler)


class RuntimeMetrics:
    def __init__(self) -> None:
        self.started_at = time.time()
        self.total_requests = 0
        self.total_errors = 0
        self.requests_by_path: dict[str, int] = defaultdict(int)
        self.duration_ms_total = 0.0
        self._lock = Lock()

    def record(self, path: str, status_code: int, duration_ms: float) -> None:
        with self._lock:
            self.total_requests += 1
            self.requests_by_path[path] += 1
            self.duration_ms_total += duration_ms
            if status_code >= 500:
                self.total_errors += 1

    def snapshot(self) -> dict:
        with self._lock:
            average = (
                self.duration_ms_total / self.total_requests
                if self.total_requests
                else 0.0
            )
            return {
                "uptime_seconds": int(time.time() - self.started_at),
                "requests_total": self.total_requests,
                "errors_total": self.total_errors,
                "average_duration_ms": round(average, 2),
                "requests_by_path": dict(self.requests_by_path),
            }


metrics = RuntimeMetrics()


async def observability_middleware(request: Request, call_next):
    started = time.perf_counter()
    status_code = 500
    request_id = getattr(request.state, "request_id", None) or request_id_context.get()
    try:
        response = await call_next(request)
        status_code = response.status_code
        return response
    finally:
        duration_ms = (time.perf_counter() - started) * 1000
        metrics.record(request.url.path, status_code, duration_ms)
        logger.info(
            json.dumps(
                {
                    "event": "http_request",
                    "request_id": request_id,
                    "method": request.method,
                    "path": request.url.path,
                    "status_code": status_code,
                    "duration_ms": round(duration_ms, 2),
                },
                ensure_ascii=False,
            )
        )
