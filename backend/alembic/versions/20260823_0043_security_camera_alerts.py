"""Security camera events with durable WhatsApp alert status.

Revision ID: 20260823_0043
Revises: 20260822_0042
"""
from alembic import op
import sqlalchemy as sa


revision = "20260823_0043"
down_revision = "20260822_0042"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "security_camera_events",
        sa.Column("id", sa.String(length=80), nullable=False),
        sa.Column("tenant_id", sa.String(length=80), nullable=False),
        sa.Column("company_id", sa.String(length=80), nullable=False),
        sa.Column("farm_id", sa.String(length=80), nullable=False),
        sa.Column("device_id", sa.String(length=80), nullable=False),
        sa.Column("event_external_id", sa.String(length=180), nullable=False),
        sa.Column("event_type", sa.String(length=30), nullable=False),
        sa.Column("confidence", sa.Float(), nullable=True),
        sa.Column("captured_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("received_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("storage_key", sa.String(length=900), nullable=False),
        sa.Column("sha256", sa.String(length=64), nullable=False),
        sa.Column("file_size", sa.Integer(), nullable=False),
        sa.Column("recipient_whatsapp", sa.String(length=30), nullable=False),
        sa.Column("alert_status", sa.String(length=40), nullable=False),
        sa.Column("provider_message_id", sa.String(length=180), nullable=False),
        sa.Column("attempt_count", sa.Integer(), nullable=False),
        sa.Column("last_attempt_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sent_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("error_message", sa.Text(), nullable=False),
        sa.Column("metadata_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["device_id"],
            ["atlas_iot_devices_v2.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "device_id",
            "event_external_id",
            name="uq_security_camera_event_device_external",
        ),
    )

    for column in (
        "tenant_id",
        "company_id",
        "farm_id",
        "device_id",
        "event_type",
        "captured_at",
        "received_at",
        "alert_status",
        "provider_message_id",
        "created_at",
    ):
        op.create_index(
            f"ix_security_camera_events_{column}",
            "security_camera_events",
            [column],
        )


def downgrade() -> None:
    op.drop_table("security_camera_events")
