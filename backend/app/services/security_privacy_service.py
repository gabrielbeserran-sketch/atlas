
from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..models import (
    AccessReview,
    BusinessContinuityPlan,
    PrivacyRequest,
    SecurityPolicy,
    SecurityPostureSnapshot,
    SecurityRisk,
    new_id,
)


def calculate_risk_score(likelihood: float, impact: float) -> float:
    return round(likelihood * impact * 4, 2)


def posture_snapshot(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
) -> SecurityPostureSnapshot:
    policies = list(
        db.scalars(
            select(SecurityPolicy).where(
                SecurityPolicy.company_id == company_id,
                SecurityPolicy.active.is_(True),
            )
        ).all()
    )
    risks = list(
        db.scalars(
            select(SecurityRisk).where(
                SecurityRisk.company_id == company_id,
                SecurityRisk.status == "open",
            )
        ).all()
    )
    reviews = list(
        db.scalars(
            select(AccessReview).where(
                AccessReview.company_id == company_id,
                AccessReview.status == "pending",
            )
        ).all()
    )
    privacy_requests = list(
        db.scalars(
            select(PrivacyRequest).where(
                PrivacyRequest.company_id == company_id,
                PrivacyRequest.status == "open",
            )
        ).all()
    )
    plans = list(
        db.scalars(
            select(BusinessContinuityPlan).where(
                BusinessContinuityPlan.company_id == company_id,
                BusinessContinuityPlan.active.is_(True),
            )
        ).all()
    )

    now = datetime.now(timezone.utc)
    overdue_reviews = sum(
        1
        for item in reviews
        if item.due_at is not None
        and (item.due_at if item.due_at.tzinfo else item.due_at.replace(tzinfo=timezone.utc)) < now
    )
    untested_plans = sum(1 for item in plans if item.last_tested_at is None)

    risk_penalty = min(45.0, sum(item.score for item in risks) / 10)
    review_penalty = min(20.0, overdue_reviews * 5)
    privacy_penalty = min(15.0, len(privacy_requests) * 3)
    continuity_penalty = min(20.0, untested_plans * 5)

    score = max(
        0.0,
        100.0
        - risk_penalty
        - review_penalty
        - privacy_penalty
        - continuity_penalty,
    )

    findings = []
    if risks:
        findings.append(f"{len(risks)} risco(s) de segurança em aberto.")
    if overdue_reviews:
        findings.append(f"{overdue_reviews} revisão(ões) de acesso atrasada(s).")
    if privacy_requests:
        findings.append(f"{len(privacy_requests)} solicitação(ões) de privacidade em aberto.")
    if untested_plans:
        findings.append(f"{untested_plans} plano(s) de continuidade sem teste.")

    item = SecurityPostureSnapshot(
        id=new_id("security_posture"),
        tenant_id=tenant_id,
        company_id=company_id,
        posture_score=round(score, 2),
        active_policies=len(policies),
        open_risks=len(risks),
        overdue_reviews=overdue_reviews,
        open_privacy_requests=len(privacy_requests),
        untested_continuity_plans=untested_plans,
        findings=findings,
    )
    db.add(item)
    db.flush()
    return item
