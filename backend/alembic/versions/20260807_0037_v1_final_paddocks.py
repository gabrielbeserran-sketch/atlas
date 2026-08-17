"""V1 final paddocks
Revision ID: 20260807_0037
Revises: 20260806_0036
"""
from alembic import op
import sqlalchemy as sa
revision="20260807_0037"
down_revision="20260806_0036"
branch_labels=None
depends_on=None

def upgrade():
    bind=op.get_bind()
    inspector=sa.inspect(bind)
    if "paddocks" not in inspector.get_table_names():
        op.create_table(
            "paddocks",
            sa.Column("id",sa.String(80),primary_key=True),
            sa.Column("tenant_id",sa.String(80),nullable=False,index=True),
            sa.Column("company_id",sa.String(80),sa.ForeignKey("companies.id",ondelete="CASCADE"),nullable=False,index=True),
            sa.Column("farm_id",sa.String(80),sa.ForeignKey("farms.id",ondelete="CASCADE"),nullable=False,index=True),
            sa.Column("name",sa.String(180),nullable=False),
            sa.Column("area",sa.Float(),nullable=False,server_default="0"),
            sa.Column("status",sa.String(60),nullable=False,server_default="Descanso"),
            sa.Column("animals",sa.Integer(),nullable=False,server_default="0"),
            sa.Column("notes",sa.Text(),nullable=False,server_default=""),
            sa.Column("active",sa.Boolean(),nullable=False,server_default=sa.true()),
            sa.Column("created_at",sa.DateTime(timezone=True),nullable=False),
            sa.Column("updated_at",sa.DateTime(timezone=True),nullable=False),
            sa.UniqueConstraint("company_id","farm_id","name",name="uq_paddock_company_farm_name"),
        )

def downgrade():
    bind=op.get_bind()
    if "paddocks" in sa.inspect(bind).get_table_names():
        op.drop_table("paddocks")
