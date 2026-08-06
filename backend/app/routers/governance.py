
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..database import get_db
from ..models import (
    ComplianceAssessment,
    ComplianceControl,
    DataCatalogAsset,
    DataGovernancePolicy,
    DataQualityRule,
    DataQualityRun,
    ResilienceIncident,
    ServiceHealthSnapshot,
    new_id,
)
from ..schemas import (
    ComplianceAssessmentCreateRequest,
    ComplianceControlCreateRequest,
    DataCatalogAssetCreateRequest,
    DataGovernancePolicyCreateRequest,
    DataQualityRuleCreateRequest,
    ResilienceIncidentCreateRequest,
    ServiceHealthSnapshotCreateRequest,
)
from ..services.governance_resilience_service import (
    compliance_score,
    open_incident_for_unhealthy_service,
    run_quality_checks,
    service_health_summary,
)

router = APIRouter(prefix="/governance", tags=["governance-resilience"])


@router.post("/policies", status_code=201)
def create_policy(
    payload: DataGovernancePolicyCreateRequest,
    principal: Principal = Depends(require_permission("governance.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = DataGovernancePolicy(
        id=new_id("governance_policy"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Código de política duplicado.") from exc
    return {"id": item.id}


@router.get("/policies")
def policies(
    principal: Principal = Depends(require_permission("governance.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    items = db.scalars(
        select(DataGovernancePolicy)
        .where(DataGovernancePolicy.company_id == principal.company.id)
        .order_by(DataGovernancePolicy.name)
    ).all()
    return [
        {
            "id": item.id,
            "code": item.code,
            "name": item.name,
            "resource_type": item.resource_type,
            "classification": item.classification,
            "retention_days": item.retention_days,
            "active": item.active,
        }
        for item in items
    ]


@router.post("/catalog/assets", status_code=201)
def create_asset(
    payload: DataCatalogAssetCreateRequest,
    principal: Principal = Depends(require_permission("governance.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = DataCatalogAsset(
        id=new_id("data_asset"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        quality_score=0,
        active=True,
        **payload.model_dump(),
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Chave de ativo duplicada.") from exc
    return {"id": item.id}


@router.get("/catalog/assets")
def assets(
    principal: Principal = Depends(require_permission("governance.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    items = db.scalars(
        select(DataCatalogAsset)
        .where(DataCatalogAsset.company_id == principal.company.id)
        .order_by(DataCatalogAsset.name)
    ).all()
    return [
        {
            "id": item.id,
            "asset_key": item.asset_key,
            "name": item.name,
            "asset_type": item.asset_type,
            "classification": item.classification,
            "quality_score": item.quality_score,
        }
        for item in items
    ]


@router.post("/quality/rules", status_code=201)
def create_quality_rule(
    payload: DataQualityRuleCreateRequest,
    principal: Principal = Depends(require_permission("governance.manage")),
    db: Session = Depends(get_db),
) -> dict:
    asset = db.get(DataCatalogAsset, payload.asset_id)
    if asset is None or asset.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Ativo de dados não encontrado.")

    item = DataQualityRule(
        id=new_id("quality_rule"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    return {"id": item.id}


@router.post("/quality/assets/{asset_id}/run", status_code=201)
def execute_quality_run(
    asset_id: str,
    sample: list[dict],
    principal: Principal = Depends(require_permission("governance.manage")),
    db: Session = Depends(get_db),
) -> dict:
    asset = db.get(DataCatalogAsset, asset_id)
    if asset is None or asset.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Ativo de dados não encontrado.")

    run = run_quality_checks(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        asset=asset,
        sample=sample,
    )
    db.commit()
    return {
        "id": run.id,
        "score": run.score,
        "checks_total": run.checks_total,
        "checks_failed": run.checks_failed,
        "findings": run.findings,
    }


@router.get("/quality/runs")
def quality_runs(
    principal: Principal = Depends(require_permission("governance.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    items = db.scalars(
        select(DataQualityRun)
        .where(DataQualityRun.company_id == principal.company.id)
        .order_by(DataQualityRun.generated_at.desc())
        .limit(100)
    ).all()
    return [
        {
            "id": item.id,
            "asset_id": item.asset_id,
            "score": item.score,
            "checks_failed": item.checks_failed,
            "generated_at": item.generated_at,
        }
        for item in items
    ]


@router.post("/compliance/controls", status_code=201)
def create_control(
    payload: ComplianceControlCreateRequest,
    principal: Principal = Depends(require_permission("compliance.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = ComplianceControl(
        id=new_id("compliance_control"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        status="implemented",
        **payload.model_dump(),
    )
    db.add(item)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="Código de controle duplicado.") from exc
    return {"id": item.id}


@router.get("/compliance/controls")
def controls(
    principal: Principal = Depends(require_permission("compliance.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    items = db.scalars(
        select(ComplianceControl)
        .where(ComplianceControl.company_id == principal.company.id)
        .order_by(ComplianceControl.framework, ComplianceControl.code)
    ).all()
    return [
        {
            "id": item.id,
            "code": item.code,
            "name": item.name,
            "framework": item.framework,
            "status": item.status,
            "next_review_at": item.next_review_at,
        }
        for item in items
    ]


@router.post("/compliance/controls/{control_id}/assess", status_code=201)
def assess_control(
    control_id: str,
    payload: ComplianceAssessmentCreateRequest,
    principal: Principal = Depends(require_permission("compliance.manage")),
    db: Session = Depends(get_db),
) -> dict:
    control = db.get(ComplianceControl, control_id)
    if control is None or control.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Controle não encontrado.")

    item = ComplianceAssessment(
        id=new_id("compliance_assessment"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        control_id=control.id,
        assessed_by=principal.user.id,
        **payload.model_dump(),
    )
    control.last_reviewed_at = datetime.now(timezone.utc)
    db.add(item)
    db.commit()
    return {"id": item.id, "score": item.score}


@router.get("/compliance/score")
def get_compliance_score(
    principal: Principal = Depends(require_permission("compliance.read")),
    db: Session = Depends(get_db),
) -> dict:
    return compliance_score(db, company_id=principal.company.id)


@router.post("/health/snapshots", status_code=201)
def create_health_snapshot(
    payload: ServiceHealthSnapshotCreateRequest,
    principal: Principal = Depends(require_permission("resilience.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = ServiceHealthSnapshot(
        id=new_id("health_snapshot"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    db.flush()
    incident = open_incident_for_unhealthy_service(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        snapshot=item,
    )
    db.commit()
    return {
        "id": item.id,
        "incident_id": incident.id if incident else None,
    }


@router.get("/health/summary")
def health_summary(
    principal: Principal = Depends(require_permission("resilience.read")),
    db: Session = Depends(get_db),
) -> dict:
    return service_health_summary(db, company_id=principal.company.id)


@router.post("/incidents", status_code=201)
def create_incident(
    payload: ResilienceIncidentCreateRequest,
    principal: Principal = Depends(require_permission("resilience.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = ResilienceIncident(
        id=new_id("resilience_incident"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        status="open",
        root_cause="",
        mitigation="",
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    return {"id": item.id}


@router.get("/incidents")
def incidents(
    principal: Principal = Depends(require_permission("resilience.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    items = db.scalars(
        select(ResilienceIncident)
        .where(ResilienceIncident.company_id == principal.company.id)
        .order_by(ResilienceIncident.opened_at.desc())
    ).all()
    return [
        {
            "id": item.id,
            "title": item.title,
            "severity": item.severity,
            "status": item.status,
            "affected_services": item.affected_services,
            "opened_at": item.opened_at,
        }
        for item in items
    ]


@router.get("/dashboard")
def dashboard(
    principal: Principal = Depends(require_permission("governance.read")),
    db: Session = Depends(get_db),
) -> dict:
    quality_runs = list(
        db.scalars(
            select(DataQualityRun)
            .where(DataQualityRun.company_id == principal.company.id)
            .order_by(DataQualityRun.generated_at.desc())
            .limit(20)
        ).all()
    )
    open_incidents = list(
        db.scalars(
            select(ResilienceIncident).where(
                ResilienceIncident.company_id == principal.company.id,
                ResilienceIncident.status == "open",
            )
        ).all()
    )
    compliance = compliance_score(db, company_id=principal.company.id)
    health = service_health_summary(db, company_id=principal.company.id)
    return {
        "data_quality_average": round(
            sum(item.score for item in quality_runs) / len(quality_runs), 2
        ) if quality_runs else 0,
        "open_incidents": len(open_incidents),
        "critical_incidents": sum(
            1 for item in open_incidents if item.severity == "critical"
        ),
        "compliance_score": compliance["average_score"],
        "healthy_services": health["healthy"],
        "services_down": health["down"],
    }
