"""Store the productive profile chosen for each farm.

Existing properties remain compatible as ``mixed`` until their responsible
user selects a more specific production profile.

Revision ID: 20260915_0055
Revises: 20260914_0054
"""

from alembic import op
import sqlalchemy as sa


revision = "20260915_0055"
down_revision = "20260914_0054"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "farms",
        sa.Column(
            "production_profile",
            sa.String(length=20),
            nullable=False,
            server_default="mixed",
        ),
    )
    op.add_column(
        "farms",
        sa.Column(
            "production_system",
            sa.String(length=60),
            nullable=False,
            server_default="",
        ),
    )


def downgrade() -> None:
    op.drop_column("farms", "production_system")
    op.drop_column("farms", "production_profile")
