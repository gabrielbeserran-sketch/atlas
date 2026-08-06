
"""governance compliance and resilience

Revision ID: 20260806_0013
Revises: 20260806_0012
"""
from alembic import op
import sqlalchemy as sa

revision = "20260806_0013"
down_revision = "20260806_0012"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "data_governance_policies",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("code", sa.String(100), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("resource_type", sa.String(100), nullable=False),
        sa.Column("classification", sa.String(40), nullable=False),
        sa.Column("retention_days", sa.Integer(), nullable=False),
        sa.Column("legal_basis", sa.String(180), nullable=False),
        sa.Column("access_rules", sa.JSON(), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "code", name="uq_data_governance_policy_code"),
    )

    op.create_table(
        "data_catalog_assets",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("asset_key", sa.String(160), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("asset_type", sa.String(60), nullable=False),
        sa.Column("source_system", sa.String(120), nullable=False),
        sa.Column("owner_user_id", sa.String(80), nullable=True),
        sa.Column("steward_user_id", sa.String(80), nullable=True),
        sa.Column("classification", sa.String(40), nullable=False),
        sa.Column("schema_definition", sa.JSON(), nullable=False),
        sa.Column("lineage", sa.JSON(), nullable=False),
        sa.Column("quality_score", sa.Float(), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "asset_key", name="uq_data_catalog_asset_key"),
    )

    op.create_table(
        "data_quality_rules",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("asset_id", sa.String(80), sa.ForeignKey("data_catalog_assets.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("rule_type", sa.String(60), nullable=False),
        sa.Column("field_name", sa.String(120), nullable=False),
        sa.Column("parameters", sa.JSON(), nullable=False),
        sa.Column("severity", sa.String(30), nullable=False),
        sa.Column("enabled", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "data_quality_runs",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("asset_id", sa.String(80), sa.ForeignKey("data_catalog_assets.id", ondelete="CASCADE"), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("score", sa.Float(), nullable=False),
        sa.Column("checks_total", sa.Integer(), nullable=False),
        sa.Column("checks_passed", sa.Integer(), nullable=False),
        sa.Column("checks_failed", sa.Integer(), nullable=False),
        sa.Column("findings", sa.JSON(), nullable=False),
        sa.Column("generated_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "compliance_controls",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("code", sa.String(100), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("framework", sa.String(100), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("evidence_requirements", sa.JSON(), nullable=False),
        sa.Column("owner_user_id", sa.String(80), nullable=True),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("last_reviewed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("next_review_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "code", name="uq_compliance_control_code"),
    )

    op.create_table(
        "compliance_assessments",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("control_id", sa.String(80), sa.ForeignKey("compliance_controls.id", ondelete="CASCADE"), nullable=False),
        sa.Column("result", sa.String(30), nullable=False),
        sa.Column("score", sa.Float(), nullable=False),
        sa.Column("findings", sa.JSON(), nullable=False),
        sa.Column("evidence", sa.JSON(), nullable=False),
        sa.Column("assessed_by", sa.String(80), nullable=False),
        sa.Column("assessed_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "service_health_snapshots",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("service_name", sa.String(120), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("latency_ms", sa.Integer(), nullable=False),
        sa.Column("availability_percent", sa.Float(), nullable=False),
        sa.Column("error_rate_percent", sa.Float(), nullable=False),
        sa.Column("metadata_json", sa.JSON(), nullable=False),
        sa.Column("checked_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "resilience_incidents",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("title", sa.String(220), nullable=False),
        sa.Column("severity", sa.String(30), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("affected_services", sa.JSON(), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("root_cause", sa.Text(), nullable=False),
        sa.Column("mitigation", sa.Text(), nullable=False),
        sa.Column("opened_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_table("resilience_incidents")
    op.drop_table("service_health_snapshots")
    op.drop_table("compliance_assessments")
    op.drop_table("compliance_controls")
    op.drop_table("data_quality_runs")
    op.drop_table("data_quality_rules")
    op.drop_table("data_catalog_assets")
    op.drop_table("data_governance_policies")
