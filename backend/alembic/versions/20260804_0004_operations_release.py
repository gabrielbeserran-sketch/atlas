
"""operations and release

Revision ID: 20260804_0004
Revises: 20260804_0003
"""
from alembic import op
import sqlalchemy as sa

revision = "20260804_0004"
down_revision = "20260804_0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "operational_alerts",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("alert_type", sa.String(100), nullable=False),
        sa.Column("severity", sa.String(30), nullable=False),
        sa.Column("title", sa.String(220), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("entity_type", sa.String(80), nullable=False),
        sa.Column("entity_id", sa.String(120), nullable=False),
        sa.Column("due_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("generated_by", sa.String(100), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_operational_alerts_company_id", "operational_alerts", ["company_id"])
    op.create_index("ix_operational_alerts_farm_id", "operational_alerts", ["farm_id"])
    op.create_index("ix_operational_alerts_status", "operational_alerts", ["status"])

    op.create_table(
        "operational_tasks",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("source_type", sa.String(80), nullable=False),
        sa.Column("source_id", sa.String(120), nullable=False),
        sa.Column("title", sa.String(220), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("responsible_user_id", sa.String(80), nullable=True),
        sa.Column("priority", sa.String(30), nullable=False),
        sa.Column("due_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("evidence", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_operational_tasks_company_id", "operational_tasks", ["company_id"])
    op.create_index("ix_operational_tasks_farm_id", "operational_tasks", ["farm_id"])
    op.create_index("ix_operational_tasks_status", "operational_tasks", ["status"])

    op.create_table(
        "indicator_snapshots",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("indicator_key", sa.String(120), nullable=False),
        sa.Column("indicator_name", sa.String(180), nullable=False),
        sa.Column("value", sa.Float(), nullable=False),
        sa.Column("unit", sa.String(40), nullable=False),
        sa.Column("formula", sa.Text(), nullable=False),
        sa.Column("source_tables", sa.JSON(), nullable=False),
        sa.Column("period_start", sa.DateTime(timezone=True), nullable=True),
        sa.Column("period_end", sa.DateTime(timezone=True), nullable=True),
        sa.Column("filters", sa.JSON(), nullable=False),
        sa.Column("generated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_indicator_snapshots_company_id", "indicator_snapshots", ["company_id"])
    op.create_index("ix_indicator_snapshots_farm_id", "indicator_snapshots", ["farm_id"])
    op.create_index("ix_indicator_snapshots_indicator_key", "indicator_snapshots", ["indicator_key"])


def downgrade() -> None:
    op.drop_table("indicator_snapshots")
    op.drop_table("operational_tasks")
    op.drop_table("operational_alerts")
