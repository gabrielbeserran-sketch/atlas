"""Durable and idempotent farm handling operations.

Revision ID: 20260824_0045
Revises: 20260823_0044
"""
from alembic import op
import sqlalchemy as sa


revision = "20260824_0045"
down_revision = "20260823_0044"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "farm_handling_operations",
        sa.Column("id", sa.String(length=80), nullable=False),
        sa.Column("tenant_id", sa.String(length=80), nullable=False),
        sa.Column("company_id", sa.String(length=80), nullable=False),
        sa.Column("farm_id", sa.String(length=80), nullable=False),
        sa.Column("idempotency_key", sa.String(length=180), nullable=False),
        sa.Column("action", sa.String(length=60), nullable=False),
        sa.Column("status", sa.String(length=30), nullable=False),
        sa.Column("affected_count", sa.Integer(), nullable=False),
        sa.Column("animal_ids_json", sa.JSON(), nullable=False),
        sa.Column("created_ids_json", sa.JSON(), nullable=False),
        sa.Column("finance_entry_id", sa.String(length=80), nullable=False),
        sa.Column("summary", sa.Text(), nullable=False),
        sa.Column("responsible", sa.String(length=180), nullable=False),
        sa.Column("notes", sa.Text(), nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_by", sa.String(length=80), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["company_id"],
            ["companies.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["farm_id"],
            ["farms.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "company_id",
            "farm_id",
            "idempotency_key",
            name="uq_farm_handling_company_farm_idempotency",
        ),
    )
    for column in (
        "tenant_id",
        "company_id",
        "farm_id",
        "action",
        "status",
        "occurred_at",
        "created_at",
    ):
        op.create_index(
            f"ix_farm_handling_operations_{column}",
            "farm_handling_operations",
            [column],
        )


def downgrade() -> None:
    op.drop_table("farm_handling_operations")
