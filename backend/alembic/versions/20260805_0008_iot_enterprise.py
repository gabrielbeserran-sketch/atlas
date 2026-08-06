
"""iot enterprise

Revision ID: 20260805_0008
Revises: 20260805_0007
"""
from alembic import op
import sqlalchemy as sa

revision = "20260805_0008"
down_revision = "20260805_0007"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "iot_gateways",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=False),
        sa.Column("external_id", sa.String(120), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("protocol", sa.String(40), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("firmware_version", sa.String(80), nullable=False),
        sa.Column("ip_address", sa.String(80), nullable=False),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("metadata_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "external_id", name="uq_iot_gateway_external_id"),
    )
    op.create_index("ix_iot_gateways_company", "iot_gateways", ["company_id"])
    op.create_index("ix_iot_gateways_farm", "iot_gateways", ["farm_id"])
    op.create_index("ix_iot_gateways_status", "iot_gateways", ["status"])

    op.create_table(
        "iot_devices",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=False),
        sa.Column("gateway_id", sa.String(80), sa.ForeignKey("iot_gateways.id", ondelete="SET NULL"), nullable=True),
        sa.Column("external_id", sa.String(120), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("device_type", sa.String(80), nullable=False),
        sa.Column("model", sa.String(120), nullable=False),
        sa.Column("manufacturer", sa.String(120), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("battery_percent", sa.Float(), nullable=True),
        sa.Column("signal_strength", sa.Float(), nullable=True),
        sa.Column("animal_id", sa.String(80), nullable=True),
        sa.Column("lot_id", sa.String(80), nullable=True),
        sa.Column("installed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("configuration", sa.JSON(), nullable=False),
        sa.Column("metadata_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("company_id", "external_id", name="uq_iot_device_external_id"),
    )
    op.create_index("ix_iot_devices_company", "iot_devices", ["company_id"])
    op.create_index("ix_iot_devices_farm", "iot_devices", ["farm_id"])
    op.create_index("ix_iot_devices_gateway", "iot_devices", ["gateway_id"])
    op.create_index("ix_iot_devices_type", "iot_devices", ["device_type"])
    op.create_index("ix_iot_devices_status", "iot_devices", ["status"])

    op.create_table(
        "iot_telemetry",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=False),
        sa.Column("device_id", sa.String(80), sa.ForeignKey("iot_devices.id", ondelete="CASCADE"), nullable=False),
        sa.Column("metric_key", sa.String(120), nullable=False),
        sa.Column("value", sa.Float(), nullable=False),
        sa.Column("unit", sa.String(40), nullable=False),
        sa.Column("quality", sa.String(30), nullable=False),
        sa.Column("payload", sa.JSON(), nullable=False),
        sa.Column("recorded_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("received_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_iot_telemetry_company", "iot_telemetry", ["company_id"])
    op.create_index("ix_iot_telemetry_farm", "iot_telemetry", ["farm_id"])
    op.create_index("ix_iot_telemetry_device", "iot_telemetry", ["device_id"])
    op.create_index("ix_iot_telemetry_metric", "iot_telemetry", ["metric_key"])
    op.create_index("ix_iot_telemetry_recorded", "iot_telemetry", ["recorded_at"])

    op.create_table(
        "iot_commands",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=False),
        sa.Column("device_id", sa.String(80), sa.ForeignKey("iot_devices.id", ondelete="CASCADE"), nullable=False),
        sa.Column("command_type", sa.String(100), nullable=False),
        sa.Column("payload", sa.JSON(), nullable=False),
        sa.Column("status", sa.String(30), nullable=False),
        sa.Column("requested_by", sa.String(80), nullable=False),
        sa.Column("requested_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("acknowledged_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("result_payload", sa.JSON(), nullable=False),
        sa.Column("error_message", sa.Text(), nullable=False),
    )
    op.create_index("ix_iot_commands_company", "iot_commands", ["company_id"])
    op.create_index("ix_iot_commands_device", "iot_commands", ["device_id"])
    op.create_index("ix_iot_commands_status", "iot_commands", ["status"])

    op.create_table(
        "iot_automation_rules",
        sa.Column("id", sa.String(80), primary_key=True),
        sa.Column("tenant_id", sa.String(80), nullable=False),
        sa.Column("company_id", sa.String(80), nullable=False),
        sa.Column("farm_id", sa.String(80), nullable=False),
        sa.Column("name", sa.String(180), nullable=False),
        sa.Column("metric_key", sa.String(120), nullable=False),
        sa.Column("operator", sa.String(20), nullable=False),
        sa.Column("threshold", sa.Float(), nullable=False),
        sa.Column("severity", sa.String(30), nullable=False),
        sa.Column("action_type", sa.String(80), nullable=False),
        sa.Column("action_payload", sa.JSON(), nullable=False),
        sa.Column("enabled", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_iot_rules_company", "iot_automation_rules", ["company_id"])
    op.create_index("ix_iot_rules_farm", "iot_automation_rules", ["farm_id"])
    op.create_index("ix_iot_rules_metric", "iot_automation_rules", ["metric_key"])


def downgrade() -> None:
    op.drop_table("iot_automation_rules")
    op.drop_table("iot_commands")
    op.drop_table("iot_telemetry")
    op.drop_table("iot_devices")
    op.drop_table("iot_gateways")
