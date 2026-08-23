"""Monthly bulletins and durable WhatsApp outbox.

Revision ID: 20260822_0042
Revises: 20260821_0041
"""
from alembic import op
import sqlalchemy as sa


revision = "20260822_0042"
down_revision = "20260821_0041"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "bulletin_schedules",
        sa.Column("id", sa.String(length=80), nullable=False),
        sa.Column("tenant_id", sa.String(length=80), nullable=False),
        sa.Column("company_id", sa.String(length=80), nullable=False),
        sa.Column("farm_id", sa.String(length=80), nullable=False),
        sa.Column("bulletin_type", sa.String(length=40), nullable=False),
        sa.Column("recipient_whatsapp", sa.String(length=30), nullable=False),
        sa.Column("whatsapp_opt_in_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("enabled", sa.Boolean(), nullable=False),
        sa.Column("day_of_month", sa.Integer(), nullable=False),
        sa.Column("hour", sa.Integer(), nullable=False),
        sa.Column("minute", sa.Integer(), nullable=False),
        sa.Column("timezone_name", sa.String(length=80), nullable=False),
        sa.Column("last_run_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("next_run_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["farm_id"], ["farms.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "company_id",
            "farm_id",
            "bulletin_type",
            name="uq_bulletin_schedule_company_farm_type",
        ),
    )
    op.create_index(
        "ix_bulletin_schedules_tenant_id",
        "bulletin_schedules",
        ["tenant_id"],
    )
    op.create_index(
        "ix_bulletin_schedules_company_id",
        "bulletin_schedules",
        ["company_id"],
    )
    op.create_index(
        "ix_bulletin_schedules_farm_id",
        "bulletin_schedules",
        ["farm_id"],
    )
    op.create_index(
        "ix_bulletin_schedules_bulletin_type",
        "bulletin_schedules",
        ["bulletin_type"],
    )
    op.create_index(
        "ix_bulletin_schedules_enabled",
        "bulletin_schedules",
        ["enabled"],
    )
    op.create_index(
        "ix_bulletin_schedules_next_run_at",
        "bulletin_schedules",
        ["next_run_at"],
    )

    op.create_table(
        "bulletin_dispatches",
        sa.Column("id", sa.String(length=80), nullable=False),
        sa.Column("tenant_id", sa.String(length=80), nullable=False),
        sa.Column("company_id", sa.String(length=80), nullable=False),
        sa.Column("farm_id", sa.String(length=80), nullable=False),
        sa.Column("schedule_id", sa.String(length=80), nullable=True),
        sa.Column("bulletin_type", sa.String(length=40), nullable=False),
        sa.Column("recipient_whatsapp", sa.String(length=30), nullable=False),
        sa.Column("period_start", sa.DateTime(timezone=True), nullable=False),
        sa.Column("period_end", sa.DateTime(timezone=True), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("status", sa.String(length=40), nullable=False),
        sa.Column("provider", sa.String(length=40), nullable=False),
        sa.Column("provider_message_id", sa.String(length=180), nullable=False),
        sa.Column("idempotency_key", sa.String(length=180), nullable=False),
        sa.Column("attempt_count", sa.Integer(), nullable=False),
        sa.Column("scheduled_for", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sent_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_attempt_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("error_message", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["farm_id"], ["farms.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["schedule_id"],
            ["bulletin_schedules.id"],
            ondelete="SET NULL",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "idempotency_key",
            name="uq_bulletin_dispatch_idempotency",
        ),
    )
    for column in (
        "tenant_id",
        "company_id",
        "farm_id",
        "schedule_id",
        "bulletin_type",
        "status",
        "idempotency_key",
        "scheduled_for",
        "created_at",
    ):
        op.create_index(
            f"ix_bulletin_dispatches_{column}",
            "bulletin_dispatches",
            [column],
        )


def downgrade() -> None:
    op.drop_table("bulletin_dispatches")
    op.drop_table("bulletin_schedules")
