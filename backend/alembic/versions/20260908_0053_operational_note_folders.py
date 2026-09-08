"""Organize operational notes in farm-scoped subject folders.

Revision ID: 20260908_0053
Revises: 20260906_0052
"""

from alembic import op
import sqlalchemy as sa

revision = "20260908_0053"
down_revision = "20260906_0052"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "operational_note_folders",
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
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint(
            "company_id", "farm_id", "name", name="uq_operational_note_folder_name"
        ),
    )
    for name, columns in (
        ("ix_operational_note_folders_tenant_id", ["tenant_id"]),
        ("ix_operational_note_folders_company_id", ["company_id"]),
        ("ix_operational_note_folders_farm_id", ["farm_id"]),
        ("ix_operational_note_folders_created_at", ["created_at"]),
    ):
        op.create_index(name, "operational_note_folders", columns)

    op.add_column(
        "operational_notes",
        sa.Column("folder_id", sa.String(length=80), nullable=True),
    )
    op.create_foreign_key(
        "fk_operational_notes_folder_id",
        "operational_notes",
        "operational_note_folders",
        ["folder_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_index("ix_operational_notes_folder_id", "operational_notes", ["folder_id"])


def downgrade() -> None:
    op.drop_index("ix_operational_notes_folder_id", table_name="operational_notes")
    op.drop_constraint("fk_operational_notes_folder_id", "operational_notes", type_="foreignkey")
    op.drop_column("operational_notes", "folder_id")
    op.drop_table("operational_note_folders")
