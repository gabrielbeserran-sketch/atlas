
"""real time monitoring

Revision ID: 20260805_0007
Revises: 20260805_0006
"""
from alembic import op
import sqlalchemy as sa

revision = "20260805_0007"
down_revision = "20260805_0006"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "realtime_notifications",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("user_id", sa.String(80), nullable=True),
        sa.Column("channel", sa.String(40), nullable=False),
        sa.Column("category", sa.String(80), nullable=False),
        sa.Column("severity", sa.String(30), nullable=False),
        sa.Column("title", sa.String(220), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("payload", sa.JSON(), nullable=False),
        sa.Column("deduplication_key", sa.String(180), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("read_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("delivered_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_realtime_notifications_company", "realtime_notifications", ["company_id"])
    op.create_index("ix_realtime_notifications_user", "realtime_notifications", ["user_id"])
    op.create_index("ix_realtime_notifications_status", "realtime_notifications", ["status"])

    op.create_table(
        "realtime_events",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("topic", sa.String(120), nullable=False),
        sa.Column("event_type", sa.String(120), nullable=False),
        sa.Column("entity_type", sa.String(100), nullable=False),
        sa.Column("entity_id", sa.String(120), nullable=False),
        sa.Column("payload", sa.JSON(), nullable=False),
        sa.Column("correlation_id", sa.String(120), nullable=False),
        sa.Column("source", sa.String(120), nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_realtime_events_company", "realtime_events", ["company_id"])
    op.create_index("ix_realtime_events_topic", "realtime_events", ["topic"])
    op.create_index("ix_realtime_events_occurred_at", "realtime_events", ["occurred_at"])

    op.create_table(
        "realtime_subscriptions",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("user_id", sa.String(80), nullable=False),
        sa.Column("topic", sa.String(120), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=True),
        sa.Column("enabled", sa.Boolean(), nullable=False),
        sa.Column("minimum_severity", sa.String(30), nullable=False),
        sa.Column("channels", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_realtime_subscriptions_company", "realtime_subscriptions", ["company_id"])
    op.create_index("ix_realtime_subscriptions_user", "realtime_subscriptions", ["user_id"])
    op.create_index("ix_realtime_subscriptions_topic", "realtime_subscriptions", ["topic"])


def downgrade() -> None:
    op.drop_table("realtime_subscriptions")
    op.drop_table("realtime_events")
    op.drop_table("realtime_notifications")
