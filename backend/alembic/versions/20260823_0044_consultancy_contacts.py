"""Farm-scoped consultancy responsible contact.

Revision ID: 20260823_0044
Revises: 20260823_0043
"""
from alembic import op
import sqlalchemy as sa


revision = "20260823_0044"
down_revision = "20260823_0043"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "consultancy_contacts",
        sa.Column("id", sa.String(length=80), nullable=False),
        sa.Column("tenant_id", sa.String(length=80), nullable=False),
        sa.Column("company_id", sa.String(length=80), nullable=False),
        sa.Column("farm_id", sa.String(length=80), nullable=False),
        sa.Column("display_name", sa.String(length=180), nullable=False),
        sa.Column("role", sa.String(length=120), nullable=False),
        sa.Column("whatsapp_number", sa.String(length=30), nullable=False),
        sa.Column("company_label", sa.String(length=180), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("updated_by", sa.String(length=80), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
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
            name="uq_consultancy_contact_company_farm",
        ),
    )
    for column in ("tenant_id", "company_id", "farm_id", "active"):
        op.create_index(
            f"ix_consultancy_contacts_{column}",
            "consultancy_contacts",
            [column],
        )


def downgrade() -> None:
    op.drop_table("consultancy_contacts")
