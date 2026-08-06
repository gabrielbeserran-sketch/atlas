
from __future__ import annotations

from sqlalchemy.orm import Session

from ..models import SecurityEvent, new_id


def record_security_event(
    db: Session,
    *,
    event_type: str,
    success: bool,
    user_id: str | None = None,
    company_id: str | None = None,
    ip_address: str = "",
    user_agent: str = "",
    details: dict | None = None,
) -> None:
    db.add(
        SecurityEvent(
            id=new_id("security_event"),
            user_id=user_id,
            company_id=company_id,
            event_type=event_type,
            success=success,
            ip_address=ip_address,
            user_agent=user_agent,
            details=details or {},
        )
    )
