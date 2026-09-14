"""Link operational notes to their originating intelligence decision.

Revision ID: 20260914_0054
Revises: 20260908_0053
"""

from alembic import op
import sqlalchemy as sa


revision = "20260914_0054"
down_revision = "20260908_0053"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "operational_notes",
        sa.Column("reference_type", sa.String(length=40), nullable=False, server_default=""),
    )
    op.add_column(
        "operational_notes",
        sa.Column("reference_id", sa.String(length=120), nullable=False, server_default=""),
    )
    op.create_index("ix_operational_notes_reference_type", "operational_notes", ["reference_type"])
    op.create_index("ix_operational_notes_reference_id", "operational_notes", ["reference_id"])


def downgrade() -> None:
    op.drop_index("ix_operational_notes_reference_id", table_name="operational_notes")
    op.drop_index("ix_operational_notes_reference_type", table_name="operational_notes")
    op.drop_column("operational_notes", "reference_id")
    op.drop_column("operational_notes", "reference_type")
