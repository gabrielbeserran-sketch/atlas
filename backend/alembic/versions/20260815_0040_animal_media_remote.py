"""Animal media remote authority.

Revision ID: 20260815_0040
Revises: 20260813_0039
"""
from alembic import op
import sqlalchemy as sa


revision = "20260815_0040"
down_revision = "20260813_0039"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "animal_media",
        sa.Column("id", sa.String(length=80), nullable=False),
        sa.Column("tenant_id", sa.String(length=80), nullable=False),
        sa.Column("company_id", sa.String(length=80), nullable=False),
        sa.Column("farm_id", sa.String(length=80), nullable=False),
        sa.Column("animal_id", sa.String(length=80), nullable=False),
        sa.Column("kind", sa.String(length=30), nullable=False),
        sa.Column("original_filename", sa.String(length=255), nullable=False),
        sa.Column("content_type", sa.String(length=160), nullable=False),
        sa.Column("size_bytes", sa.Integer(), nullable=False),
        sa.Column("sha256", sa.String(length=64), nullable=False),
        sa.Column("storage_key", sa.String(length=700), nullable=False),
        sa.Column("metadata_json", sa.JSON(), nullable=False),
        sa.Column("created_by", sa.String(length=80), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["animal_id"], ["livestock_animals.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["company_id"], ["companies.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["farm_id"], ["farms.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "company_id",
            "animal_id",
            "kind",
            "id",
            name="uq_animal_media_company_animal_kind_id",
        ),
    )
    for column in (
        "tenant_id",
        "company_id",
        "farm_id",
        "animal_id",
        "kind",
        "sha256",
        "created_by",
        "created_at",
    ):
        op.create_index(
            f"ix_animal_media_{column}",
            "animal_media",
            [column],
            unique=False,
        )


def downgrade() -> None:
    op.drop_table("animal_media")
