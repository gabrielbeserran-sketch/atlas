
from app.models import (
    AtlasAiAgent,
    AtlasAiMemory,
    AtlasAiMessage,
    AtlasAiPlan,
    AtlasAiRecommendation,
    AtlasAiSession,
    AtlasKnowledgeDocument,
)


def test_phase52_tables():
    assert AtlasAiAgent.__tablename__ == "atlas_ai_agents"
    assert AtlasAiSession.__tablename__ == "atlas_ai_sessions"
    assert AtlasAiMessage.__tablename__ == "atlas_ai_messages"
    assert AtlasAiMemory.__tablename__ == "atlas_ai_memories"
    assert AtlasAiRecommendation.__tablename__ == "atlas_ai_recommendations_v2"
    assert AtlasAiPlan.__tablename__ == "atlas_ai_plans"
    assert AtlasKnowledgeDocument.__tablename__ == "atlas_knowledge_documents"
