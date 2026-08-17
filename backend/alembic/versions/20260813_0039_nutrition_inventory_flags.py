"""persist nutrition inventory integration state

Revision ID: 20260813_0039
Revises: 20260811_0038
"""
from alembic import op
import sqlalchemy as sa

revision = "20260813_0039"
down_revision = "20260811_0038"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if "nutrition_plans" not in set(inspector.get_table_names()):
        return
    columns = {column["name"] for column in inspector.get_columns("nutrition_plans")}
    if "stock_integration_enabled" not in columns:
        op.add_column("nutrition_plans", sa.Column("stock_integration_enabled", sa.Boolean(), nullable=False, server_default=sa.false()))
    if "inventory_deducted" not in columns:
        op.add_column("nutrition_plans", sa.Column("inventory_deducted", sa.Boolean(), nullable=False, server_default=sa.false()))
    if "inventory_deduction_cost" not in columns:
        op.add_column("nutrition_plans", sa.Column("inventory_deduction_cost", sa.Float(), nullable=False, server_default="0"))


def downgrade() -> None:
    # Campos de estado operacional; não removemos automaticamente para evitar perda de dados.
    pass
