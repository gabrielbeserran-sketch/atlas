
"""livestock real APIs

Revision ID: 20260804_0003
Revises: 20260804_0002
"""
from alembic import op
import sqlalchemy as sa

revision = "20260804_0003"
down_revision = "20260804_0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "herd_lots",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), sa.ForeignKey("companies.id", ondelete="CASCADE"), nullable=False),
        sa.Column("farm_id", sa.String(80), sa.ForeignKey("farms.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("category", sa.String(100), nullable=False, server_default=""),
        sa.Column("status", sa.String(40), nullable=False, server_default="active"),
        sa.Column("capacity", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("notes", sa.Text(), nullable=False, server_default=""),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "farm_id", "name", name="uq_lot_company_farm_name"),
    )
    op.create_index("ix_herd_lots_company_id", "herd_lots", ["company_id"])
    op.create_index("ix_herd_lots_farm_id", "herd_lots", ["farm_id"])

    op.create_table(
        "livestock_animals",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), sa.ForeignKey("companies.id", ondelete="CASCADE"), nullable=False),
        sa.Column("farm_id", sa.String(80), sa.ForeignKey("farms.id", ondelete="CASCADE"), nullable=False),
        sa.Column("lot_id", sa.String(80), sa.ForeignKey("herd_lots.id", ondelete="SET NULL"), nullable=True),
        sa.Column("tag", sa.String(120), nullable=False),
        sa.Column("sisbov", sa.String(120), nullable=False, server_default=""),
        sa.Column("name", sa.String(180), nullable=False, server_default=""),
        sa.Column("sex", sa.String(30), nullable=False, server_default=""),
        sa.Column("breed", sa.String(100), nullable=False, server_default=""),
        sa.Column("category", sa.String(100), nullable=False, server_default=""),
        sa.Column("birth_date", sa.String(20), nullable=False, server_default=""),
        sa.Column("status", sa.String(40), nullable=False, server_default="active"),
        sa.Column("current_weight", sa.Float(), nullable=False, server_default="0"),
        sa.Column("body_condition_score", sa.Float(), nullable=False, server_default="0"),
        sa.Column("mother_id", sa.String(80), nullable=True),
        sa.Column("father_id", sa.String(80), nullable=True),
        sa.Column("metadata_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "tag", name="uq_animal_company_tag"),
        sa.UniqueConstraint("company_id", "sisbov", name="uq_animal_company_sisbov"),
    )
    op.create_index("ix_livestock_animals_company_id", "livestock_animals", ["company_id"])
    op.create_index("ix_livestock_animals_farm_id", "livestock_animals", ["farm_id"])
    op.create_index("ix_livestock_animals_lot_id", "livestock_animals", ["lot_id"])
    op.create_index("ix_livestock_animals_tag", "livestock_animals", ["tag"])

    for table, columns in {
        "animal_movements": [
            sa.Column("id", sa.String(80), primary_key=True),
            sa.Column("tenant_id", sa.String(80), nullable=False),
            sa.Column("company_id", sa.String(80), nullable=False),
            sa.Column("farm_id", sa.String(80), nullable=False),
            sa.Column("animal_id", sa.String(80), sa.ForeignKey("livestock_animals.id", ondelete="CASCADE"), nullable=False),
            sa.Column("movement_type", sa.String(60), nullable=False),
            sa.Column("from_lot_id", sa.String(80), nullable=True),
            sa.Column("to_lot_id", sa.String(80), nullable=True),
            sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("reason", sa.Text(), nullable=False, server_default=""),
            sa.Column("document_reference", sa.String(180), nullable=False, server_default=""),
            sa.Column("created_by", sa.String(80), nullable=False),
        ],
        "weight_records": [
            sa.Column("id", sa.String(80), primary_key=True),
            sa.Column("tenant_id", sa.String(80), nullable=False),
            sa.Column("company_id", sa.String(80), nullable=False),
            sa.Column("farm_id", sa.String(80), nullable=False),
            sa.Column("animal_id", sa.String(80), sa.ForeignKey("livestock_animals.id", ondelete="CASCADE"), nullable=False),
            sa.Column("weight", sa.Float(), nullable=False),
            sa.Column("body_condition_score", sa.Float(), nullable=False, server_default="0"),
            sa.Column("source", sa.String(100), nullable=False, server_default=""),
            sa.Column("equipment", sa.String(120), nullable=False, server_default=""),
            sa.Column("measured_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("notes", sa.Text(), nullable=False, server_default=""),
            sa.Column("created_by", sa.String(80), nullable=False),
        ],
        "reproduction_events": [
            sa.Column("id", sa.String(80), primary_key=True),
            sa.Column("tenant_id", sa.String(80), nullable=False),
            sa.Column("company_id", sa.String(80), nullable=False),
            sa.Column("farm_id", sa.String(80), nullable=False),
            sa.Column("animal_id", sa.String(80), sa.ForeignKey("livestock_animals.id", ondelete="CASCADE"), nullable=False),
            sa.Column("event_type", sa.String(80), nullable=False),
            sa.Column("protocol_name", sa.String(180), nullable=False, server_default=""),
            sa.Column("sire_reference", sa.String(180), nullable=False, server_default=""),
            sa.Column("result", sa.String(100), nullable=False, server_default=""),
            sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("expected_date", sa.DateTime(timezone=True), nullable=True),
            sa.Column("notes", sa.Text(), nullable=False, server_default=""),
            sa.Column("created_by", sa.String(80), nullable=False),
        ],
    }.items():
        op.create_table(table, *columns)

    op.create_table(
        "health_events",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=False),
        sa.Column("animal_id", sa.String(80), sa.ForeignKey("livestock_animals.id", ondelete="CASCADE"), nullable=True),
        sa.Column("lot_id", sa.String(80), sa.ForeignKey("herd_lots.id", ondelete="CASCADE"), nullable=True),
        sa.Column("event_type", sa.String(80), nullable=False),
        sa.Column("product_name", sa.String(180), nullable=False, server_default=""),
        sa.Column("dosage", sa.String(80), nullable=False, server_default=""),
        sa.Column("route", sa.String(80), nullable=False, server_default=""),
        sa.Column("withdrawal_until", sa.DateTime(timezone=True), nullable=True),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("responsible", sa.String(180), nullable=False, server_default=""),
        sa.Column("notes", sa.Text(), nullable=False, server_default=""),
        sa.Column("created_by", sa.String(80), nullable=False),
    )

    op.create_table(
        "inventory_products",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=False),
        sa.Column("sku", sa.String(120), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("category", sa.String(100), nullable=False, server_default=""),
        sa.Column("unit", sa.String(40), nullable=False, server_default="un"),
        sa.Column("quantity", sa.Float(), nullable=False, server_default="0"),
        sa.Column("minimum_quantity", sa.Float(), nullable=False, server_default="0"),
        sa.Column("average_cost", sa.Float(), nullable=False, server_default="0"),
        sa.Column("expiry_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column("active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "sku", name="uq_inventory_company_sku"),
    )

    op.create_table(
        "inventory_movements",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=False),
        sa.Column("product_id", sa.String(80), sa.ForeignKey("inventory_products.id", ondelete="CASCADE"), nullable=False),
        sa.Column("movement_type", sa.String(40), nullable=False),
        sa.Column("quantity", sa.Float(), nullable=False),
        sa.Column("unit_cost", sa.Float(), nullable=False, server_default="0"),
        sa.Column("reference_type", sa.String(80), nullable=False, server_default=""),
        sa.Column("reference_id", sa.String(120), nullable=False, server_default=""),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_by", sa.String(80), nullable=False),
    )

    op.create_table(
        "financial_entries",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=False),
        sa.Column("entry_type", sa.String(30), nullable=False),
        sa.Column("category", sa.String(100), nullable=False, server_default=""),
        sa.Column("description", sa.String(255), nullable=False),
        sa.Column("amount", sa.Float(), nullable=False),
        sa.Column("due_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column("paid_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("reference_type", sa.String(80), nullable=False, server_default=""),
        sa.Column("reference_id", sa.String(120), nullable=False, server_default=""),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_by", sa.String(80), nullable=False),
    )

    op.create_table(
        "nutrition_events",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=False),
        sa.Column("lot_id", sa.String(80), sa.ForeignKey("herd_lots.id", ondelete="CASCADE"), nullable=False),
        sa.Column("diet_name", sa.String(180), nullable=False),
        sa.Column("product_id", sa.String(80), sa.ForeignKey("inventory_products.id", ondelete="SET NULL"), nullable=True),
        sa.Column("quantity_per_head", sa.Float(), nullable=False, server_default="0"),
        sa.Column("total_quantity", sa.Float(), nullable=False, server_default="0"),
        sa.Column("estimated_cost", sa.Float(), nullable=False, server_default="0"),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("notes", sa.Text(), nullable=False, server_default=""),
        sa.Column("created_by", sa.String(80), nullable=False),
    )


def downgrade() -> None:
    for table in [
        "nutrition_events", "financial_entries", "inventory_movements",
        "inventory_products", "health_events", "reproduction_events",
        "weight_records", "animal_movements", "livestock_animals", "herd_lots",
    ]:
        op.drop_table(table)
