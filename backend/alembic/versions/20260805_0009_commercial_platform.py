
"""commercial platform

Revision ID: 20260805_0009
Revises: 20260805_0008
"""
from alembic import op
import sqlalchemy as sa

revision = "20260805_0009"
down_revision = "20260805_0008"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "commercial_customers",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("document", sa.String(40), nullable=False),
        sa.Column("email", sa.String(180), nullable=False),
        sa.Column("phone", sa.String(40), nullable=False),
        sa.Column("customer_type", sa.String(40), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("source", sa.String(80), nullable=False),
        sa.Column("notes", sa.Text(), nullable=False),
        sa.Column("metadata_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_commercial_customers_company", "commercial_customers", ["company_id"])
    op.create_index("ix_commercial_customers_name", "commercial_customers", ["name"])
    op.create_index("ix_commercial_customers_status", "commercial_customers", ["status"])

    op.create_table(
        "commercial_opportunities",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("customer_id", sa.String(80), sa.ForeignKey("commercial_customers.id", ondelete="CASCADE"), nullable=False),
        sa.Column("title", sa.String(220), nullable=False),
        sa.Column("stage", sa.String(40), nullable=False),
        sa.Column("estimated_value", sa.Float(), nullable=False),
        sa.Column("probability_percent", sa.Float(), nullable=False),
        sa.Column("expected_close_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("responsible_user_id", sa.String(80), nullable=True),
        sa.Column("loss_reason", sa.Text(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_commercial_opportunities_company", "commercial_opportunities", ["company_id"])
    op.create_index("ix_commercial_opportunities_customer", "commercial_opportunities", ["customer_id"])
    op.create_index("ix_commercial_opportunities_stage", "commercial_opportunities", ["stage"])

    op.create_table(
        "commercial_proposals",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("customer_id", sa.String(80), sa.ForeignKey("commercial_customers.id", ondelete="CASCADE"), nullable=False),
        sa.Column("opportunity_id", sa.String(80), sa.ForeignKey("commercial_opportunities.id", ondelete="SET NULL"), nullable=True),
        sa.Column("title", sa.String(220), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("items", sa.JSON(), nullable=False),
        sa.Column("subtotal", sa.Float(), nullable=False),
        sa.Column("discount", sa.Float(), nullable=False),
        sa.Column("total", sa.Float(), nullable=False),
        sa.Column("valid_until", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("created_by", sa.String(80), nullable=False),
        sa.Column("accepted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("rejected_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_commercial_proposals_company", "commercial_proposals", ["company_id"])
    op.create_index("ix_commercial_proposals_customer", "commercial_proposals", ["customer_id"])
    op.create_index("ix_commercial_proposals_status", "commercial_proposals", ["status"])

    op.create_table(
        "commercial_contracts",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("customer_id", sa.String(80), sa.ForeignKey("commercial_customers.id", ondelete="CASCADE"), nullable=False),
        sa.Column("proposal_id", sa.String(80), sa.ForeignKey("commercial_proposals.id", ondelete="SET NULL"), nullable=True),
        sa.Column("title", sa.String(220), nullable=False),
        sa.Column("terms", sa.Text(), nullable=False),
        sa.Column("start_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("end_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("signed_by_customer_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("signed_by_company_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("signature_metadata", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_commercial_contracts_company", "commercial_contracts", ["company_id"])
    op.create_index("ix_commercial_contracts_customer", "commercial_contracts", ["customer_id"])
    op.create_index("ix_commercial_contracts_status", "commercial_contracts", ["status"])

    op.create_table(
        "commercial_plans",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("code", sa.String(80), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("billing_cycle", sa.String(30), nullable=False),
        sa.Column("price", sa.Float(), nullable=False),
        sa.Column("limits", sa.JSON(), nullable=False),
        sa.Column("features", sa.JSON(), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "code", name="uq_commercial_plan_code"),
    )

    op.create_table(
        "commercial_subscriptions",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("customer_id", sa.String(80), sa.ForeignKey("commercial_customers.id", ondelete="CASCADE"), nullable=False),
        sa.Column("plan_id", sa.String(80), sa.ForeignKey("commercial_plans.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("trial_ends_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("renews_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("canceled_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("external_reference", sa.String(120), nullable=False),
        sa.Column("metadata_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_commercial_subscriptions_company", "commercial_subscriptions", ["company_id"])
    op.create_index("ix_commercial_subscriptions_customer", "commercial_subscriptions", ["customer_id"])
    op.create_index("ix_commercial_subscriptions_status", "commercial_subscriptions", ["status"])

    op.create_table(
        "commercial_invoices",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("customer_id", sa.String(80), sa.ForeignKey("commercial_customers.id", ondelete="CASCADE"), nullable=False),
        sa.Column("subscription_id", sa.String(80), sa.ForeignKey("commercial_subscriptions.id", ondelete="SET NULL"), nullable=True),
        sa.Column("reference", sa.String(100), nullable=False),
        sa.Column("amount", sa.Float(), nullable=False),
        sa.Column("due_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("payment_method", sa.String(40), nullable=False),
        sa.Column("paid_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("external_reference", sa.String(120), nullable=False),
        sa.Column("metadata_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_commercial_invoices_company", "commercial_invoices", ["company_id"])
    op.create_index("ix_commercial_invoices_customer", "commercial_invoices", ["customer_id"])
    op.create_index("ix_commercial_invoices_status", "commercial_invoices", ["status"])
    op.create_index("ix_commercial_invoices_due", "commercial_invoices", ["due_at"])


def downgrade() -> None:
    op.drop_table("commercial_invoices")
    op.drop_table("commercial_subscriptions")
    op.drop_table("commercial_plans")
    op.drop_table("commercial_contracts")
    op.drop_table("commercial_proposals")
    op.drop_table("commercial_opportunities")
    op.drop_table("commercial_customers")
