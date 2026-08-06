"""farm operational fields

Revision ID: 20260806_0017
Revises: 20260806_0016
"""
from alembic import op
import sqlalchemy as sa

revision = "20260806_0017"
down_revision = "20260806_0016"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "farms",
        sa.Column("animals", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column(
        "farms",
        sa.Column("area", sa.Integer(), nullable=False, server_default="0"),
    )


def downgrade() -> None:
    op.drop_column("farms", "area")
    op.drop_column("farms", "animals")
