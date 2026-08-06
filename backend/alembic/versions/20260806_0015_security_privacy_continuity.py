
"""security privacy and continuity

Revision ID: 20260806_0015
Revises: 20260806_0014
"""
from alembic import op
import sqlalchemy as sa

revision = "20260806_0015"
down_revision = "20260806_0014"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "security_policies",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("code", sa.String(100), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("policy_type", sa.String(80), nullable=False),
        sa.Column("rules", sa.JSON(), nullable=False),
        sa.Column("enforcement_mode", sa.String(30), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "code", name="uq_security_policy_code"),
    )

    op.create_table(
        "access_reviews",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("review_type", sa.String(60), nullable=False),
        sa.Column("subject_user_id", sa.String(80), nullable=False),
        sa.Column("reviewer_user_id", sa.String(80), nullable=True),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("permissions_snapshot", sa.JSON(), nullable=False),
        sa.Column("findings", sa.JSON(), nullable=False),
        sa.Column("decision", sa.String(30), nullable=False),
        sa.Column("due_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "privacy_consents",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("data_subject_type", sa.String(60), nullable=False),
        sa.Column("data_subject_id", sa.String(120), nullable=False),
        sa.Column("purpose", sa.String(180), nullable=False),
        sa.Column("legal_basis", sa.String(120), nullable=False),
        sa.Column("granted", sa.Boolean(), nullable=False),
        sa.Column("granted_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("evidence", sa.JSON(), nullable=False),
    )

    op.create_table(
        "privacy_requests",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("request_type", sa.String(60), nullable=False),
        sa.Column("data_subject_type", sa.String(60), nullable=False),
        sa.Column("data_subject_id", sa.String(120), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("requested_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("due_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("response_summary", sa.Text(), nullable=False),
    )

    op.create_table(
        "security_risks",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("title", sa.String(220), nullable=False),
        sa.Column("category", sa.String(80), nullable=False),
        sa.Column("likelihood", sa.Float(), nullable=False),
        sa.Column("impact", sa.Float(), nullable=False),
        sa.Column("score", sa.Float(), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("treatment", sa.Text(), nullable=False),
        sa.Column("owner_user_id", sa.String(80), nullable=True),
        sa.Column("due_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "business_continuity_plans",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("scenario", sa.String(120), nullable=False),
        sa.Column("critical_services", sa.JSON(), nullable=False),
        sa.Column("recovery_steps", sa.JSON(), nullable=False),
        sa.Column("rto_minutes", sa.Integer(), nullable=False),
        sa.Column("rpo_minutes", sa.Integer(), nullable=False),
        sa.Column("owner_user_id", sa.String(80), nullable=True),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("last_tested_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "continuity_exercises",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("plan_id", sa.String(80), sa.ForeignKey("business_continuity_plans.id", ondelete="CASCADE"), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("actual_rto_minutes", sa.Integer(), nullable=True),
        sa.Column("actual_rpo_minutes", sa.Integer(), nullable=True),
        sa.Column("findings", sa.JSON(), nullable=False),
        sa.Column("result", sa.String(30), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "security_posture_snapshots",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("posture_score", sa.Float(), nullable=False),
        sa.Column("active_policies", sa.Integer(), nullable=False),
        sa.Column("open_risks", sa.Integer(), nullable=False),
        sa.Column("overdue_reviews", sa.Integer(), nullable=False),
        sa.Column("open_privacy_requests", sa.Integer(), nullable=False),
        sa.Column("untested_continuity_plans", sa.Integer(), nullable=False),
        sa.Column("findings", sa.JSON(), nullable=False),
        sa.Column("generated_at", sa.DateTime(timezone=True), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("security_posture_snapshots")
    op.drop_table("continuity_exercises")
    op.drop_table("business_continuity_plans")
    op.drop_table("security_risks")
    op.drop_table("privacy_requests")
    op.drop_table("privacy_consents")
    op.drop_table("access_reviews")
    op.drop_table("security_policies")
