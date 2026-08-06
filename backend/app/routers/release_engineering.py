
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..database import get_db
from ..models import (
    ChangeApproval,
    DeploymentEnvironment,
    DeploymentRelease,
    FeatureFlag,
    ProductionReadinessCheck,
    ReleaseBuild,
    ReleaseMetricSnapshot,
    ReleasePipeline,
    new_id,
)
from ..schemas import (
    ChangeApprovalCreateRequest,
    DeploymentEnvironmentCreateRequest,
    DeploymentReleaseCreateRequest,
    FeatureFlagCreateRequest,
    ReadinessCheckCompleteRequest,
    ReadinessCheckCreateRequest,
    ReleaseBuildCreateRequest,
    ReleasePipelineCreateRequest,
)
from ..services.release_engineering_service import (
    deployment_dashboard,
    generate_release_metrics,
    readiness_summary,
)

router = APIRouter(prefix="/release-engineering", tags=["release-engineering"])


@router.post("/pipelines", status_code=201)
def create_pipeline(
    payload: ReleasePipelineCreateRequest,
    principal: Principal = Depends(require_permission("release.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = ReleasePipeline(
        id=new_id("release_pipeline"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Código de pipeline duplicado.") from exc
    return {"id": item.id}


@router.get("/pipelines")
def pipelines(
    principal: Principal = Depends(require_permission("release.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    items = db.scalars(
        select(ReleasePipeline)
        .where(ReleasePipeline.company_id == principal.company.id)
        .order_by(ReleasePipeline.name)
    ).all()
    return [
        {
            "id": item.id,
            "code": item.code,
            "name": item.name,
            "stages": item.stages,
            "active": item.active,
        }
        for item in items
    ]


@router.post("/builds", status_code=201)
def create_build(
    payload: ReleaseBuildCreateRequest,
    principal: Principal = Depends(require_permission("release.execute")),
    db: Session = Depends(get_db),
) -> dict:
    pipeline = db.get(ReleasePipeline, payload.pipeline_id)
    if pipeline is None or pipeline.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Pipeline não encontrado.")

    item = ReleaseBuild(
        id=new_id("release_build"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        pipeline_id=pipeline.id,
        version=payload.version,
        commit_sha=payload.commit_sha,
        branch=payload.branch,
        status="queued",
        artifacts=[],
        test_summary={},
        created_by=principal.user.id,
    )
    db.add(item)
    db.commit()
    return {"id": item.id, "status": item.status}


@router.patch("/builds/{build_id}/complete")
def complete_build(
    build_id: str,
    status: str,
    artifacts: list[dict] | None = None,
    test_summary: dict | None = None,
    principal: Principal = Depends(require_permission("release.execute")),
    db: Session = Depends(get_db),
) -> dict:
    if status not in {"completed", "failed"}:
        raise HTTPException(status_code=422, detail="Status inválido.")

    item = db.get(ReleaseBuild, build_id)
    if item is None or item.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Build não encontrado.")

    item.status = status
    item.artifacts = artifacts or []
    item.test_summary = test_summary or {}
    item.completed_at = datetime.now(timezone.utc)
    if item.started_at is None:
        item.started_at = item.created_at
    db.commit()
    return {"id": item.id, "status": item.status}


@router.get("/builds")
def builds(
    status_filter: str | None = Query(default=None, alias="status"),
    principal: Principal = Depends(require_permission("release.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    query = select(ReleaseBuild).where(
        ReleaseBuild.company_id == principal.company.id
    )
    if status_filter:
        query = query.where(ReleaseBuild.status == status_filter)
    items = db.scalars(
        query.order_by(ReleaseBuild.created_at.desc()).limit(300)
    ).all()
    return [
        {
            "id": item.id,
            "version": item.version,
            "branch": item.branch,
            "status": item.status,
            "test_summary": item.test_summary,
            "created_at": item.created_at,
        }
        for item in items
    ]


@router.post("/environments", status_code=201)
def create_environment(
    payload: DeploymentEnvironmentCreateRequest,
    principal: Principal = Depends(require_permission("release.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = DeploymentEnvironment(
        id=new_id("deployment_environment"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Código de ambiente duplicado.") from exc
    return {"id": item.id}


@router.get("/environments")
def environments(
    principal: Principal = Depends(require_permission("release.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    items = db.scalars(
        select(DeploymentEnvironment)
        .where(DeploymentEnvironment.company_id == principal.company.id)
        .order_by(DeploymentEnvironment.name)
    ).all()
    return [
        {
            "id": item.id,
            "code": item.code,
            "name": item.name,
            "environment_type": item.environment_type,
            "base_url": item.base_url,
            "protected": item.protected,
            "active": item.active,
        }
        for item in items
    ]


@router.post("/deployments", status_code=201)
def create_deployment(
    payload: DeploymentReleaseCreateRequest,
    principal: Principal = Depends(require_permission("release.execute")),
    db: Session = Depends(get_db),
) -> dict:
    build = db.get(ReleaseBuild, payload.build_id)
    environment = db.get(DeploymentEnvironment, payload.environment_id)

    if build is None or build.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Build não encontrado.")
    if environment is None or environment.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Ambiente não encontrado.")
    if build.status != "completed":
        raise HTTPException(status_code=409, detail="Build ainda não está concluído.")

    approval_status = "pending" if environment.protected else "not_required"

    item = DeploymentRelease(
        id=new_id("deployment_release"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        build_id=build.id,
        environment_id=environment.id,
        strategy=payload.strategy,
        status="pending",
        approval_status=approval_status,
        rollback_build_id=payload.rollback_build_id,
        health_checks=[],
        deployed_by=principal.user.id,
    )
    db.add(item)
    db.commit()
    return {
        "id": item.id,
        "status": item.status,
        "approval_status": item.approval_status,
    }


@router.patch("/deployments/{deployment_id}/complete")
def complete_deployment(
    deployment_id: str,
    status: str,
    health_checks: list[dict] | None = None,
    principal: Principal = Depends(require_permission("release.execute")),
    db: Session = Depends(get_db),
) -> dict:
    if status not in {"completed", "failed", "rolled_back"}:
        raise HTTPException(status_code=422, detail="Status inválido.")

    item = db.get(DeploymentRelease, deployment_id)
    if item is None or item.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Deployment não encontrado.")

    if item.approval_status == "pending":
        raise HTTPException(status_code=409, detail="Deployment ainda não foi aprovado.")

    item.status = status
    item.health_checks = health_checks or []
    item.deployed_at = item.deployed_at or datetime.now(timezone.utc)
    item.completed_at = datetime.now(timezone.utc)
    db.commit()
    return {"id": item.id, "status": item.status}


@router.get("/deployments")
def deployments(
    environment_id: str | None = None,
    principal: Principal = Depends(require_permission("release.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    query = select(DeploymentRelease).where(
        DeploymentRelease.company_id == principal.company.id
    )
    if environment_id:
        query = query.where(DeploymentRelease.environment_id == environment_id)
    items = db.scalars(
        query.order_by(DeploymentRelease.created_at.desc()).limit(300)
    ).all()
    return [
        {
            "id": item.id,
            "build_id": item.build_id,
            "environment_id": item.environment_id,
            "strategy": item.strategy,
            "status": item.status,
            "approval_status": item.approval_status,
            "created_at": item.created_at,
        }
        for item in items
    ]


@router.post("/feature-flags", status_code=201)
def create_feature_flag(
    payload: FeatureFlagCreateRequest,
    principal: Principal = Depends(require_permission("release.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = FeatureFlag(
        id=new_id("feature_flag"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Chave de feature flag duplicada.") from exc
    return {"id": item.id}


@router.get("/feature-flags")
def feature_flags(
    principal: Principal = Depends(require_permission("release.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    items = db.scalars(
        select(FeatureFlag)
        .where(FeatureFlag.company_id == principal.company.id)
        .order_by(FeatureFlag.name)
    ).all()
    return [
        {
            "id": item.id,
            "key": item.key,
            "name": item.name,
            "enabled": item.enabled,
            "rollout_percent": item.rollout_percent,
            "environments": item.environments,
        }
        for item in items
    ]


@router.post("/change-approvals", status_code=201)
def create_change_approval(
    payload: ChangeApprovalCreateRequest,
    principal: Principal = Depends(require_permission("release.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = ChangeApproval(
        id=new_id("change_approval"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        requested_by=principal.user.id,
        status="pending",
        decision_notes="",
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    return {"id": item.id}


@router.patch("/change-approvals/{approval_id}/decision")
def decide_change_approval(
    approval_id: str,
    decision: str,
    notes: str = "",
    principal: Principal = Depends(require_permission("release.approve")),
    db: Session = Depends(get_db),
) -> dict:
    if decision not in {"approved", "rejected"}:
        raise HTTPException(status_code=422, detail="Decisão inválida.")

    item = db.get(ChangeApproval, approval_id)
    if item is None or item.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Aprovação não encontrada.")

    item.status = decision
    item.approved_by = principal.user.id
    item.decided_at = datetime.now(timezone.utc)
    item.decision_notes = notes

    if item.change_type == "deployment" and decision == "approved":
        deployment = db.get(DeploymentRelease, item.reference_id)
        if deployment is not None and deployment.company_id == principal.company.id:
            deployment.approval_status = "approved"
            deployment.approved_by = principal.user.id

    db.commit()
    return {"id": item.id, "status": item.status}


@router.get("/change-approvals")
def change_approvals(
    status_filter: str | None = Query(default=None, alias="status"),
    principal: Principal = Depends(require_permission("release.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    query = select(ChangeApproval).where(
        ChangeApproval.company_id == principal.company.id
    )
    if status_filter:
        query = query.where(ChangeApproval.status == status_filter)
    items = db.scalars(
        query.order_by(ChangeApproval.requested_at.desc())
    ).all()
    return [
        {
            "id": item.id,
            "change_type": item.change_type,
            "reference_id": item.reference_id,
            "title": item.title,
            "risk_level": item.risk_level,
            "status": item.status,
            "requested_at": item.requested_at,
        }
        for item in items
    ]


@router.post("/readiness-checks", status_code=201)
def create_readiness_check(
    payload: ReadinessCheckCreateRequest,
    principal: Principal = Depends(require_permission("release.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = ProductionReadinessCheck(
        id=new_id("readiness_check"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        status="pending",
        evidence={},
        findings=[],
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    return {"id": item.id}


@router.patch("/readiness-checks/{check_id}/complete")
def complete_readiness_check(
    check_id: str,
    payload: ReadinessCheckCompleteRequest,
    principal: Principal = Depends(require_permission("release.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = db.get(ProductionReadinessCheck, check_id)
    if item is None or item.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Check não encontrado.")

    item.status = payload.status
    item.evidence = payload.evidence
    item.findings = payload.findings
    item.checked_by = principal.user.id
    item.checked_at = datetime.now(timezone.utc)
    db.commit()
    return {"id": item.id, "status": item.status}


@router.get("/readiness")
def readiness(
    release_id: str | None = None,
    principal: Principal = Depends(require_permission("release.read")),
    db: Session = Depends(get_db),
) -> dict:
    return readiness_summary(
        db,
        company_id=principal.company.id,
        release_id=release_id,
    )


@router.post("/metrics", status_code=201)
def create_release_metrics(
    environment_id: str | None = None,
    principal: Principal = Depends(require_permission("release.read")),
    db: Session = Depends(get_db),
) -> dict:
    item = generate_release_metrics(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        environment_id=environment_id,
    )
    db.commit()
    return {
        "id": item.id,
        "deployment_frequency": item.deployment_frequency,
        "lead_time_hours": item.lead_time_hours,
        "change_failure_rate_percent": item.change_failure_rate_percent,
        "mean_time_to_recovery_minutes": item.mean_time_to_recovery_minutes,
    }


@router.get("/dashboard")
def dashboard(
    principal: Principal = Depends(require_permission("release.read")),
    db: Session = Depends(get_db),
) -> dict:
    values = deployment_dashboard(
        db,
        company_id=principal.company.id,
    )
    readiness_data = readiness_summary(
        db,
        company_id=principal.company.id,
        release_id=None,
    )
    values["readiness"] = readiness_data
    return values
