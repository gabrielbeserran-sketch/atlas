
from app.models import (
    AtlasAiConversation,
    AtlasAiExecution,
    AtlasAiMessage,
    AtlasAiRecommendation,
)


def test_phase47_tables():
    assert AtlasAiConversation.__tablename__ == "atlas_ai_conversations"
    assert AtlasAiMessage.__tablename__ == "atlas_ai_messages"
    assert AtlasAiRecommendation.__tablename__ == "atlas_ai_recommendations"
    assert AtlasAiExecution.__tablename__ == "atlas_ai_executions"
