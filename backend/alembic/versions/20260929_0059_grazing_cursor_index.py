"""Index the scoped pasture-grazing cursor without changing existing rows.

Revision ID: 20260929_0059
Revises: 20260929_0058
"""

from alembic import op


revision = "20260929_0059"
down_revision = "20260929_0058"
branch_labels = None
depends_on = None

INDEX = "ix_pasture_grazing_scope_created_id"
TABLE = "pasture_grazing_bases"
COLUMNS = ["tenant_id", "company_id", "farm_id", "created_at", "id"]


def upgrade() -> None:
    op.create_index(INDEX, TABLE, COLUMNS)


def downgrade() -> None:
    op.drop_index(INDEX, table_name=TABLE)
