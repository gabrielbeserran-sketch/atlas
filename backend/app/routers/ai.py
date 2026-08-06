
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..database import get_db
from ..models import (
    AtlasAiConversation,
    AtlasAiMessage,
    AtlasAiRecommendation,
    new_id,
)
from ..schemas import (
    AtlasAiAnalyzeRequest,
    AtlasAiConversationCreateRequest,
    AtlasAiConversationResponse,
    AtlasAiExecutiveResponse,
    AtlasAiMessageRequest,
    AtlasAiMessageResponse,
    AtlasAiRecommendationResponse,
)
from ..services.atlas_ai_2 import (
    conversational_answer,
    executive_summary,
    execute_area,
)

router = APIRouter(prefix="/ai", tags=["ai"])


def _farm_allowed(principal: Principal, farm_id: str | None) -> None:
    if farm_id is None or principal.membership.role in {"owner", "admin"}:
        return
    if farm_id not in set(principal.membership.farm_ids or []):
        raise HTTPException(status_code=403, detail="Fazenda não autorizada.")


@router.post("/conversations", response_model=AtlasAiConversationResponse, status_code=201)
def create_conversation(
    payload: AtlasAiConversationCreateRequest,
    principal: Principal = Depends(require_permission("ai.use")),
    db: Session = Depends(get_db),
) -> AtlasAiConversation:
    _farm_allowed(principal, payload.farm_id)
    item = AtlasAiConversation(
        id=new_id("ai_conversation"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=payload.farm_id,
        user_id=principal.user.id,
        title=payload.title,
        specialist_area=payload.specialist_area,
        context_snapshot={},
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@router.get("/conversations", response_model=list[AtlasAiConversationResponse])
def list_conversations(
    farm_id: str | None = None,
    principal: Principal = Depends(require_permission("ai.use")),
    db: Session = Depends(get_db),
) -> list[AtlasAiConversation]:
    _farm_allowed(principal, farm_id)
    query = select(AtlasAiConversation).where(
        AtlasAiConversation.company_id == principal.company.id,
        AtlasAiConversation.user_id == principal.user.id,
    )
    if farm_id:
        query = query.where(AtlasAiConversation.farm_id == farm_id)
    return list(
        db.scalars(
            query.order_by(AtlasAiConversation.updated_at.desc())
        ).all()
    )


@router.post(
    "/conversations/{conversation_id}/messages",
    response_model=list[AtlasAiMessageResponse],
)
def send_message(
    conversation_id: str,
    payload: AtlasAiMessageRequest,
    principal: Principal = Depends(require_permission("ai.use")),
    db: Session = Depends(get_db),
) -> list[AtlasAiMessage]:
    conversation = db.get(AtlasAiConversation, conversation_id)
    if (
        conversation is None
        or conversation.company_id != principal.company.id
        or conversation.user_id != principal.user.id
    ):
        raise HTTPException(status_code=404, detail="Conversa não encontrada.")
    _farm_allowed(principal, conversation.farm_id)

    user_message = AtlasAiMessage(
        id=new_id("ai_message"),
        conversation_id=conversation.id,
        role="user",
        content=payload.content,
        structured_payload=payload.context,
        confidence=100,
        sources=[],
    )
    db.add(user_message)

    recommendations = execute_area(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=conversation.farm_id,
        animal_id=payload.context.get("animal_id"),
        area=conversation.specialist_area,
        context=payload.context,
    )
    answer, structured, confidence, sources = conversational_answer(
        area=conversation.specialist_area,
        question=payload.content,
        recommendations=recommendations,
    )
    assistant_message = AtlasAiMessage(
        id=new_id("ai_message"),
        conversation_id=conversation.id,
        role="assistant",
        content=answer,
        structured_payload=structured,
        confidence=confidence,
        sources=sources,
    )
    db.add(assistant_message)
    conversation.context_snapshot = payload.context
    conversation.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(user_message)
    db.refresh(assistant_message)
    return [user_message, assistant_message]


@router.get(
    "/conversations/{conversation_id}/messages",
    response_model=list[AtlasAiMessageResponse],
)
def conversation_messages(
    conversation_id: str,
    principal: Principal = Depends(require_permission("ai.use")),
    db: Session = Depends(get_db),
) -> list[AtlasAiMessage]:
    conversation = db.get(AtlasAiConversation, conversation_id)
    if (
        conversation is None
        or conversation.company_id != principal.company.id
        or conversation.user_id != principal.user.id
    ):
        raise HTTPException(status_code=404, detail="Conversa não encontrada.")
    return list(
        db.scalars(
            select(AtlasAiMessage)
            .where(AtlasAiMessage.conversation_id == conversation_id)
            .order_by(AtlasAiMessage.created_at)
        ).all()
    )


@router.post(
    "/analyze/{area}",
    response_model=list[AtlasAiRecommendationResponse],
)
def analyze_area(
    area: str,
    payload: AtlasAiAnalyzeRequest,
    principal: Principal = Depends(require_permission("ai.use")),
    db: Session = Depends(get_db),
) -> list[AtlasAiRecommendation]:
    allowed = {
        "health",
        "nutrition",
        "reproduction",
        "finance",
        "climate",
        "market",
        "strategy",
        "executive",
        "general",
    }
    if area not in allowed:
        raise HTTPException(status_code=404, detail="Especialidade de IA inválida.")
    _farm_allowed(principal, payload.farm_id)
    items = execute_area(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=payload.farm_id,
        animal_id=payload.animal_id,
        area=area,
        context=payload.context,
    )
    db.commit()
    return items


@router.get(
    "/recommendations",
    response_model=list[AtlasAiRecommendationResponse],
)
def recommendations(
    farm_id: str | None = None,
    area: str | None = None,
    status_filter: str = Query(default="open", alias="status"),
    principal: Principal = Depends(require_permission("ai.read")),
    db: Session = Depends(get_db),
) -> list[AtlasAiRecommendation]:
    _farm_allowed(principal, farm_id)
    query = select(AtlasAiRecommendation).where(
        AtlasAiRecommendation.company_id == principal.company.id,
        AtlasAiRecommendation.status == status_filter,
    )
    if farm_id:
        query = query.where(AtlasAiRecommendation.farm_id == farm_id)
    if area:
        query = query.where(AtlasAiRecommendation.area == area)
    return list(
        db.scalars(
            query.order_by(
                AtlasAiRecommendation.priority.desc(),
                AtlasAiRecommendation.generated_at.desc(),
            )
        ).all()
    )


@router.patch(
    "/recommendations/{recommendation_id}/review",
    response_model=AtlasAiRecommendationResponse,
)
def review_recommendation(
    recommendation_id: str,
    accepted: bool,
    principal: Principal = Depends(require_permission("ai.manage")),
    db: Session = Depends(get_db),
) -> AtlasAiRecommendation:
    item = db.get(AtlasAiRecommendation, recommendation_id)
    if item is None or item.company_id != principal.company.id:
        raise HTTPException(status_code=404, detail="Recomendação não encontrada.")
    _farm_allowed(principal, item.farm_id)
    item.status = "accepted" if accepted else "rejected"
    item.reviewed_by = principal.user.id
    item.reviewed_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(item)
    return item


@router.post("/executive", response_model=AtlasAiExecutiveResponse)
def executive_ai(
    payload: AtlasAiAnalyzeRequest,
    principal: Principal = Depends(require_permission("ai.use")),
    db: Session = Depends(get_db),
) -> dict:
    _farm_allowed(principal, payload.farm_id)
    result = executive_summary(
        db,
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=payload.farm_id,
        context=payload.context,
    )
    db.commit()
    return result
