from alembic import op
import sqlalchemy as sa

revision = "20260824_0048"
down_revision = "20260824_0047"
branch_labels = None
depends_on = None


def upgrade() -> None:
    json_default = sa.text("'{}'") if op.get_bind().dialect.name == "sqlite" else sa.text("'{}'::json")
    op.add_column(
        "atlas_action_plan_items",
        sa.Column("completed_by_user_id", sa.String(length=80), nullable=True),
    )
    op.add_column(
        "atlas_action_plan_items",
        sa.Column("execution_evidence_json", sa.JSON(), nullable=False, server_default=json_default),
    )
    if op.get_bind().dialect.name == "sqlite":
        with op.batch_alter_table("atlas_action_plan_items") as batch:
            batch.create_foreign_key(
                "fk_atlas_action_completed_by_user",
                "users", ["completed_by_user_id"], ["id"], ondelete="SET NULL",
            )
    else:
        op.create_foreign_key(
            "fk_atlas_action_completed_by_user",
            "atlas_action_plan_items",
            "users",
            ["completed_by_user_id"],
            ["id"],
            ondelete="SET NULL",
        )
    op.create_index(
        "ix_atlas_action_completed_by_user_id",
        "atlas_action_plan_items",
        ["completed_by_user_id"],
    )


def downgrade() -> None:
    op.drop_index("ix_atlas_action_completed_by_user_id", table_name="atlas_action_plan_items")
    op.drop_constraint("fk_atlas_action_completed_by_user", "atlas_action_plan_items", type_="foreignkey")
    op.drop_column("atlas_action_plan_items", "execution_evidence_json")
    op.drop_column("atlas_action_plan_items", "completed_by_user_id")
