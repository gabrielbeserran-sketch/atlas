
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from threading import Lock


@dataclass(frozen=True)
class OutboxMessage:
    to: str
    subject: str
    body: str
    created_at: datetime


class InMemoryMailer:
    """Development/test mailer. Replace with a provider in staging/production."""

    def __init__(self) -> None:
        self._messages: list[OutboxMessage] = []
        self._lock = Lock()

    def send(self, *, to: str, subject: str, body: str) -> None:
        with self._lock:
            self._messages.append(
                OutboxMessage(
                    to=to,
                    subject=subject,
                    body=body,
                    created_at=datetime.now(timezone.utc),
                )
            )

    def latest_for(self, email: str) -> OutboxMessage | None:
        with self._lock:
            for message in reversed(self._messages):
                if message.to == email:
                    return message
        return None

    def clear(self) -> None:
        with self._lock:
            self._messages.clear()


mailer = InMemoryMailer()
