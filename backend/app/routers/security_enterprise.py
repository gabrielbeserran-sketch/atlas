
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..database import get_db
from ..models import (
    AccessReview,
    BusinessContinuityPlan,
    ContinuityExercise,
    PrivacyConsent,
    PrivacyRequest,
    SecurityPolicy,
    SecurityPostureSnapshot,
    SecurityRisk,
    new_id,
)
from ..schemas import (
    AccessReviewCreateRequest,
    BusinessContinuityPlanCreateRequest,
    ContinuityExerciseCompleteRequest,
    ContinuityExerciseCreateRequest,
    PrivacyConsentCreateRequest,
    PrivacyRequestCreateRequest,
    SecurityPolicyCreateRequest,
    SecurityRiskCreateRequest,
)
from ..services.security_privacy_service import (
    calculate_risk_score,
    posture_snapshot,
)

router = APIRouter(prefix="/security-enterprise", tags=["security-privacy-continuity"])


@router.post("/policies", status_code=201)
def create_policy(
    payload: SecurityPolicyCreateRequest,
    principal: Principal = Depends(require_permission("security_enterprise.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = SecurityPolicy(
        id=new_id("security_policy"),
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
    principal: Principal = Depends(require_permission("security_enterprise.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    items = db.scalars(
        select(SecurityPolicy)
        .where(SecurityPolicy.company_id == principal.company.id)
        .order_by(SecurityPolicy.name)
    ).all()
    return [
        {
            "id": item.id,
            "code": item.code,
            "name": item.name,
            "policy_type": item.policy_type,
            "enforcement_mode": item.enforcement_mode,
            "active": item.active,
        }
        for item in items
    ]


@router.post("/access-reviews", status_code=201)
def create_access_review(
    payload: AccessReviewCreateRequest,
    principal: Principal = Depends(require_permission("security_enterprise.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = AccessReview(
        id=new_id("access_review"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        status="pending",
        findings=[],
        decision="",
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    return {"id": item.id}


@router.get("/access-reviews")
def access_reviews(
    status_filter: str | None = Query(default=None, alias="status"),
    principal: Principal = Depends(require_permission("security_enterprise.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    query = select(AccessReview).where(
        AccessReview.company_id == principal.company.id
    )
    if status_filter:
        query = query.where(AccessReview.status == status_filter)
    items = db.scalars(query.order_by(AccessReview.created_at.desc())).all()
    return [
        {
            "id": item.id,
            "review_type": item.review_type,
            "subject_user_id": item.subject_user_id,
            "reviewer_user_id": item.reviewer_user_id,
            "status": item.status,
            "due_at": item.due_at,
        }
        for item in items
    ]


@router.patch("/access-reviews/{review_id}/complete")
def complete_access_review(
    review_id: str,
    decision: str,
    findings: list[dict] | None = None,
    principal: Principal = Depends(require_permission("security_enterprise.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = db.get(AccessReview, review_id)
    if item is None or item.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Revisão não encontrada.")
    item.status = "completed"
    item.decision = decision
    item.findings = findings or []
    item.completed_at = datetime.now(timezone.utc)
    db.commit()
    return {"id": item.id, "status": item.status}


@router.post("/privacy/consents", status_code=201)
def create_consent(
    payload: PrivacyConsentCreateRequest,
    principal: Principal = Depends(require_permission("privacy.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = PrivacyConsent(
        id=new_id("privacy_consent"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    return {"id": item.id}


@router.get("/privacy/consents")
def consents(
    data_subject_id: str | None = None,
    principal: Principal = Depends(require_permission("privacy.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    query = select(PrivacyConsent).where(
        PrivacyConsent.company_id == principal.company.id
    )
    if data_subject_id:
        query = query.where(PrivacyConsent.data_subject_id == data_subject_id)
    items = db.scalars(query.order_by(PrivacyConsent.granted_at.desc())).all()
    return [
        {
            "id": item.id,
            "data_subject_type": item.data_subject_type,
            "data_subject_id": item.data_subject_id,
            "purpose": item.purpose,
            "granted": item.granted,
            "granted_at": item.granted_at,
            "revoked_at": item.revoked_at,
        }
        for item in items
    ]


@router.post("/privacy/requests", status_code=201)
def create_privacy_request(
    payload: PrivacyRequestCreateRequest,
    principal: Principal = Depends(require_permission("privacy.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = PrivacyRequest(
        id=new_id("privacy_request"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        status="open",
        response_summary="",
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    return {"id": item.id}


@router.get("/privacy/requests")
def privacy_requests(
    status_filter: str | None = Query(default=None, alias="status"),
    principal: Principal = Depends(require_permission("privacy.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    query = select(PrivacyRequest).where(
        PrivacyRequest.company_id == principal.company.id
    )
    if status_filter:
        query = query.where(PrivacyRequest.status == status_filter)
    items = db.scalars(query.order_by(PrivacyRequest.requested_at.desc())).all()
    return [
        {
            "id": item.id,
            "request_type": item.request_type,
            "data_subject_id": item.data_subject_id,
            "status": item.status,
            "requested_at": item.requested_at,
            "due_at": item.due_at,
        }
        for item in items
    ]


@router.post("/risks", status_code=201)
def create_risk(
    payload: SecurityRiskCreateRequest,
    principal: Principal = Depends(require_permission("security_enterprise.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = SecurityRisk(
        id=new_id("security_risk"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        score=calculate_risk_score(payload.likelihood, payload.impact),
        status="open",
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    return {"id": item.id, "score": item.score}


@router.get("/risks")
def risks(
    status_filter: str | None = Query(default=None, alias="status"),
    principal: Principal = Depends(require_permission("security_enterprise.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    query = select(SecurityRisk).where(
        SecurityRisk.company_id == principal.company.id
    )
    if status_filter:
        query = query.where(SecurityRisk.status == status_filter)
    items = db.scalars(query.order_by(SecurityRisk.score.desc())).all()
    return [
        {
            "id": item.id,
            "title": item.title,
            "category": item.category,
            "score": item.score,
            "status": item.status,
            "due_at": item.due_at,
        }
        for item in items
    ]


@router.post("/continuity/plans", status_code=201)
def create_continuity_plan(
    payload: BusinessContinuityPlanCreateRequest,
    principal: Principal = Depends(require_permission("continuity.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = BusinessContinuityPlan(
        id=new_id("continuity_plan"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    return {"id": item.id}


@router.get("/continuity/plans")
def continuity_plans(
    principal: Principal = Depends(require_permission("continuity.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    items = db.scalars(
        select(BusinessContinuityPlan)
        .where(BusinessContinuityPlan.company_id == principal.company.id)
        .order_by(BusinessContinuityPlan.name)
    ).all()
    return [
        {
            "id": item.id,
            "name": item.name,
            "scenario": item.scenario,
            "rto_minutes": item.rto_minutes,
            "rpo_minutes": item.rpo_minutes,
            "last_tested_at": item.last_tested_at,
            "active": item.active,
        }
        for item in items
    ]


@router.post("/continuity/exercises", status_code=201)
def create_exercise(
    payload: ContinuityExerciseCreateRequest,
    principal: Principal = Depends(require_permission("continuity.manage")),
    db: Session = Depends(get_db),
) -> dict:
    plan = db.get(BusinessContinuityPlan, payload.plan_id)
    if plan is None or plan.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Plano não encontrado.")

    item = ContinuityExercise(
        id=new_id("continuity_exercise"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        plan_id=plan.id,
        status="planned",
        findings=[],
        result="",
    )
    db.add(item)
    db.commit()
    return {"id": item.id}


@router.patch("/continuity/exercises/{exercise_id}/complete")
def complete_exercise(
    exercise_id: str,
    payload: ContinuityExerciseCompleteRequest,
    principal: Principal = Depends(require_permission("continuity.manage")),
    db: Session = Depends(get_db),
) -> dict:
    item = db.get(ContinuityExercise, exercise_id)
    if item is None or item.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Exercício não encontrado.")

    plan = db.get(BusinessContinuityPlan, item.plan_id)
    item.actual_rto_minutes = payload.actual_rto_minutes
    item.actual_rpo_minutes = payload.actual_rpo_minutes
    item.findings = payload.findings
    item.status = "completed"
    item.completed_at = datetime.now(timezone.utc)
    item.result = (
        "passed"
        if plan
        and payload.actual_rto_minutes <= plan.rto_minutes
        and payload.actual_rpo_minutes <= plan.rpo_minutes
        else "failed"
    )
    if plan is not None:
        plan.last_tested_at = item.completed_at
    db.commit()
    return {"id": item.id, "result": item.result}


@router.post("/posture/snapshots", status_code=201)
def generate_posture_snapshot(
    principal: Principal = Depends(require_permission("security_enterprise.read")),
    db: Session = Depends(get_db),
) -> dict:
    item = posture_snapshot(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
    )
    db.commit()
    return {
        "id": item.id,
        "posture_score": item.posture_score,
        "findings": item.findings,
    }


@router.get("/dashboard")
def dashboard(
    principal: Principal = Depends(require_permission("security_enterprise.read")),
    db: Session = Depends(get_db),
) -> dict:
    item = posture_snapshot(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
    )
    db.commit()
    return {
        "posture_score": item.posture_score,
        "active_policies": item.active_policies,
        "open_risks": item.open_risks,
        "overdue_reviews": item.overdue_reviews,
        "open_privacy_requests": item.open_privacy_requests,
        "untested_continuity_plans": item.untested_continuity_plans,
        "findings": item.findings,
    }
