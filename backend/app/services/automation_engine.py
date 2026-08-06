
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models import (
    AutomationRule,
    CorporateCalendarEvent,
    ExecutiveDigest,
    RealtimeNotification,
    StrategicObjective,
    WorkflowDefinition,
    WorkflowInstance,
    new_id,
)


def _condition_matches(conditions: dict[str, Any], payload: dict[str, Any]) -> bool:
    for key, expected in conditions.items():
        if payload.get(key) != expected:
            return False
    return True


def execute_event_rules(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str | None,
    event_type: str,
    payload: dict[str, Any],
) -> list[str]:
    rules = list(
        db.scalars(
            select(AutomationRule).where(
                AutomationRule.company_id == company_id,
                AutomationRule.enabled.is_(True),
                AutomationRule.event_type == event_type,
            ).order_by(AutomationRule.priority.desc())
        ).all()
    )
    executed: list[str] = []
    for rule in rules:
        if not _condition_matches(rule.conditions or {}, payload):
            continue
        for action in rule.actions or []:
            if action.get("type") == "notification":
                db.add(
                    RealtimeNotification(
                        id=new_id("notification"),
                        tenant_id=tenant_id,
                        company_id=company_id,
                        farm_id=farm_id,
                        user_id=None,
                        channel="in_app",
                        category="automation",
                        severity=action.get("severity", "info"),
                        title=action.get("title", rule.name),
                        message=action.get("message", f"Regra executada: {rule.name}"),
                        payload={"rule_id": rule.id, **payload},
                        deduplication_key=f"automation:{rule.id}:{payload.get('entity_id', '')}",
                        status="pending",
                    )
                )
        rule.last_executed_at = datetime.now(timezone.utc)
        executed.append(rule.id)
    db.flush()
    return executed


def generate_executive_digest(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str | None,
    period: str,
) -> ExecutiveDigest:
    objectives = list(
        db.scalars(
            select(StrategicObjective).where(
                StrategicObjective.company_id == company_id,
                StrategicObjective.status == "active",
            )
        ).all()
    )
    events = list(
        db.scalars(
            select(CorporateCalendarEvent).where(
                CorporateCalendarEvent.company_id == company_id,
                CorporateCalendarEvent.status == "scheduled",
            )
        ).all()
    )
    instances = list(
        db.scalars(
            select(WorkflowInstance).where(
                WorkflowInstance.company_id == company_id,
                WorkflowInstance.status == "running",
            )
        ).all()
    )
    digest = ExecutiveDigest(
        id=new_id("executive_digest"),
        tenant_id=tenant_id,
        company_id=company_id,
        farm_id=farm_id,
        period=period,
        summary=(
            f"{len(objectives)} objetivo(s) ativo(s), "
            f"{len(events)} evento(s) agendado(s) e "
            f"{len(instances)} fluxo(s) em execução."
        ),
        priorities=[
            {"title": item.title, "progress_percent": item.progress_percent}
            for item in objectives[:5]
        ],
        alerts=[],
        metrics={
            "active_objectives": len(objectives),
            "scheduled_events": len(events),
            "running_workflows": len(instances),
        },
    )
    db.add(digest)
    db.flush()
    return digest
