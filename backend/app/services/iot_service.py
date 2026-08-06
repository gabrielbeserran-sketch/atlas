
from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models import (
    IotAutomationRule,
    IotDevice,
    IotTelemetry,
    RealtimeNotification,
    new_id,
)


def rule_matches(rule: IotAutomationRule, value: float) -> bool:
    return {
        "gt": value > rule.threshold,
        "gte": value >= rule.threshold,
        "lt": value < rule.threshold,
        "lte": value <= rule.threshold,
        "eq": value == rule.threshold,
    }.get(rule.operator, False)


def apply_rules(
    db: Session,
    *,
    telemetry: IotTelemetry,
    device: IotDevice,
) -> list[RealtimeNotification]:
    rules = list(
        db.scalars(
            select(IotAutomationRule).where(
                IotAutomationRule.company_id == telemetry.company_id,
                IotAutomationRule.farm_id == telemetry.farm_id,
                IotAutomationRule.metric_key == telemetry.metric_key,
                IotAutomationRule.enabled.is_(True),
            )
        ).all()
    )

    notifications: list[RealtimeNotification] = []

    for rule in rules:
        if not rule_matches(rule, telemetry.value):
            continue

        deduplication_key = (
            f"iot:{device.id}:{telemetry.metric_key}:{rule.id}:"
            f"{telemetry.recorded_at.date().isoformat()}"
        )

        existing = db.scalar(
            select(RealtimeNotification).where(
                RealtimeNotification.company_id == telemetry.company_id,
                RealtimeNotification.deduplication_key == deduplication_key,
                RealtimeNotification.status.in_(["pending", "delivered"]),
            )
        )
        if existing is not None:
            continue

        notification = RealtimeNotification(
            id=new_id("notification"),
            tenant_id=telemetry.tenant_id,
            company_id=telemetry.company_id,
            farm_id=telemetry.farm_id,
            user_id=None,
            channel="in_app",
            category="iot",
            severity=rule.severity,
            title=rule.name,
            message=(
                f"{device.name}: {telemetry.metric_key} = "
                f"{telemetry.value} {telemetry.unit}."
            ),
            payload={
                "device_id": device.id,
                "device_external_id": device.external_id,
                "telemetry_id": telemetry.id,
                "metric_key": telemetry.metric_key,
                "value": telemetry.value,
                "unit": telemetry.unit,
                "rule_id": rule.id,
                **rule.action_payload,
            },
            deduplication_key=deduplication_key,
            status="pending",
        )
        db.add(notification)
        notifications.append(notification)

    db.flush()
    return notifications
