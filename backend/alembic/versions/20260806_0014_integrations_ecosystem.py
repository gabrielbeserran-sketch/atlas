
"""integrations webhooks and partner ecosystem

Revision ID: 20260806_0014
Revises: 20260806_0013
"""
from alembic import op
import sqlalchemy as sa

revision = "20260806_0014"
down_revision = "20260806_0013"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "integration_providers",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("code", sa.String(100), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("category", sa.String(80), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("base_url", sa.String(500), nullable=False),
        sa.Column("auth_type", sa.String(40), nullable=False),
        sa.Column("capabilities", sa.JSON(), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "code", name="uq_integration_provider_code"),
    )

    op.create_table(
        "integration_connections",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("provider_id", sa.String(80), sa.ForeignKey("integration_providers.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("credentials_encrypted", sa.Text(), nullable=False),
        sa.Column("configuration", sa.JSON(), nullable=False),
        sa.Column("scopes", sa.JSON(), nullable=False),
        sa.Column("last_sync_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_error", sa.Text(), nullable=False),
        sa.Column("created_by", sa.String(80), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "integration_sync_jobs",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("connection_id", sa.String(80), sa.ForeignKey("integration_connections.id", ondelete="CASCADE"), nullable=False),
        sa.Column("job_type", sa.String(80), nullable=False),
        sa.Column("direction", sa.String(30), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("cursor", sa.String(500), nullable=False),
        sa.Column("records_processed", sa.Integer(), nullable=False),
        sa.Column("records_failed", sa.Integer(), nullable=False),
        sa.Column("payload", sa.JSON(), nullable=False),
        sa.Column("result", sa.JSON(), nullable=False),
        sa.Column("error_message", sa.Text(), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "outbound_webhooks",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("target_url", sa.String(700), nullable=False),
        sa.Column("secret_hash", sa.String(128), nullable=False),
        sa.Column("event_types", sa.JSON(), nullable=False),
        sa.Column("headers", sa.JSON(), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("retry_policy", sa.JSON(), nullable=False),
        sa.Column("created_by", sa.String(80), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "webhook_deliveries",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("webhook_id", sa.String(80), sa.ForeignKey("outbound_webhooks.id", ondelete="CASCADE"), nullable=False),
        sa.Column("event_type", sa.String(120), nullable=False),
        sa.Column("payload", sa.JSON(), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("attempt_count", sa.Integer(), nullable=False),
        sa.Column("response_status", sa.Integer(), nullable=True),
        sa.Column("response_body", sa.Text(), nullable=False),
        sa.Column("error_message", sa.Text(), nullable=False),
        sa.Column("next_attempt_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("delivered_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    op.create_table(
        "partner_applications",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("partner_name", sa.String(180), nullable=False),
        sa.Column("client_id", sa.String(120), nullable=False),
        sa.Column("client_secret_hash", sa.String(128), nullable=False),
        sa.Column("scopes", sa.JSON(), nullable=False),
        sa.Column("allowed_origins", sa.JSON(), nullable=False),
        sa.Column("rate_limit_per_minute", sa.Integer(), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "client_id", name="uq_partner_application_client_id"),
    )

    op.create_table(
        "api_usage_records",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("partner_application_id", sa.String(80), sa.ForeignKey("partner_applications.id", ondelete="SET NULL"), nullable=True),
        sa.Column("endpoint", sa.String(300), nullable=False),
        sa.Column("method", sa.String(20), nullable=False),
        sa.Column("status_code", sa.Integer(), nullable=False),
        sa.Column("duration_ms", sa.Integer(), nullable=False),
        sa.Column("request_units", sa.Integer(), nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("api_usage_records")
    op.drop_table("partner_applications")
    op.drop_table("webhook_deliveries")
    op.drop_table("outbound_webhooks")
    op.drop_table("integration_sync_jobs")
    op.drop_table("integration_connections")
    op.drop_table("integration_providers")
