"""Adiciona localização/piquete aos lotes do rebanho.

Revision ID: 20260806_0018
Revises: 20260806_0017
"""

from alembic import op
import sqlalchemy as sa

revision = "20260806_0018"
down_revision = "20260806_0017"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "herd_lots",
        sa.Column("paddock", sa.String(length=180), nullable=False, server_default=""),
    )
    op.alter_column("herd_lots", "paddock", server_default=None)


def downgrade() -> None:
    op.drop_column("herd_lots", "paddock")
