"""Add a stable client operation id for retry-safe animal weighings.

Revision ID: 20260923_0056
Revises: 20260915_0055
"""

from alembic import op
import sqlalchemy as sa


revision = "20260923_0056"
down_revision = "20260915_0055"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("weight_records") as batch:
        batch.add_column(sa.Column("client_operation_id", sa.String(length=180), nullable=True))
        batch.create_unique_constraint(
            "uq_weight_company_operation", ["company_id", "client_operation_id"]
        )


def downgrade() -> None:
    with op.batch_alter_table("weight_records") as batch:
        batch.drop_constraint("uq_weight_company_operation", type_="unique")
        batch.drop_column("client_operation_id")
