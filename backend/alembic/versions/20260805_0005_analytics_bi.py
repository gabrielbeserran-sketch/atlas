
"""analytics and business intelligence

Revision ID: 20260805_0005
Revises: 20260804_0004
"""
from alembic import op
import sqlalchemy as sa

revision = "20260805_0005"
down_revision = "20260804_0004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "analytics_dimension_date",
        sa.Column("id", sa.String(20), primary_key=True),
        sa.Column("full_date", sa.DateTime(timezone=True), nullable=False, unique=True),
        sa.Column("year", sa.Integer(), nullable=False),
        sa.Column("quarter", sa.Integer(), nullable=False),
        sa.Column("month", sa.Integer(), nullable=False),
        sa.Column("month_name", sa.String(30), nullable=False),
        sa.Column("week", sa.Integer(), nullable=False),
        sa.Column("day", sa.Integer(), nullable=False),
        sa.Column("day_of_week", sa.Integer(), nullable=False),
        sa.Column("is_month_end", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.create_index("ix_analytics_dimension_date_full_date", "analytics_dimension_date", ["full_date"])
    op.create_index("ix_analytics_dimension_date_year", "analytics_dimension_date", ["year"])
    op.create_index("ix_analytics_dimension_date_month", "analytics_dimension_date", ["month"])

    op.create_table(
        "analytics_fact_snapshots",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("lot_id", sa.String(80), nullable=True),
        sa.Column("metric_key", sa.String(120), nullable=False),
        sa.Column("metric_name", sa.String(180), nullable=False),
        sa.Column("metric_group", sa.String(80), nullable=False),
        sa.Column("value", sa.Float(), nullable=False),
        sa.Column("unit", sa.String(40), nullable=False),
        sa.Column("period_start", sa.DateTime(timezone=True), nullable=False),
        sa.Column("period_end", sa.DateTime(timezone=True), nullable=False),
        sa.Column("dimensions", sa.JSON(), nullable=False),
        sa.Column("source_tables", sa.JSON(), nullable=False),
        sa.Column("formula", sa.Text(), nullable=False),
        sa.Column("generated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint(
            "company_id",
            "farm_id",
            "metric_key",
            "period_start",
            "period_end",
            name="uq_analytics_fact_period",
        ),
    )
    op.create_index("ix_analytics_fact_company", "analytics_fact_snapshots", ["company_id"])
    op.create_index("ix_analytics_fact_farm", "analytics_fact_snapshots", ["farm_id"])
    op.create_index("ix_analytics_fact_metric", "analytics_fact_snapshots", ["metric_key"])
    op.create_index("ix_analytics_fact_group", "analytics_fact_snapshots", ["metric_group"])
    op.create_index("ix_analytics_fact_period_end", "analytics_fact_snapshots", ["period_end"])

    op.create_table(
        "analytics_kpi_definitions",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("key", sa.String(120), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("metric_group", sa.String(80), nullable=False),
        sa.Column("formula", sa.Text(), nullable=False),
        sa.Column("unit", sa.String(40), nullable=False),
        sa.Column("target_direction", sa.String(30), nullable=False),
        sa.Column("warning_threshold", sa.Float(), nullable=True),
        sa.Column("critical_threshold", sa.Float(), nullable=True),
        sa.Column("weight", sa.Float(), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "key", name="uq_analytics_kpi_company_key"),
    )

    op.create_table(
        "analytics_goals",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("kpi_key", sa.String(120), nullable=False),
        sa.Column("title", sa.String(220), nullable=False),
        sa.Column("baseline_value", sa.Float(), nullable=False),
        sa.Column("target_value", sa.Float(), nullable=False),
        sa.Column("current_value", sa.Float(), nullable=False),
        sa.Column("start_date", sa.DateTime(timezone=True), nullable=False),
        sa.Column("due_date", sa.DateTime(timezone=True), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("responsible_user_id", sa.String(80), nullable=True),
        sa.Column("notes", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_analytics_goals_company", "analytics_goals", ["company_id"])
    op.create_index("ix_analytics_goals_farm", "analytics_goals", ["farm_id"])
    op.create_index("ix_analytics_goals_kpi", "analytics_goals", ["kpi_key"])
    op.create_index("ix_analytics_goals_due", "analytics_goals", ["due_date"])

    op.create_table(
        "analytics_benchmark_snapshots",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=False),
        sa.Column("metric_key", sa.String(120), nullable=False),
        sa.Column("value", sa.Float(), nullable=False),
        sa.Column("percentile", sa.Float(), nullable=False),
        sa.Column("rank_position", sa.Integer(), nullable=False),
        sa.Column("peer_count", sa.Integer(), nullable=False),
        sa.Column("peer_group", sa.String(120), nullable=False),
        sa.Column("period_start", sa.DateTime(timezone=True), nullable=False),
        sa.Column("period_end", sa.DateTime(timezone=True), nullable=False),
        sa.Column("generated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_analytics_benchmark_company", "analytics_benchmark_snapshots", ["company_id"])
    op.create_index("ix_analytics_benchmark_farm", "analytics_benchmark_snapshots", ["farm_id"])
    op.create_index("ix_analytics_benchmark_metric", "analytics_benchmark_snapshots", ["metric_key"])

    op.create_table(
        "analytics_farm_scores",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=False),
        sa.Column("score", sa.Float(), nullable=False),
        sa.Column("grade", sa.String(10), nullable=False),
        sa.Column("component_scores", sa.JSON(), nullable=False),
        sa.Column("explanations", sa.JSON(), nullable=False),
        sa.Column("period_start", sa.DateTime(timezone=True), nullable=False),
        sa.Column("period_end", sa.DateTime(timezone=True), nullable=False),
        sa.Column("generated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_analytics_score_company", "analytics_farm_scores", ["company_id"])
    op.create_index("ix_analytics_score_farm", "analytics_farm_scores", ["farm_id"])


def downgrade() -> None:
    op.drop_table("analytics_farm_scores")
    op.drop_table("analytics_benchmark_snapshots")
    op.drop_table("analytics_goals")
    op.drop_table("analytics_kpi_definitions")
    op.drop_table("analytics_fact_snapshots")
    op.drop_table("analytics_dimension_date")
