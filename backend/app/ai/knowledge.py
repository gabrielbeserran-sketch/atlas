
from __future__ import annotations

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from ..models import AtlasKnowledgeDocument


def retrieve_documents(
    db: Session,
    *,
    company_id: str,
    farm_id: str | None,
    query: str,
    limit: int = 5,
) -> list[AtlasKnowledgeDocument]:
    tokens = [
        token.strip().lower()
        for token in query.replace(",", " ").replace(".", " ").split()
        if len(token.strip()) >= 4
    ]

    statement = select(AtlasKnowledgeDocument).where(
        AtlasKnowledgeDocument.company_id == company_id,
        AtlasKnowledgeDocument.active.is_(True),
        or_(
            AtlasKnowledgeDocument.farm_id.is_(None),
            AtlasKnowledgeDocument.farm_id == farm_id,
        ),
    )

    documents = list(
        db.scalars(
            statement.order_by(AtlasKnowledgeDocument.updated_at.desc()).limit(100)
        ).all()
    )

    ranked = []
    for document in documents:
        haystack = (
            f"{document.title} {document.category} {document.content} "
            f"{' '.join(document.tags or [])}"
        ).lower()
        score = sum(1 for token in tokens if token in haystack)
        ranked.append((score, document))

    ranked.sort(key=lambda item: item[0], reverse=True)
    return [
        document
        for score, document in ranked[:limit]
        if score > 0 or not tokens
    ]
