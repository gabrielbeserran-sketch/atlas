
from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models import (
    ChangeApproval,
    DeploymentEnvironment,
    DeploymentRelease,
    ProductionReadinessCheck,
    ReleaseBuild,
    ReleaseMetricSnapshot,
    new_id,
)


def readiness_summary(
    db: Session,
    *,
    company_id: str,
    release_id: str | None,
) -> dict:
    query = select(ProductionReadinessCheck).where(
        ProductionReadinessCheck.company_id == company_id
    )
    if release_id:
        query = query.where(ProductionReadinessCheck.release_id == release_id)

    checks = list(db.scalars(query).all())
    required = [item for item in checks if item.required]
    passed = [item for item in required if item.status in {"passed", "waived"}]
    blockers = [item for item in required if item.status == "failed"]

    return {
        "checks_total": len(checks),
        "required_checks": len(required),
        "required_passed": len(passed),
        "blockers": len(blockers),
        "ready": len(required) > 0 and len(passed) == len(required),
    }


def deployment_dashboard(
    db: Session,
    *,
    company_id: str,
) -> dict:
    releases = list(
        db.scalars(
            select(DeploymentRelease)
            .where(DeploymentRelease.company_id == company_id)
            .order_by(DeploymentRelease.created_at.desc())
            .limit(200)
        ).all()
    )
    builds = list(
        db.scalars(
            select(ReleaseBuild)
            .where(ReleaseBuild.company_id == company_id)
            .order_by(ReleaseBuild.created_at.desc())
            .limit(200)
        ).all()
    )
    approvals = list(
        db.scalars(
            select(ChangeApproval).where(
                ChangeApproval.company_id == company_id
            )
        ).all()
    )

    return {
        "builds": len(builds),
        "successful_builds": sum(1 for item in builds if item.status == "completed"),
        "failed_builds": sum(1 for item in builds if item.status == "failed"),
        "deployments": len(releases),
        "successful_deployments": sum(
            1 for item in releases if item.status == "completed"
        ),
        "failed_deployments": sum(
            1 for item in releases if item.status in {"failed", "rolled_back"}
        ),
        "pending_approvals": sum(
            1 for item in approvals if item.status == "pending"
        ),
    }


def generate_release_metrics(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    environment_id: str | None,
) -> ReleaseMetricSnapshot:
    query = select(DeploymentRelease).where(
        DeploymentRelease.company_id == company_id
    )
    if environment_id:
        query = query.where(DeploymentRelease.environment_id == environment_id)

    releases = list(db.scalars(query).all())
    completed = [item for item in releases if item.status == "completed"]
    failed = [
        item for item in releases
        if item.status in {"failed", "rolled_back"}
    ]

    total = len(releases)
    failure_rate = (len(failed) / total * 100) if total else 0.0

    lead_times = []
    for item in releases:
        build = db.get(ReleaseBuild, item.build_id)
        if (
            build is not None
            and build.created_at is not None
            and item.completed_at is not None
        ):
            start = build.created_at
            end = item.completed_at
            if start.tzinfo is None:
                start = start.replace(tzinfo=timezone.utc)
            if end.tzinfo is None:
                end = end.replace(tzinfo=timezone.utc)
            lead_times.append((end - start).total_seconds() / 3600)

    metric = ReleaseMetricSnapshot(
        id=new_id("release_metric"),
        tenant_id=tenant_id,
        company_id=company_id,
        environment_id=environment_id,
        deployment_frequency=float(len(completed)),
        lead_time_hours=round(
            sum(lead_times) / len(lead_times), 2
        ) if lead_times else 0,
        change_failure_rate_percent=round(failure_rate, 2),
        mean_time_to_recovery_minutes=0,
        successful_deployments=len(completed),
        failed_deployments=len(failed),
    )
    db.add(metric)
    db.flush()
    return metric
