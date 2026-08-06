
"""atlas ai enterprise

Revision ID: 20260805_0011
Revises: 20260805_0010
"""
from alembic import op
import sqlalchemy as sa

revision = "20260805_0011"
down_revision = "20260805_0010"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "atlas_ai_agents",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("code", sa.String(80), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("specialty", sa.String(80), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("instructions", sa.Text(), nullable=False),
        sa.Column("capabilities", sa.JSON(), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "code", name="uq_atlas_ai_agent_company_code"),
    )
    op.create_index("ix_atlas_ai_agents_company", "atlas_ai_agents", ["company_id"])
    op.create_index("ix_atlas_ai_agents_specialty", "atlas_ai_agents", ["specialty"])

    op.create_table(
        "atlas_ai_sessions",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("user_id", sa.String(80), nullable=False),
        sa.Column("title", sa.String(220), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("context_snapshot", sa.JSON(), nullable=False),
        sa.Column("last_message_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_atlas_ai_sessions_company", "atlas_ai_sessions", ["company_id"])
    op.create_index("ix_atlas_ai_sessions_user", "atlas_ai_sessions", ["user_id"])
    op.create_index("ix_atlas_ai_sessions_farm", "atlas_ai_sessions", ["farm_id"])

    op.create_table(
        "atlas_ai_messages",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("session_id", sa.String(80), sa.ForeignKey("atlas_ai_sessions.id", ondelete="CASCADE"), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("role", sa.String(30), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("agent_code", sa.String(80), nullable=False),
        sa.Column("confidence_percent", sa.Float(), nullable=False),
        sa.Column("sources", sa.JSON(), nullable=False),
        sa.Column("evidence", sa.JSON(), nullable=False),
        sa.Column("limitations", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_atlas_ai_messages_session", "atlas_ai_messages", ["session_id"])
    op.create_index("ix_atlas_ai_messages_company", "atlas_ai_messages", ["company_id"])

    op.create_table(
        "atlas_ai_memories",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("user_id", sa.String(80), nullable=True),
        sa.Column("memory_type", sa.String(50), nullable=False),
        sa.Column("key", sa.String(160), nullable=False),
        sa.Column("content", sa.JSON(), nullable=False),
        sa.Column("importance", sa.Float(), nullable=False),
        sa.Column("source", sa.String(120), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_atlas_ai_memories_company", "atlas_ai_memories", ["company_id"])
    op.create_index("ix_atlas_ai_memories_farm", "atlas_ai_memories", ["farm_id"])
    op.create_index("ix_atlas_ai_memories_type", "atlas_ai_memories", ["memory_type"])

    op.create_table(
        "atlas_ai_recommendations_v2",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("agent_code", sa.String(80), nullable=False),
        sa.Column("title", sa.String(220), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("priority", sa.String(30), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("confidence_percent", sa.Float(), nullable=False),
        sa.Column("expected_financial_impact", sa.Float(), nullable=False),
        sa.Column("expected_technical_impact", sa.Text(), nullable=False),
        sa.Column("reasoning", sa.JSON(), nullable=False),
        sa.Column("actions", sa.JSON(), nullable=False),
        sa.Column("due_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("reviewed_by", sa.String(80), nullable=True),
        sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_atlas_ai_recommendations_company", "atlas_ai_recommendations_v2", ["company_id"])
    op.create_index("ix_atlas_ai_recommendations_priority", "atlas_ai_recommendations_v2", ["priority"])
    op.create_index("ix_atlas_ai_recommendations_status", "atlas_ai_recommendations_v2", ["status"])

    op.create_table(
        "atlas_ai_plans",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("horizon", sa.String(30), nullable=False),
        sa.Column("title", sa.String(220), nullable=False),
        sa.Column("summary", sa.Text(), nullable=False),
        sa.Column("items", sa.JSON(), nullable=False),
        sa.Column("confidence_percent", sa.Float(), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("generated_by", sa.String(80), nullable=False),
        sa.Column("generated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_atlas_ai_plans_company", "atlas_ai_plans", ["company_id"])
    op.create_index("ix_atlas_ai_plans_horizon", "atlas_ai_plans", ["horizon"])

    op.create_table(
        "atlas_knowledge_documents",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("title", sa.String(220), nullable=False),
        sa.Column("category", sa.String(80), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("tags", sa.JSON(), nullable=False),
        sa.Column("source_reference", sa.String(500), nullable=False),
        sa.Column("checksum", sa.String(128), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_atlas_knowledge_company", "atlas_knowledge_documents", ["company_id"])
    op.create_index("ix_atlas_knowledge_farm", "atlas_knowledge_documents", ["farm_id"])
    op.create_index("ix_atlas_knowledge_category", "atlas_knowledge_documents", ["category"])


def downgrade() -> None:
    op.drop_table("atlas_knowledge_documents")
    op.drop_table("atlas_ai_plans")
    op.drop_table("atlas_ai_recommendations_v2")
    op.drop_table("atlas_ai_memories")
    op.drop_table("atlas_ai_messages")
    op.drop_table("atlas_ai_sessions")
    op.drop_table("atlas_ai_agents")
