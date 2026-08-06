"""offline sync foundation

Revision ID: 20260806_0029
Revises: 20260806_0028
"""
from alembic import op
import sqlalchemy as sa

revision = "20260806_0029"
down_revision = "20260806_0028"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table("offline_devices",
        sa.Column("id", sa.String(80), primary_key=True), sa.Column("tenant_id", sa.String(80), nullable=False), sa.Column("company_id", sa.String(80), sa.ForeignKey("companies.id", ondelete="CASCADE"), nullable=False), sa.Column("user_id", sa.String(80), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False), sa.Column("device_key", sa.String(180), nullable=False), sa.Column("name", sa.String(180), nullable=False, server_default="Dispositivo"), sa.Column("platform", sa.String(40), nullable=False, server_default="unknown"), sa.Column("app_version", sa.String(40), nullable=False, server_default=""), sa.Column("active", sa.Boolean(), nullable=False, server_default=sa.true()), sa.Column("last_cursor", sa.Integer(), nullable=False, server_default="0"), sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=False), sa.Column("created_at", sa.DateTime(timezone=True), nullable=False), sa.UniqueConstraint("company_id", "device_key", name="uq_offline_device_company_key"))
    op.create_index("ix_offline_devices_company_id", "offline_devices", ["company_id"]); op.create_index("ix_offline_devices_tenant_id", "offline_devices", ["tenant_id"]); op.create_index("ix_offline_devices_user_id", "offline_devices", ["user_id"]); op.create_index("ix_offline_devices_device_key", "offline_devices", ["device_key"])
    op.create_table("sync_conflicts",
        sa.Column("id", sa.String(80), primary_key=True), sa.Column("tenant_id", sa.String(80), nullable=False), sa.Column("company_id", sa.String(80), sa.ForeignKey("companies.id", ondelete="CASCADE"), nullable=False), sa.Column("farm_id", sa.String(80)), sa.Column("user_id", sa.String(80), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False), sa.Column("device_id", sa.String(180), nullable=False, server_default="unknown"), sa.Column("operation_id", sa.String(120), nullable=False), sa.Column("entity_type", sa.String(80), nullable=False), sa.Column("entity_id", sa.String(120), nullable=False), sa.Column("local_version", sa.Integer(), nullable=False, server_default="0"), sa.Column("remote_version", sa.Integer(), nullable=False, server_default="0"), sa.Column("local_payload", sa.JSON(), nullable=False), sa.Column("remote_payload", sa.JSON(), nullable=False), sa.Column("status", sa.String(30), nullable=False, server_default="open"), sa.Column("resolution", sa.String(30), nullable=False, server_default=""), sa.Column("resolved_payload", sa.JSON(), nullable=False), sa.Column("resolution_note", sa.Text(), nullable=False, server_default=""), sa.Column("created_at", sa.DateTime(timezone=True), nullable=False), sa.Column("resolved_at", sa.DateTime(timezone=True)), sa.UniqueConstraint("company_id", "operation_id", name="uq_sync_conflict_company_operation"))
    for name, cols in [("ix_sync_conflicts_company_id",["company_id"]),("ix_sync_conflicts_tenant_id",["tenant_id"]),("ix_sync_conflicts_farm_id",["farm_id"]),("ix_sync_conflicts_user_id",["user_id"]),("ix_sync_conflicts_operation_id",["operation_id"]),("ix_sync_conflicts_entity_type",["entity_type"]),("ix_sync_conflicts_entity_id",["entity_id"]),("ix_sync_conflicts_status",["status"])]: op.create_index(name,"sync_conflicts",cols)
    op.create_table("offline_diagnostics",
        sa.Column("id", sa.String(80), primary_key=True), sa.Column("tenant_id", sa.String(80), nullable=False), sa.Column("company_id", sa.String(80), sa.ForeignKey("companies.id", ondelete="CASCADE"), nullable=False), sa.Column("user_id", sa.String(80), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False), sa.Column("device_id", sa.String(180), nullable=False), sa.Column("queue_size", sa.Integer(), nullable=False, server_default="0"), sa.Column("failed_operations", sa.Integer(), nullable=False, server_default="0"), sa.Column("local_database_bytes", sa.Integer(), nullable=False, server_default="0"), sa.Column("free_storage_bytes", sa.Integer(), nullable=False, server_default="0"), sa.Column("clock_offset_seconds", sa.Integer(), nullable=False, server_default="0"), sa.Column("payload", sa.JSON(), nullable=False), sa.Column("reported_at", sa.DateTime(timezone=True), nullable=False))
    op.create_index("ix_offline_diagnostics_company_id","offline_diagnostics",["company_id"]); op.create_index("ix_offline_diagnostics_tenant_id","offline_diagnostics",["tenant_id"]); op.create_index("ix_offline_diagnostics_user_id","offline_diagnostics",["user_id"]); op.create_index("ix_offline_diagnostics_device_id","offline_diagnostics",["device_id"]); op.create_index("ix_offline_diagnostics_reported_at","offline_diagnostics",["reported_at"])


def downgrade() -> None:
    op.drop_table("offline_diagnostics")
    op.drop_table("sync_conflicts")
    op.drop_table("offline_devices")
