
"""release engineering and production readiness

Revision ID: 20260806_0016
Revises: 20260806_0015
"""
from alembic import op
import sqlalchemy as sa

revision = "20260806_0016"
down_revision = "20260806_0015"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "release_pipelines",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("code", sa.String(100), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("stages", sa.JSON(), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "code", name="uq_release_pipeline_code"),
    )

    op.create_table(
        "release_builds",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("pipeline_id", sa.String(80), sa.ForeignKey("release_pipelines.id", ondelete="CASCADE"), nullable=False),
        sa.Column("version", sa.String(80), nullable=False),
        sa.Column("commit_sha", sa.String(80), nullable=False),
        sa.Column("branch", sa.String(120), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("artifacts", sa.JSON(), nullable=False),
        sa.Column("test_summary", sa.JSON(), nullable=False),
        sa.Column("created_by", sa.String(80), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "deployment_environments",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("code", sa.String(80), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("environment_type", sa.String(40), nullable=False),
        sa.Column("base_url", sa.String(500), nullable=False),
        sa.Column("configuration", sa.JSON(), nullable=False),
        sa.Column("protected", sa.Boolean(), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "code", name="uq_deployment_environment_code"),
    )

    op.create_table(
        "deployment_releases",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("build_id", sa.String(80), sa.ForeignKey("release_builds.id", ondelete="CASCADE"), nullable=False),
        sa.Column("environment_id", sa.String(80), sa.ForeignKey("deployment_environments.id", ondelete="CASCADE"), nullable=False),
        sa.Column("strategy", sa.String(40), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("approval_status", sa.String(30), nullable=False),
        sa.Column("approved_by", sa.String(80), nullable=True),
        sa.Column("health_checks", sa.JSON(), nullable=False),
        sa.Column("rollback_build_id", sa.String(80), nullable=True),
        sa.Column("deployed_by", sa.String(80), nullable=False),
        sa.Column("deployed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "feature_flags",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("key", sa.String(160), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("enabled", sa.Boolean(), nullable=False),
        sa.Column("rollout_percent", sa.Float(), nullable=False),
        sa.Column("targeting_rules", sa.JSON(), nullable=False),
        sa.Column("environments", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "key", name="uq_feature_flag_key"),
    )

    op.create_table(
        "change_approvals",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("change_type", sa.String(60), nullable=False),
        sa.Column("reference_id", sa.String(100), nullable=False),
        sa.Column("title", sa.String(220), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("risk_level", sa.String(30), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("requested_by", sa.String(80), nullable=False),
        sa.Column("approved_by", sa.String(80), nullable=True),
        sa.Column("requested_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("decided_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("decision_notes", sa.Text(), nullable=False),
    )

    op.create_table(
        "production_readiness_checks",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("release_id", sa.String(80), sa.ForeignKey("deployment_releases.id", ondelete="CASCADE"), nullable=True),
        sa.Column("check_type", sa.String(80), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("required", sa.Boolean(), nullable=False),
        sa.Column("evidence", sa.JSON(), nullable=False),
        sa.Column("findings", sa.JSON(), nullable=False),
        sa.Column("checked_by", sa.String(80), nullable=True),
        sa.Column("checked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "release_metric_snapshots",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("environment_id", sa.String(80), sa.ForeignKey("deployment_environments.id", ondelete="SET NULL"), nullable=True),
        sa.Column("deployment_frequency", sa.Float(), nullable=False),
        sa.Column("lead_time_hours", sa.Float(), nullable=False),
        sa.Column("change_failure_rate_percent", sa.Float(), nullable=False),
        sa.Column("mean_time_to_recovery_minutes", sa.Float(), nullable=False),
        sa.Column("successful_deployments", sa.Integer(), nullable=False),
        sa.Column("failed_deployments", sa.Integer(), nullable=False),
        sa.Column("generated_at", sa.DateTime(timezone=True), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("release_metric_snapshots")
    op.drop_table("production_readiness_checks")
    op.drop_table("change_approvals")
    op.drop_table("feature_flags")
    op.drop_table("deployment_releases")
    op.drop_table("deployment_environments")
    op.drop_table("release_builds")
    op.drop_table("release_pipelines")
