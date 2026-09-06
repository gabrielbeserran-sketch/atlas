"""Add auditable documents linked to financial entries.

Revision ID: 20260905_0051
Revises: 20260825_0050
"""

from alembic import op
import sqlalchemy as sa

revision = "20260905_0051"
down_revision = "20260825_0050"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "financial_documents",
        sa.Column("id", sa.String(length=80), primary_key=True),
        sa.Column("tenant_id", sa.String(length=80), nullable=False),
        sa.Column("company_id", sa.String(length=80), sa.ForeignKey("companies.id", ondelete="CASCADE"), nullable=False),
        sa.Column("farm_id", sa.String(length=80), sa.ForeignKey("farms.id", ondelete="CASCADE"), nullable=False),
        sa.Column("financial_entry_id", sa.String(length=80), sa.ForeignKey("financial_entries.id", ondelete="CASCADE"), nullable=False),
        sa.Column("original_filename", sa.String(length=255), nullable=False, server_default=""),
        sa.Column("content_type", sa.String(length=160), nullable=False, server_default=""),
        sa.Column("size_bytes", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("sha256", sa.String(length=64), nullable=False, server_default=""),
        sa.Column("storage_key", sa.String(length=700), nullable=False, server_default=""),
        sa.Column("review_status", sa.String(length=30), nullable=False, server_default="pending"),
        sa.Column("extracted_data", sa.JSON(), nullable=False, server_default=sa.text("'{}'")),
        sa.Column("review_notes", sa.Text(), nullable=False, server_default=""),
        sa.Column("created_by", sa.String(length=80), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    for name, columns in (
        ("ix_financial_documents_tenant_id", ["tenant_id"]),
        ("ix_financial_documents_company_id", ["company_id"]),
        ("ix_financial_documents_farm_id", ["farm_id"]),
        ("ix_financial_documents_financial_entry_id", ["financial_entry_id"]),
        ("ix_financial_documents_sha256", ["sha256"]),
        ("ix_financial_documents_review_status", ["review_status"]),
        ("ix_financial_documents_created_by", ["created_by"]),
        ("ix_financial_documents_created_at", ["created_at"]),
    ):
        op.create_index(name, "financial_documents", columns)


def downgrade() -> None:
    op.drop_table("financial_documents")
