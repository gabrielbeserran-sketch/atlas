
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models import (
    ComplianceAssessment,
    ComplianceControl,
    DataCatalogAsset,
    DataQualityRule,
    DataQualityRun,
    RealtimeNotification,
    ResilienceIncident,
    ServiceHealthSnapshot,
    new_id,
)


def evaluate_quality_rule(rule: DataQualityRule, sample: list[dict[str, Any]]) -> tuple[bool, dict]:
    field = rule.field_name
    parameters = rule.parameters or {}

    if rule.rule_type == "not_null":
        invalid = sum(1 for row in sample if row.get(field) in (None, ""))
        return invalid == 0, {"invalid_count": invalid}

    if rule.rule_type == "range":
        minimum = parameters.get("min")
        maximum = parameters.get("max")
        invalid = 0
        for row in sample:
            value = row.get(field)
            if value is None:
                continue
            if minimum is not None and value < minimum:
                invalid += 1
            if maximum is not None and value > maximum:
                invalid += 1
        return invalid == 0, {"invalid_count": invalid}

    if rule.rule_type == "allowed_values":
        allowed = set(parameters.get("values", []))
        invalid = sum(1 for row in sample if row.get(field) not in allowed)
        return invalid == 0, {"invalid_count": invalid}

    return False, {"error": "Tipo de regra não suportado."}


def run_quality_checks(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    asset: DataCatalogAsset,
    sample: list[dict[str, Any]],
) -> DataQualityRun:
    rules = list(
        db.scalars(
            select(DataQualityRule).where(
                DataQualityRule.company_id == company_id,
                DataQualityRule.asset_id == asset.id,
                DataQualityRule.enabled.is_(True),
            )
        ).all()
    )

    findings = []
    passed = 0

    for rule in rules:
        ok, details = evaluate_quality_rule(rule, sample)
        if ok:
            passed += 1
        else:
            findings.append(
                {
                    "rule_id": rule.id,
                    "rule_name": rule.name,
                    "severity": rule.severity,
                    "details": details,
                }
            )

    total = len(rules)
    failed = total - passed
    score = round((passed / total) * 100, 2) if total else 100.0
    asset.quality_score = score

    run = DataQualityRun(
        id=new_id("quality_run"),
        tenant_id=tenant_id,
        company_id=company_id,
        asset_id=asset.id,
        status="completed",
        score=score,
        checks_total=total,
        checks_passed=passed,
        checks_failed=failed,
        findings=findings,
    )
    db.add(run)

    if failed:
        db.add(
            RealtimeNotification(
                id=new_id("notification"),
                tenant_id=tenant_id,
                company_id=company_id,
                farm_id=None,
                user_id=None,
                channel="in_app",
                category="data_quality",
                severity="warning",
                title=f"Qualidade de dados abaixo do esperado: {asset.name}",
                message=f"{failed} regra(s) de qualidade falharam.",
                payload={"asset_id": asset.id, "run_id": run.id, "score": score},
                deduplication_key=f"quality:{asset.id}:{datetime.now(timezone.utc).date().isoformat()}",
                status="pending",
            )
        )

    db.flush()
    return run


def compliance_score(
    db: Session,
    *,
    company_id: str,
) -> dict:
    controls = list(
        db.scalars(
            select(ComplianceControl).where(
                ComplianceControl.company_id == company_id
            )
        ).all()
    )
    assessments = list(
        db.scalars(
            select(ComplianceAssessment).where(
                ComplianceAssessment.company_id == company_id
            )
        ).all()
    )

    latest_by_control: dict[str, ComplianceAssessment] = {}
    for item in sorted(assessments, key=lambda value: value.assessed_at, reverse=True):
        latest_by_control.setdefault(item.control_id, item)

    scores = [
        latest_by_control[control.id].score
        for control in controls
        if control.id in latest_by_control
    ]

    return {
        "controls": len(controls),
        "assessed_controls": len(scores),
        "average_score": round(sum(scores) / len(scores), 2) if scores else 0,
        "unassessed_controls": len(controls) - len(scores),
    }


def service_health_summary(
    db: Session,
    *,
    company_id: str,
) -> dict:
    snapshots = list(
        db.scalars(
            select(ServiceHealthSnapshot)
            .where(ServiceHealthSnapshot.company_id == company_id)
            .order_by(ServiceHealthSnapshot.checked_at.desc())
            .limit(200)
        ).all()
    )

    latest: dict[str, ServiceHealthSnapshot] = {}
    for item in snapshots:
        latest.setdefault(item.service_name, item)

    values = list(latest.values())
    return {
        "services": len(values),
        "healthy": sum(1 for item in values if item.status == "healthy"),
        "degraded": sum(1 for item in values if item.status == "degraded"),
        "down": sum(1 for item in values if item.status == "down"),
        "average_latency_ms": round(
            sum(item.latency_ms for item in values) / len(values), 2
        ) if values else 0,
        "average_availability_percent": round(
            sum(item.availability_percent for item in values) / len(values), 2
        ) if values else 0,
    }


def open_incident_for_unhealthy_service(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    snapshot: ServiceHealthSnapshot,
) -> ResilienceIncident | None:
    if snapshot.status == "healthy":
        return None

    existing = db.scalar(
        select(ResilienceIncident).where(
            ResilienceIncident.company_id == company_id,
            ResilienceIncident.status == "open",
            ResilienceIncident.affected_services.contains([snapshot.service_name]),
        )
    )
    if existing is not None:
        return existing

    incident = ResilienceIncident(
        id=new_id("resilience_incident"),
        tenant_id=tenant_id,
        company_id=company_id,
        title=f"Degradação detectada em {snapshot.service_name}",
        severity="critical" if snapshot.status == "down" else "high",
        status="open",
        affected_services=[snapshot.service_name],
        description=(
            f"Serviço em estado {snapshot.status}; "
            f"latência {snapshot.latency_ms} ms; "
            f"taxa de erro {snapshot.error_rate_percent}%."
        ),
        root_cause="",
        mitigation="Investigar logs, dependências e capacidade do serviço.",
    )
    db.add(incident)
    db.flush()
    return incident
