from __future__ import annotations

import hashlib
import hmac
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..config import get_settings
from ..models import BulletinDispatch, SecurityCameraEvent


settings = get_settings()

_STATUS_RANK = {
    "queued": 0,
    "blocked_provider": 0,
    "failed": 0,
    "provider_accepted": 1,
    "sent": 1,
    "delivered": 2,
    "read": 3,
}


def verify_signature(raw_body: bytes, signature_header: str) -> bool:
    secret = settings.atlas_whatsapp_app_secret.strip()
    if not secret or not signature_header.startswith("sha256="):
        return False
    expected = hmac.new(
        secret.encode("utf-8"),
        raw_body,
        hashlib.sha256,
    ).hexdigest()
    supplied = signature_header.removeprefix("sha256=").strip()
    return hmac.compare_digest(expected, supplied)


def apply_status_webhook(
    db: Session,
    payload: dict,
) -> dict[str, int]:
    updated = 0
    ignored = 0

    entries = payload.get("entry")
    if not isinstance(entries, list):
        return {"updated": 0, "ignored": 0}

    for entry in entries:
        if not isinstance(entry, dict):
            continue
        changes = entry.get("changes")
        if not isinstance(changes, list):
            continue

        for change in changes:
            if not isinstance(change, dict):
                continue
            value = change.get("value")
            if not isinstance(value, dict):
                continue
            statuses = value.get("statuses")
            if not isinstance(statuses, list):
                continue

            for item in statuses:
                if not isinstance(item, dict):
                    continue
                message_id = str(item.get("id") or "").strip()
                incoming = str(item.get("status") or "").strip().lower()
                if not message_id or incoming not in {
                    "sent",
                    "delivered",
                    "read",
                    "failed",
                }:
                    ignored += 1
                    continue

                dispatch = db.scalar(
                    select(BulletinDispatch).where(
                        BulletinDispatch.provider_message_id == message_id,
                    )
                )
                security_event = None
                if dispatch is None:
                    security_event = db.scalar(
                        select(SecurityCameraEvent).where(
                            SecurityCameraEvent.provider_message_id
                            == message_id,
                        )
                    )

                target = dispatch if dispatch is not None else security_event
                if target is None:
                    ignored += 1
                    continue

                status_attr = (
                    "status" if dispatch is not None else "alert_status"
                )

                if incoming == "failed":
                    setattr(target, status_attr, "failed")
                    errors = item.get("errors")
                    target.error_message = (
                        str(errors)[:2000]
                        if errors
                        else "Falha informada pela Meta."
                    )
                    updated += 1
                    continue

                normalized = (
                    "provider_accepted" if incoming == "sent" else incoming
                )
                current_status = str(getattr(target, status_attr) or "")
                current_rank = _STATUS_RANK.get(current_status, 0)
                incoming_rank = _STATUS_RANK[normalized]
                if incoming_rank >= current_rank:
                    setattr(target, status_attr, normalized)
                    if normalized in {
                        "provider_accepted",
                        "delivered",
                        "read",
                    }:
                        target.sent_at = (
                            target.sent_at or datetime.now(timezone.utc)
                        )
                    target.error_message = ""
                    updated += 1
                else:
                    ignored += 1

    if updated:
        db.commit()
    return {"updated": updated, "ignored": ignored}
