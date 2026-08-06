"""Consolida animais no núcleo livestock e permite SISBOV vazio.

Revision ID: 20260806_0019
Revises: 20260806_0018
"""

from alembic import op

revision = "20260806_0019"
down_revision = "20260806_0018"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("livestock_animals") as batch_op:
        batch_op.drop_constraint(
            "uq_animal_company_sisbov",
            type_="unique",
        )


def downgrade() -> None:
    with op.batch_alter_table("livestock_animals") as batch_op:
        batch_op.create_unique_constraint(
            "uq_animal_company_sisbov",
            ["company_id", "sisbov"],
        )
