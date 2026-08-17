"""repair farm schema for existing installations

Revision ID: 20260811_0038
Revises: 20260807_0037
"""
from alembic import op
import sqlalchemy as sa

revision = "20260811_0038"
down_revision = "20260807_0037"
branch_labels = None
depends_on = None

def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    tables = set(inspector.get_table_names())
    if "farms" not in tables:
        return
    columns = {column["name"] for column in inspector.get_columns("farms")}
    if "animals" not in columns:
        op.add_column("farms", sa.Column("animals", sa.Integer(), nullable=False, server_default="0"))
    if "area" not in columns:
        op.add_column("farms", sa.Column("area", sa.Integer(), nullable=False, server_default="0"))

def downgrade() -> None:
    # Migração de reparação: downgrade não remove dados/colunas preexistentes.
    pass
