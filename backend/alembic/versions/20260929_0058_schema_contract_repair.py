"""Repair additive model/schema drift in AI sessions and nutrition.

Revision ID: 20260929_0058
Revises: 20260926_0057
"""

from alembic import op
import sqlalchemy as sa


revision = "20260929_0058"
down_revision = "20260926_0057"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Conversations antigas continuam em atlas_ai_messages. A sessão Enterprise
    # possui contrato diferente e nunca deve partilhar essa tabela.
    op.create_table(
        "atlas_ai_session_messages",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("session_id", sa.String(80), sa.ForeignKey("atlas_ai_sessions.id", ondelete="CASCADE"), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("role", sa.String(30), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("agent_code", sa.String(80), nullable=False, server_default=""),
        sa.Column("confidence_percent", sa.Float(), nullable=False, server_default="0"),
        sa.Column("sources", sa.JSON(), nullable=False),
        sa.Column("evidence", sa.JSON(), nullable=False),
        sa.Column("limitations", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    for column in ("session_id", "company_id", "role", "created_at"):
        op.create_index(
            f"ix_atlas_ai_session_messages_{column}",
            "atlas_ai_session_messages", [column],
        )

    with op.batch_alter_table("nutrition_events") as batch:
        batch.add_column(sa.Column(
            "amount_per_animal", sa.Float(), nullable=False, server_default="0",
        ))
        batch.add_column(sa.Column(
            "animal_count", sa.Integer(), nullable=False, server_default="0",
        ))
    # O campo antigo é mantido para compatibilidade; não é possível deduzir
    # com segurança a contagem histórica de animais apenas pelo total.
    op.execute(
        "UPDATE nutrition_events SET amount_per_animal = quantity_per_head "
        "WHERE quantity_per_head IS NOT NULL"
    )


def downgrade() -> None:
    with op.batch_alter_table("nutrition_events") as batch:
        batch.drop_column("animal_count")
        batch.drop_column("amount_per_animal")
    op.drop_table("atlas_ai_session_messages")
