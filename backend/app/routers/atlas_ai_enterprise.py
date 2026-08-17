
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..database import get_db
from ..models import (
    AtlasAiMemory,
    AtlasAiMessage,
    AtlasAiPlan,
    AtlasAiRecommendation,
    AtlasAiSession,
    AtlasKnowledgeDocument,
    new_id,
)
from ..schemas import (
    AtlasAiChatRequest,
    AtlasAiChatResponse,
    AtlasAiMemoryCreateRequest,
    AtlasAiMessageResponse,
    AtlasAiPlanRequest,
    AtlasAiPlanResponse,
    AtlasAiRecommendationResponse,
    AtlasAiSessionCreateRequest,
    AtlasAiSessionResponse,
    AtlasKnowledgeDocumentCreateRequest,
    AtlasKnowledgeDocumentResponse,
)
from ..services.atlas_ai_enterprise_service import (
    create_knowledge_document,
    ensure_default_agents,
    generate_plan,
    orchestrator,
)

router = APIRouter(prefix="/atlas-ai", tags=["atlas-ai-enterprise"])


def _farm_allowed(principal: Principal, farm_id: str | None) -> None:
    if farm_id is None or principal.membership.role in {
        "owner",
        "admin",
        "companyAdministrator",
    }:
        return
    if principal.membership.farm_ids and farm_id not in set(principal.membership.farm_ids):
        raise HTTPException(status_code=403, detail="Fazenda não autorizada.")


@router.post("/sessions", response_model=AtlasAiSessionResponse, status_code=201)
def create_session(
    payload: AtlasAiSessionCreateRequest,
    principal: Principal = Depends(require_permission("atlas_ai.use")),
    db: Session = Depends(get_db),
) -> AtlasAiSession:
    _farm_allowed(principal, payload.farm_id)
    ensure_default_agents(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
    )
    item = AtlasAiSession(
        id=new_id("ai_session"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=payload.farm_id,
        user_id=principal.user.id,
        title=payload.title,
        status="active",
        context_snapshot={},
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.get("/sessions", response_model=list[AtlasAiSessionResponse])
def list_sessions(
    farm_id: str | None = None,
    principal: Principal = Depends(require_permission("atlas_ai.read")),
    db: Session = Depends(get_db),
) -> list[AtlasAiSession]:
    _farm_allowed(principal, farm_id)
    query = select(AtlasAiSession).where(
        AtlasAiSession.company_id == principal.company.id,
        AtlasAiSession.user_id == principal.user.id,
    )
    if farm_id:
        query = query.where(AtlasAiSession.farm_id == farm_id)
    return list(
        db.scalars(
            query.order_by(AtlasAiSession.updated_at.desc())
        ).all()
    )


@router.post("/chat", response_model=AtlasAiChatResponse)
def chat(
    payload: AtlasAiChatRequest,
    principal: Principal = Depends(require_permission("atlas_ai.use")),
    db: Session = Depends(get_db),
) -> AtlasAiChatResponse:
    _farm_allowed(principal, payload.farm_id)
    ensure_default_agents(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
    )

    session = None
    if payload.session_id:
        session = db.get(AtlasAiSession, payload.session_id)
        if session is None or session.company_id != principal.company.id:
            raise HTTPException(status_code=404, detail="Sessão não encontrada.")

    if session is None:
        session = AtlasAiSession(
            id=new_id("ai_session"),
            tenant_id=principal.company.tenant_id,
            company_id=principal.company.id,
            farm_id=payload.farm_id,
            user_id=principal.user.id,
            title=payload.message[:80],
            status="active",
            context_snapshot={},
        )
        db.add(session)
        db.flush()

    user_message = AtlasAiMessage(
        id=new_id("ai_message"),
        session_id=session.id,
        company_id=principal.company.id,
        role="user",
        content=payload.message,
        agent_code="",
        confidence_percent=100,
        sources=[],
        evidence=[],
        limitations=[],
    )
    db.add(user_message)
    db.flush()

    result = orchestrator.execute(
        db,
        company_id=principal.company.id,
        farm_id=session.farm_id,
        message=payload.message,
        requested_specialty=payload.requested_specialty,
    )

    assistant_message = AtlasAiMessage(
        id=new_id("ai_message"),
        session_id=session.id,
        company_id=principal.company.id,
        role="assistant",
        content=result.answer,
        agent_code=result.agent_code,
        confidence_percent=result.confidence_percent,
        sources=[],
        evidence=result.evidence,
        limitations=result.limitations,
    )
    db.add(assistant_message)

    recommendation_ids: list[str] = []
    if result.recommendation is not None:
        recommendation = AtlasAiRecommendation(
            id=new_id("ai_recommendation_v2"),
            tenant_id=principal.company.tenant_id,
            company_id=principal.company.id,
            farm_id=session.farm_id,
            agent_code=result.agent_code,
            title=result.recommendation["title"],
            description=result.recommendation["description"],
            priority=result.recommendation["priority"],
            status="pending",
            confidence_percent=result.recommendation["confidence_percent"],
            expected_financial_impact=0,
            expected_technical_impact="Melhoria operacional esperada.",
            reasoning=result.recommendation["reasoning"],
            actions=result.recommendation["actions"],
        )
        db.add(recommendation)
        db.flush()
        recommendation_ids.append(recommendation.id)

    session.last_message_at = datetime.now(timezone.utc)
    session.context_snapshot = {
        "agent_code": result.agent_code,
        "confidence_percent": result.confidence_percent,
    }
    db.commit()

    return AtlasAiChatResponse(
        session_id=session.id,
        message_id=assistant_message.id,
        answer=result.answer,
        agent_code=result.agent_code,
        confidence_percent=result.confidence_percent,
        evidence=result.evidence,
        limitations=result.limitations,
        recommendations_created=recommendation_ids,
    )


@router.get("/sessions/{session_id}/messages", response_model=list[AtlasAiMessageResponse])
def messages(
    session_id: str,
    principal: Principal = Depends(require_permission("atlas_ai.read")),
    db: Session = Depends(get_db),
) -> list[AtlasAiMessage]:
    session = db.get(AtlasAiSession, session_id)
    if session is None or session.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Sessão não encontrada.")

    return list(
        db.scalars(
            select(AtlasAiMessage)
            .where(AtlasAiMessage.session_id == session_id)
            .order_by(AtlasAiMessage.created_at)
        ).all()
    )


@router.post("/memories", status_code=201)
def create_memory(
    payload: AtlasAiMemoryCreateRequest,
    principal: Principal = Depends(require_permission("atlas_ai.manage")),
    db: Session = Depends(get_db),
) -> dict:
    _farm_allowed(principal, payload.farm_id)
    item = AtlasAiMemory(
        id=new_id("ai_memory"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        **payload.model_dump(),
    )
    db.add(item)
    db.commit()
    return {"id": item.id}


@router.get("/memories")
def memories(
    farm_id: str | None = None,
    memory_type: str | None = None,
    principal: Principal = Depends(require_permission("atlas_ai.read")),
    db: Session = Depends(get_db),
) -> list[dict]:
    _farm_allowed(principal, farm_id)
    query = select(AtlasAiMemory).where(
        AtlasAiMemory.company_id == principal.company.id
    )
    if farm_id:
        query = query.where(AtlasAiMemory.farm_id == farm_id)
    if memory_type:
        query = query.where(AtlasAiMemory.memory_type == memory_type)
    items = db.scalars(
        query.order_by(
            AtlasAiMemory.importance.desc(),
            AtlasAiMemory.updated_at.desc(),
        )
    ).all()
    return [
        {
            "id": item.id,
            "memory_type": item.memory_type,
            "key": item.key,
            "content": item.content,
            "importance": item.importance,
            "source": item.source,
            "updated_at": item.updated_at,
        }
        for item in items
    ]


@router.post("/plans", response_model=AtlasAiPlanResponse, status_code=201)
def create_plan(
    payload: AtlasAiPlanRequest,
    principal: Principal = Depends(require_permission("atlas_ai.use")),
    db: Session = Depends(get_db),
) -> AtlasAiPlan:
    _farm_allowed(principal, payload.farm_id)
    item = generate_plan(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=payload.farm_id,
        horizon=payload.horizon,
    )
    db.commit()
    db.refresh(item)
    return item


@router.get("/plans", response_model=list[AtlasAiPlanResponse])
def plans(
    farm_id: str | None = None,
    horizon: str | None = None,
    principal: Principal = Depends(require_permission("atlas_ai.read")),
    db: Session = Depends(get_db),
) -> list[AtlasAiPlan]:
    _farm_allowed(principal, farm_id)
    query = select(AtlasAiPlan).where(
        AtlasAiPlan.company_id == principal.company.id
    )
    if farm_id:
        query = query.where(AtlasAiPlan.farm_id == farm_id)
    if horizon:
        query = query.where(AtlasAiPlan.horizon == horizon)
    return list(
        db.scalars(
            query.order_by(AtlasAiPlan.generated_at.desc())
        ).all()
    )


@router.get("/recommendations", response_model=list[AtlasAiRecommendationResponse])
def recommendations(
    farm_id: str | None = None,
    status_filter: str | None = Query(default=None, alias="status"),
    principal: Principal = Depends(require_permission("atlas_ai.read")),
    db: Session = Depends(get_db),
) -> list[AtlasAiRecommendation]:
    _farm_allowed(principal, farm_id)
    query = select(AtlasAiRecommendation).where(
        AtlasAiRecommendation.company_id == principal.company.id
    )
    if farm_id:
        query = query.where(AtlasAiRecommendation.farm_id == farm_id)
    if status_filter:
        query = query.where(AtlasAiRecommendation.status == status_filter)
    return list(
        db.scalars(
            query.order_by(AtlasAiRecommendation.created_at.desc())
        ).all()
    )


@router.patch(
    "/recommendations/{recommendation_id}/status",
    response_model=AtlasAiRecommendationResponse,
)
def review_recommendation(
    recommendation_id: str,
    status: str,
    principal: Principal = Depends(require_permission("atlas_ai.manage")),
    db: Session = Depends(get_db),
) -> AtlasAiRecommendation:
    if status not in {"accepted", "rejected", "completed", "pending"}:
        raise HTTPException(status_code=422, detail="Status inválido.")

    item = db.get(AtlasAiRecommendation, recommendation_id)
    if item is None or item.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Recomendação não encontrada.")

    item.status = status
    item.reviewed_by = principal.user.id
    item.reviewed_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(item)
    return item


@router.post(
    "/knowledge/documents",
    response_model=AtlasKnowledgeDocumentResponse,
    status_code=201,
)
def add_document(
    payload: AtlasKnowledgeDocumentCreateRequest,
    principal: Principal = Depends(require_permission("atlas_ai.manage")),
    db: Session = Depends(get_db),
) -> AtlasKnowledgeDocument:
    _farm_allowed(principal, payload.farm_id)
    item = create_knowledge_document(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        payload=payload.model_dump(),
    )
    db.commit()
    db.refresh(item)
    return item


@router.get(
    "/knowledge/documents",
    response_model=list[AtlasKnowledgeDocumentResponse],
)
def documents(
    farm_id: str | None = None,
    category: str | None = None,
    principal: Principal = Depends(require_permission("atlas_ai.read")),
    db: Session = Depends(get_db),
) -> list[AtlasKnowledgeDocument]:
    _farm_allowed(principal, farm_id)
    query = select(AtlasKnowledgeDocument).where(
        AtlasKnowledgeDocument.company_id == principal.company.id,
        AtlasKnowledgeDocument.active.is_(True),
    )
    if farm_id:
        query = query.where(AtlasKnowledgeDocument.farm_id == farm_id)
    if category:
        query = query.where(AtlasKnowledgeDocument.category == category)
    return list(
        db.scalars(
            query.order_by(AtlasKnowledgeDocument.updated_at.desc())
        ).all()
    )


@router.get("/dashboard")
def dashboard(
    principal: Principal = Depends(require_permission("atlas_ai.read")),
    db: Session = Depends(get_db),
) -> dict:
    recommendations = list(
        db.scalars(
            select(AtlasAiRecommendation).where(
                AtlasAiRecommendation.company_id == principal.company.id,
                AtlasAiRecommendation.status == "pending",
            )
        ).all()
    )
    plans = list(
        db.scalars(
            select(AtlasAiPlan)
            .where(
                AtlasAiPlan.company_id == principal.company.id,
                AtlasAiPlan.status == "active",
            )
            .order_by(AtlasAiPlan.generated_at.desc())
            .limit(10)
        ).all()
    )
    return {
        "pending_recommendations": len(recommendations),
        "high_priority_recommendations": sum(
            1 for item in recommendations if item.priority == "high"
        ),
        "active_plans": len(plans),
        "average_confidence": round(
            (
                sum(item.confidence_percent for item in recommendations)
                / len(recommendations)
            )
            if recommendations
            else 0,
            2,
        ),
        "engine": "atlas_enterprise_ai_deterministic",
        "external_llm_connected": False,
    }
