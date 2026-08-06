
from __future__ import annotations

import asyncio
from collections import defaultdict
from datetime import datetime, timezone
from typing import Any

from fastapi import WebSocket


class RealtimeHub:
    def __init__(self) -> None:
        self._connections: dict[str, set[WebSocket]] = defaultdict(set)
        self._lock = asyncio.Lock()
        self._published = 0
        self._failed = 0

    async def connect(self, room: str, websocket: WebSocket) -> None:
        await websocket.accept()
        async with self._lock:
            self._connections[room].add(websocket)

    async def disconnect(self, room: str, websocket: WebSocket) -> None:
        async with self._lock:
            self._connections[room].discard(websocket)
            if not self._connections[room]:
                self._connections.pop(room, None)

    async def publish(self, room: str, event: dict[str, Any]) -> int:
        event = {
            **event,
            "published_at": datetime.now(timezone.utc).isoformat(),
        }
        async with self._lock:
            connections = list(self._connections.get(room, set()))

        delivered = 0
        stale: list[WebSocket] = []
        for websocket in connections:
            try:
                await websocket.send_json(event)
                delivered += 1
            except Exception:
                stale.append(websocket)
                self._failed += 1

        for websocket in stale:
            await self.disconnect(room, websocket)

        self._published += 1
        return delivered

    def metrics(self) -> dict[str, int]:
        return {
            "rooms": len(self._connections),
            "connections": sum(len(items) for items in self._connections.values()),
            "published_events": self._published,
            "failed_deliveries": self._failed,
        }


realtime_hub = RealtimeHub()
