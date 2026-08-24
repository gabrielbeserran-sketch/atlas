"""Add idempotency to consultancy action plans and prepare Agenda integration.

Revision ID: 20260824_0047
Revises: 20260824_0046
"""
from alembic import op
import sqlalchemy as sa


revision = "20260824_0047"
down_revision = "20260824_0046"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "atlas_action_plan_items",
        sa.Column("idempotency_key", sa.String(length=160), nullable=True),
    )
    op.create_index(
        "ix_atlas_action_idempotency_key",
        "atlas_action_plan_items",
        ["idempotency_key"],
        unique=False,
    )
    op.create_unique_constraint(
        "uq_atlas_action_company_farm_idempotency",
        "atlas_action_plan_items",
        ["company_id", "farm_id", "idempotency_key"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "uq_atlas_action_company_farm_idempotency",
        "atlas_action_plan_items",
        type_="unique",
    )
    op.drop_index(
        "ix_atlas_action_idempotency_key",
        table_name="atlas_action_plan_items",
    )
    op.drop_column("atlas_action_plan_items", "idempotency_key")
