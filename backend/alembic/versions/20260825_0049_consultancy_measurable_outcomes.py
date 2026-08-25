"""consultancy measurable outcomes

Revision ID: 20260825_0049
Revises: 20260824_0048
"""
from alembic import op
import sqlalchemy as sa

revision = "20260825_0049"
down_revision = "20260824_0048"
branch_labels = None
depends_on = None

def upgrade() -> None:
    op.add_column("atlas_action_plan_items", sa.Column("source_entity_type", sa.String(length=80), nullable=False, server_default=""))
    op.add_column("atlas_action_plan_items", sa.Column("source_entity_id", sa.String(length=120), nullable=False, server_default=""))
    op.add_column("atlas_action_plan_items", sa.Column("baseline_metrics_json", sa.JSON(), nullable=False, server_default=sa.text("'{}'::json")))
    op.add_column("atlas_action_plan_items", sa.Column("outcome_metrics_json", sa.JSON(), nullable=False, server_default=sa.text("'{}'::json")))
    op.add_column("atlas_action_plan_items", sa.Column("outcome_status", sa.String(length=30), nullable=False, server_default="pending"))
    op.add_column("atlas_action_plan_items", sa.Column("outcome_measured_at", sa.DateTime(timezone=True), nullable=True))
    op.create_index("ix_atlas_action_plan_items_source_entity_type", "atlas_action_plan_items", ["source_entity_type"], unique=False)
    op.create_index("ix_atlas_action_plan_items_source_entity_id", "atlas_action_plan_items", ["source_entity_id"], unique=False)
    op.create_index("ix_atlas_action_plan_items_outcome_status", "atlas_action_plan_items", ["outcome_status"], unique=False)

def downgrade() -> None:
    op.drop_index("ix_atlas_action_plan_items_outcome_status", table_name="atlas_action_plan_items")
    op.drop_index("ix_atlas_action_plan_items_source_entity_id", table_name="atlas_action_plan_items")
    op.drop_index("ix_atlas_action_plan_items_source_entity_type", table_name="atlas_action_plan_items")
    op.drop_column("atlas_action_plan_items", "outcome_measured_at")
    op.drop_column("atlas_action_plan_items", "outcome_status")
    op.drop_column("atlas_action_plan_items", "outcome_metrics_json")
    op.drop_column("atlas_action_plan_items", "baseline_metrics_json")
    op.drop_column("atlas_action_plan_items", "source_entity_id")
    op.drop_column("atlas_action_plan_items", "source_entity_type")
