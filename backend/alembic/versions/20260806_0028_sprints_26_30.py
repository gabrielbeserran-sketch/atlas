"""Sprints 26 to 30 enterprise growth

Revision ID: 20260806_0028
Revises: 20260806_0027
"""
from alembic import op
import sqlalchemy as sa
revision="20260806_0028"
down_revision="20260806_0027"
branch_labels=None
depends_on=None

def scoped_columns():
 return [sa.Column("id",sa.String(64),primary_key=True),sa.Column("company_id",sa.String(64),nullable=False,index=True),sa.Column("tenant_id",sa.String(64),nullable=False,index=True),sa.Column("farm_id",sa.String(64),nullable=True,index=True),sa.Column("created_at",sa.DateTime(timezone=True),nullable=False),sa.Column("updated_at",sa.DateTime(timezone=True),nullable=False)]
def upgrade():
 op.create_table("annual_budgets",*scoped_columns(),sa.Column("year",sa.Integer(),nullable=False),sa.Column("cost_center",sa.String(120),nullable=False),sa.Column("revenue_budget",sa.Float(),nullable=False),sa.Column("expense_budget",sa.Float(),nullable=False),sa.Column("assumptions_json",sa.JSON(),nullable=False))
 op.create_table("inventory_counts",*scoped_columns(),sa.Column("status",sa.String(32),nullable=False),sa.Column("counted_at",sa.DateTime(timezone=True),nullable=False),sa.Column("items_json",sa.JSON(),nullable=False),sa.Column("differences_json",sa.JSON(),nullable=False),sa.Column("notes",sa.Text(),nullable=False))
 op.create_table("ecosystem_partners",*scoped_columns(),sa.Column("partner_type",sa.String(48),nullable=False),sa.Column("name",sa.String(180),nullable=False),sa.Column("document",sa.String(64),nullable=False),sa.Column("email",sa.String(180),nullable=False),sa.Column("phone",sa.String(64),nullable=False),sa.Column("service_regions_json",sa.JSON(),nullable=False),sa.Column("specialties_json",sa.JSON(),nullable=False),sa.Column("verified",sa.Boolean(),nullable=False),sa.Column("active",sa.Boolean(),nullable=False))
 op.create_table("support_conversations",*scoped_columns(),sa.Column("subject",sa.String(220),nullable=False),sa.Column("status",sa.String(32),nullable=False),sa.Column("priority",sa.String(24),nullable=False),sa.Column("participants_json",sa.JSON(),nullable=False),sa.Column("messages_json",sa.JSON(),nullable=False))
 op.create_table("strategic_plans_v2",*scoped_columns(),sa.Column("title",sa.String(220),nullable=False),sa.Column("horizon_days",sa.Integer(),nullable=False),sa.Column("status",sa.String(32),nullable=False),sa.Column("objectives_json",sa.JSON(),nullable=False),sa.Column("kpis_json",sa.JSON(),nullable=False),sa.Column("initiatives_json",sa.JSON(),nullable=False))
 op.create_table("corporate_scenarios",*scoped_columns(),sa.Column("name",sa.String(180),nullable=False),sa.Column("scenario_type",sa.String(48),nullable=False),sa.Column("assumptions_json",sa.JSON(),nullable=False),sa.Column("results_json",sa.JSON(),nullable=False),sa.Column("roi_percent",sa.Float(),nullable=False))
 op.create_table("localization_profiles",*scoped_columns(),sa.Column("locale",sa.String(16),nullable=False),sa.Column("currency",sa.String(8),nullable=False),sa.Column("measurement_system",sa.String(24),nullable=False),sa.Column("timezone_name",sa.String(64),nullable=False),sa.Column("settings_json",sa.JSON(),nullable=False))
 op.create_table("certification_records",*scoped_columns(),sa.Column("certification_type",sa.String(100),nullable=False),sa.Column("issuer",sa.String(180),nullable=False),sa.Column("valid_from",sa.DateTime(timezone=True),nullable=True),sa.Column("valid_until",sa.DateTime(timezone=True),nullable=True),sa.Column("status",sa.String(32),nullable=False),sa.Column("evidence_json",sa.JSON(),nullable=False))
 op.create_table("training_resources",*scoped_columns(),sa.Column("resource_type",sa.String(48),nullable=False),sa.Column("title",sa.String(220),nullable=False),sa.Column("language",sa.String(16),nullable=False),sa.Column("content_uri",sa.Text(),nullable=False),sa.Column("metadata_json",sa.JSON(),nullable=False),sa.Column("published",sa.Boolean(),nullable=False))
def downgrade():
 for table in ["training_resources","certification_records","localization_profiles","corporate_scenarios","strategic_plans_v2","support_conversations","ecosystem_partners","inventory_counts","annual_budgets"]: op.drop_table(table)
