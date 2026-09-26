"""Append-only, retry-safe pasture grazing snapshots."""
from alembic import op
import sqlalchemy as sa

revision = "20260926_0057"
down_revision = "20260923_0056"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "pasture_grazing_bases",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), sa.ForeignKey("companies.id", ondelete="CASCADE"), nullable=False),
        sa.Column("farm_id", sa.String(80), sa.ForeignKey("farms.id", ondelete="CASCADE"), nullable=False),
        sa.Column("client_operation_id", sa.String(180), nullable=False),
        sa.Column("effective_area_ha", sa.Float(), nullable=False),
        sa.Column("grazing_animals", sa.Integer(), nullable=False),
        sa.Column("unique_area_confirmed", sa.Boolean(), nullable=False),
        sa.Column("recorded_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_by", sa.String(80), sa.ForeignKey("users.id"), nullable=False),
        sa.UniqueConstraint("company_id", "client_operation_id", name="uq_grazing_company_operation"),
    )
    for field in ("tenant_id", "company_id", "farm_id"):
        op.create_index(f"ix_pasture_grazing_bases_{field}", "pasture_grazing_bases", [field])


def downgrade() -> None:
    op.drop_table("pasture_grazing_bases")
