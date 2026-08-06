"""Fase 2: nutricao e estoque integrados.

Revision ID: 20260806_0021
Revises: 20260806_0020
"""
from alembic import op
import sqlalchemy as sa

revision = "20260806_0021"
down_revision = "20260806_0020"
branch_labels = None
depends_on = None

def upgrade():
    with op.batch_alter_table("inventory_products") as b:
        b.add_column(sa.Column("maximum_quantity", sa.Float(), nullable=False, server_default="0"))
        b.add_column(sa.Column("last_purchase_cost", sa.Float(), nullable=False, server_default="0"))
        b.add_column(sa.Column("manufacturing_date", sa.DateTime(timezone=True), nullable=True))
        b.add_column(sa.Column("batch_number", sa.String(120), nullable=False, server_default=""))
        b.add_column(sa.Column("supplier", sa.String(180), nullable=False, server_default=""))
        b.add_column(sa.Column("storage_location", sa.String(180), nullable=False, server_default=""))
        b.add_column(sa.Column("active_ingredient", sa.String(180), nullable=False, server_default=""))
        b.add_column(sa.Column("barcode", sa.String(120), nullable=False, server_default=""))
        b.add_column(sa.Column("notes", sa.Text(), nullable=False, server_default=""))
    with op.batch_alter_table("inventory_movements") as b:
        b.add_column(sa.Column("balance_after", sa.Float(), nullable=False, server_default="0"))
        b.add_column(sa.Column("reason", sa.String(255), nullable=False, server_default=""))
        b.add_column(sa.Column("document_number", sa.String(120), nullable=False, server_default=""))
        b.add_column(sa.Column("product_batch", sa.String(120), nullable=False, server_default=""))
    op.create_table("nutrition_ingredients",
        sa.Column("id",sa.String(80),primary_key=True),sa.Column("tenant_id",sa.String(80),nullable=False,index=True),
        sa.Column("company_id",sa.String(80),nullable=False,index=True),sa.Column("farm_id",sa.String(80),nullable=False,index=True),
        sa.Column("inventory_product_id",sa.String(80),sa.ForeignKey("inventory_products.id",ondelete="SET NULL"),nullable=True,index=True),
        sa.Column("name",sa.String(180),nullable=False),sa.Column("category",sa.String(100),nullable=False,server_default="other"),
        sa.Column("unit",sa.String(40),nullable=False,server_default="kg"),sa.Column("dry_matter_percent",sa.Float(),nullable=False,server_default="0"),
        sa.Column("crude_protein_percent",sa.Float(),nullable=False,server_default="0"),sa.Column("ndf_percent",sa.Float(),nullable=False,server_default="0"),
        sa.Column("adf_percent",sa.Float(),nullable=False,server_default="0"),sa.Column("tdn_percent",sa.Float(),nullable=False,server_default="0"),
        sa.Column("cost_per_kg",sa.Float(),nullable=False,server_default="0"),sa.Column("active",sa.Boolean(),nullable=False,server_default=sa.true()),
        sa.Column("notes",sa.Text(),nullable=False,server_default=""),sa.Column("created_at",sa.DateTime(timezone=True),nullable=False),
        sa.UniqueConstraint("company_id","farm_id","name",name="uq_nutrition_ingredient_farm_name"))
    op.create_table("nutrition_plans",
        sa.Column("id",sa.String(80),primary_key=True),sa.Column("tenant_id",sa.String(80),nullable=False,index=True),
        sa.Column("company_id",sa.String(80),nullable=False,index=True),sa.Column("farm_id",sa.String(80),nullable=False,index=True),
        sa.Column("lot_id",sa.String(80),sa.ForeignKey("herd_lots.id",ondelete="CASCADE"),nullable=False,index=True),
        sa.Column("name",sa.String(180),nullable=False),sa.Column("category",sa.String(100),nullable=False,server_default=""),
        sa.Column("start_date",sa.DateTime(timezone=True),nullable=False),sa.Column("end_date",sa.DateTime(timezone=True),nullable=True),
        sa.Column("daily_amount_per_animal_kg",sa.Float(),nullable=False,server_default="0"),sa.Column("animal_count",sa.Integer(),nullable=False,server_default="0"),
        sa.Column("average_body_weight_kg",sa.Float(),nullable=False,server_default="0"),sa.Column("target_daily_gain_kg",sa.Float(),nullable=False,server_default="0"),
        sa.Column("dry_matter_percent",sa.Float(),nullable=False,server_default="0"),sa.Column("crude_protein_percent",sa.Float(),nullable=False,server_default="0"),
        sa.Column("ndf_percent",sa.Float(),nullable=False,server_default="0"),sa.Column("tdn_percent",sa.Float(),nullable=False,server_default="0"),
        sa.Column("cost_per_kg",sa.Float(),nullable=False,server_default="0"),sa.Column("ingredients_json",sa.JSON(),nullable=False),
        sa.Column("active",sa.Boolean(),nullable=False,server_default=sa.true()),sa.Column("notes",sa.Text(),nullable=False,server_default=""),
        sa.Column("created_at",sa.DateTime(timezone=True),nullable=False),sa.Column("created_by",sa.String(80),nullable=False))
    with op.batch_alter_table("nutrition_events") as b:
        b.add_column(sa.Column("nutrition_plan_id",sa.String(80),nullable=True))
        b.add_column(sa.Column("planned_quantity",sa.Float(),nullable=False,server_default="0"))
        b.add_column(sa.Column("observed_daily_gain_kg",sa.Float(),nullable=False,server_default="0"))
        b.add_column(sa.Column("feed_conversion",sa.Float(),nullable=False,server_default="0"))
        b.create_foreign_key("fk_nutrition_event_plan","nutrition_plans",["nutrition_plan_id"],["id"],ondelete="SET NULL")

def downgrade():
    with op.batch_alter_table("nutrition_events") as b:
        b.drop_constraint("fk_nutrition_event_plan",type_="foreignkey"); b.drop_column("feed_conversion"); b.drop_column("observed_daily_gain_kg"); b.drop_column("planned_quantity"); b.drop_column("nutrition_plan_id")
    op.drop_table("nutrition_plans"); op.drop_table("nutrition_ingredients")
    with op.batch_alter_table("inventory_movements") as b:
        for c in ["product_batch","document_number","reason","balance_after"]: b.drop_column(c)
    with op.batch_alter_table("inventory_products") as b:
        for c in ["notes","barcode","active_ingredient","storage_location","supplier","batch_number","manufacturing_date","last_purchase_cost","maximum_quantity"]: b.drop_column(c)
