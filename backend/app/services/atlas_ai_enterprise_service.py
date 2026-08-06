
from __future__ import annotations

import hashlib
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.orm import Session

from ..ai.context_builder import build_farm_context
from ..ai.orchestrator import AtlasAiOrchestrator, build_plan_items
from ..models import (
    AtlasAiAgent,
    AtlasAiMemory,
    AtlasAiMessage,
    AtlasAiPlan,
    AtlasAiRecommendation,
    AtlasAiSession,
    AtlasKnowledgeDocument,
    new_id,
)

orchestrator = AtlasAiOrchestrator()


def ensure_default_agents(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
) -> None:
    defaults = [
        ("general", "Atlas Gestor", "management"),
        ("health", "Atlas Sanidade", "health"),
        ("reproduction", "Atlas Reprodução", "reproduction"),
        ("nutrition", "Atlas Nutrição", "nutrition"),
        ("finance", "Atlas Financeiro", "finance"),
        ("inventory", "Atlas Estoque", "inventory"),
        ("sustainability", "Atlas Sustentabilidade", "sustainability"),
    ]

    for code, name, specialty in defaults:
        existing = db.scalar(
            select(AtlasAiAgent).where(
                AtlasAiAgent.company_id == company_id,
                AtlasAiAgent.code == code,
            )
        )
        if existing is not None:
            continue

        db.add(
            AtlasAiAgent(
                id=new_id("ai_agent"),
                tenant_id=tenant_id,
                company_id=company_id,
                code=code,
                name=name,
                specialty=specialty,
                description=f"Agente especialista em {specialty}.",
                instructions="Use dados do Atlas e declare limitações.",
                capabilities=["analyze", "recommend", "plan"],
                active=True,
            )
        )
    db.flush()


def create_knowledge_document(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    payload: dict,
) -> AtlasKnowledgeDocument:
    checksum = hashlib.sha256(payload["content"].encode("utf-8")).hexdigest()
    item = AtlasKnowledgeDocument(
        id=new_id("knowledge_document"),
        tenant_id=tenant_id,
        company_id=company_id,
        checksum=checksum,
        **payload,
    )
    db.add(item)
    db.flush()
    return item


def generate_plan(
    db: Session,
    *,
    tenant_id: str,
    company_id: str,
    farm_id: str | None,
    horizon: str,
) -> AtlasAiPlan:
    context = build_farm_context(
        db,
        company_id=company_id,
        farm_id=farm_id,
    )
    items = build_plan_items(horizon, context)
    confidence = min(
        90.0,
        55.0
        + min(20.0, context.get("animals", 0) / 10)
        + min(10.0, context.get("active_alerts", 0)),
    )

    item = AtlasAiPlan(
        id=new_id("ai_plan"),
        tenant_id=tenant_id,
        company_id=company_id,
        farm_id=farm_id,
        horizon=horizon,
        title=f"Plano {horizon} Atlas",
        summary="Plano priorizado com base no contexto operacional disponível.",
        items=items,
        confidence_percent=round(confidence, 2),
        status="active",
        generated_by="atlas_orchestrator",
    )
    db.add(item)
    db.flush()
    return item
