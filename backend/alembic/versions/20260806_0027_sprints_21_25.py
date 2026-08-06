"""Sprints 21 to 25 domain architecture and operational intelligence.

Revision ID: 20260806_0027
Revises: 20260806_0026
"""
from alembic import op
import sqlalchemy as sa

revision = "20260806_0027"
down_revision = "20260806_0026"
branch_labels = None
depends_on = None

COMMON=[sa.Column("company_id",sa.String(64),nullable=False,index=True),sa.Column("tenant_id",sa.String(64),nullable=False,index=True),sa.Column("farm_id",sa.String(64),nullable=False,index=True),sa.Column("created_at",sa.DateTime(timezone=True),nullable=False),sa.Column("updated_at",sa.DateTime(timezone=True),nullable=False)]
def upgrade():
    op.create_table("precision_assessments",sa.Column("id",sa.String(64),primary_key=True),*COMMON,sa.Column("assessment_type",sa.String(48),nullable=False),sa.Column("lot_id",sa.String(64)),sa.Column("animal_id",sa.String(64)),sa.Column("score",sa.Float(),nullable=False),sa.Column("confidence_percent",sa.Float(),nullable=False),sa.Column("metrics_json",sa.JSON(),nullable=False),sa.Column("evidence_json",sa.JSON(),nullable=False),sa.Column("recommendation",sa.Text(),nullable=False))
    op.create_table("reproduction_protocol_templates_v2",sa.Column("id",sa.String(64),primary_key=True),*COMMON,sa.Column("name",sa.String(180),nullable=False),sa.Column("protocol_type",sa.String(48),nullable=False),sa.Column("steps_json",sa.JSON(),nullable=False),sa.Column("active",sa.Boolean(),nullable=False))
    op.create_table("breeding_seasons",sa.Column("id",sa.String(64),primary_key=True),*COMMON,sa.Column("name",sa.String(180),nullable=False),sa.Column("starts_at",sa.DateTime(timezone=True),nullable=False),sa.Column("ends_at",sa.DateTime(timezone=True),nullable=False),sa.Column("target_pregnancy_rate",sa.Float(),nullable=False),sa.Column("status",sa.String(32),nullable=False),sa.Column("settings_json",sa.JSON(),nullable=False))
    op.create_table("medicine_library_items",sa.Column("id",sa.String(64),primary_key=True),*COMMON,sa.Column("name",sa.String(180),nullable=False),sa.Column("active_ingredient",sa.String(180),nullable=False),sa.Column("dosage_guidance",sa.Text(),nullable=False),sa.Column("meat_withdrawal_days",sa.Integer(),nullable=False),sa.Column("milk_withdrawal_days",sa.Integer(),nullable=False),sa.Column("inventory_product_id",sa.String(64)),sa.Column("metadata_json",sa.JSON(),nullable=False))
    op.create_table("epidemiological_occurrences",sa.Column("id",sa.String(64),primary_key=True),*COMMON,sa.Column("disease_code",sa.String(80),nullable=False),sa.Column("lot_id",sa.String(64)),sa.Column("animal_id",sa.String(64)),sa.Column("severity",sa.String(24),nullable=False),sa.Column("occurred_at",sa.DateTime(timezone=True),nullable=False),sa.Column("latitude",sa.Float()),sa.Column("longitude",sa.Float()),sa.Column("details_json",sa.JSON(),nullable=False))
    op.create_table("nutrition_simulations",sa.Column("id",sa.String(64),primary_key=True),*COMMON,sa.Column("lot_id",sa.String(64),nullable=False),sa.Column("name",sa.String(180),nullable=False),sa.Column("ingredients_json",sa.JSON(),nullable=False),sa.Column("targets_json",sa.JSON(),nullable=False),sa.Column("results_json",sa.JSON(),nullable=False),sa.Column("daily_cost",sa.Float(),nullable=False),sa.Column("projected_gain_kg_day",sa.Float(),nullable=False))
    op.create_table("operational_work_orders",sa.Column("id",sa.String(64),primary_key=True),*COMMON,sa.Column("title",sa.String(180),nullable=False),sa.Column("area",sa.String(64),nullable=False),sa.Column("assigned_user_id",sa.String(64)),sa.Column("priority",sa.String(24),nullable=False),sa.Column("status",sa.String(24),nullable=False),sa.Column("scheduled_at",sa.DateTime(timezone=True)),sa.Column("completed_at",sa.DateTime(timezone=True)),sa.Column("estimated_cost",sa.Float(),nullable=False),sa.Column("actual_cost",sa.Float(),nullable=False),sa.Column("checklist_json",sa.JSON(),nullable=False),sa.Column("notes",sa.Text(),nullable=False))
    op.create_table("farm_assets",sa.Column("id",sa.String(64),primary_key=True),*COMMON,sa.Column("name",sa.String(180),nullable=False),sa.Column("asset_type",sa.String(48),nullable=False),sa.Column("identifier",sa.String(120),nullable=False),sa.Column("status",sa.String(24),nullable=False),sa.Column("hour_meter",sa.Float(),nullable=False),sa.Column("next_maintenance_at",sa.DateTime(timezone=True)),sa.Column("metadata_json",sa.JSON(),nullable=False))
def downgrade():
    for name in ["farm_assets","operational_work_orders","nutrition_simulations","epidemiological_occurrences","medicine_library_items","breeding_seasons","reproduction_protocol_templates_v2","precision_assessments"]: op.drop_table(name)
