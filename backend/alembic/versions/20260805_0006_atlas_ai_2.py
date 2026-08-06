
"""atlas ai 2

Revision ID: 20260805_0006
Revises: 20260805_0005
"""
from alembic import op
import sqlalchemy as sa

revision = "20260805_0006"
down_revision = "20260805_0005"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "atlas_ai_conversations",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("user_id", sa.String(80), nullable=False),
        sa.Column("title", sa.String(220), nullable=False),
        sa.Column("specialist_area", sa.String(80), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("context_snapshot", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_atlas_ai_conversations_company", "atlas_ai_conversations", ["company_id"])
    op.create_index("ix_atlas_ai_conversations_farm", "atlas_ai_conversations", ["farm_id"])
    op.create_index("ix_atlas_ai_conversations_user", "atlas_ai_conversations", ["user_id"])

    op.create_table(
        "atlas_ai_messages",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column(
            "conversation_id",
            sa.String(80),
            sa.ForeignKey("atlas_ai_conversations.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("role", sa.String(30), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("structured_payload", sa.JSON(), nullable=False),
        sa.Column("confidence", sa.Float(), nullable=False),
        sa.Column("sources", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_atlas_ai_messages_conversation", "atlas_ai_messages", ["conversation_id"])

    op.create_table(
        "atlas_ai_recommendations",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("animal_id", sa.String(80), nullable=True),
        sa.Column("area", sa.String(80), nullable=False),
        sa.Column("recommendation_type", sa.String(100), nullable=False),
        sa.Column("title", sa.String(220), nullable=False),
        sa.Column("summary", sa.Text(), nullable=False),
        sa.Column("rationale", sa.Text(), nullable=False),
        sa.Column("action_items", sa.JSON(), nullable=False),
        sa.Column("evidence", sa.JSON(), nullable=False),
        sa.Column("assumptions", sa.JSON(), nullable=False),
        sa.Column("confidence", sa.Float(), nullable=False),
        sa.Column("priority", sa.String(30), nullable=False),
        sa.Column("financial_impact", sa.Float(), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("generated_by", sa.String(120), nullable=False),
        sa.Column("generated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("reviewed_by", sa.String(80), nullable=True),
        sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_atlas_ai_recommendations_company", "atlas_ai_recommendations", ["company_id"])
    op.create_index("ix_atlas_ai_recommendations_farm", "atlas_ai_recommendations", ["farm_id"])
    op.create_index("ix_atlas_ai_recommendations_area", "atlas_ai_recommendations", ["area"])
    op.create_index("ix_atlas_ai_recommendations_status", "atlas_ai_recommendations", ["status"])

    op.create_table(
        "atlas_ai_executions",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("area", sa.String(80), nullable=False),
        sa.Column("engine_version", sa.String(60), nullable=False),
        sa.Column("input_payload", sa.JSON(), nullable=False),
        sa.Column("output_payload", sa.JSON(), nullable=False),
        sa.Column("confidence", sa.Float(), nullable=False),
        sa.Column("duration_ms", sa.Integer(), nullable=False),
        sa.Column("success", sa.Boolean(), nullable=False),
        sa.Column("error_message", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_atlas_ai_executions_company", "atlas_ai_executions", ["company_id"])
    op.create_index("ix_atlas_ai_executions_area", "atlas_ai_executions", ["area"])


def downgrade() -> None:
    op.drop_table("atlas_ai_executions")
    op.drop_table("atlas_ai_recommendations")
    op.drop_table("atlas_ai_messages")
    op.drop_table("atlas_ai_conversations")
