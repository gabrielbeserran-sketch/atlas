"""Add farm-scoped operational notes with an auditable author.

Revision ID: 20260906_0052
Revises: 20260905_0051
"""

from alembic import op
import sqlalchemy as sa

revision = "20260906_0052"
down_revision = "20260905_0051"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "operational_notes",
        sa.Column("id", sa.String(length=80), primary_key=True),
        sa.Column("tenant_id", sa.String(length=80), nullable=False),
        sa.Column(
            "company_id",
            sa.String(length=80),
            sa.ForeignKey("companies.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "farm_id",
            sa.String(length=80),
            sa.ForeignKey("farms.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("author_user_id", sa.String(length=80), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("source", sa.String(length=30), nullable=False, server_default="text"),
        sa.Column("transcript", sa.Text(), nullable=False, server_default=""),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    for name, columns in (
        ("ix_operational_notes_tenant_id", ["tenant_id"]),
        ("ix_operational_notes_company_id", ["company_id"]),
        ("ix_operational_notes_farm_id", ["farm_id"]),
        ("ix_operational_notes_author_user_id", ["author_user_id"]),
        ("ix_operational_notes_source", ["source"]),
        ("ix_operational_notes_created_at", ["created_at"]),
    ):
        op.create_index(name, "operational_notes", columns)


def downgrade() -> None:
    op.drop_table("operational_notes")
