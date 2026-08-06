from __future__ import annotations

from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, JSON, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from .database import Base
from .models import new_id, utcnow


class OfflineDevice(Base):
    __tablename__ = "offline_devices"
    __table_args__ = (
        UniqueConstraint("company_id", "device_key", name="uq_offline_device_company_key"),
    )

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("device"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    device_key: Mapped[str] = mapped_column(String(180), index=True)
    name: Mapped[str] = mapped_column(String(180), default="Dispositivo")
    platform: Mapped[str] = mapped_column(String(40), default="unknown")
    app_version: Mapped[str] = mapped_column(String(40), default="")
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    last_cursor: Mapped[int] = mapped_column(Integer, default=0)
    last_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class SyncConflict(Base):
    __tablename__ = "sync_conflicts"
    __table_args__ = (
        UniqueConstraint("company_id", "operation_id", name="uq_sync_conflict_company_operation"),
    )

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("conflict"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(80), nullable=True, index=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    device_id: Mapped[str] = mapped_column(String(180), default="unknown")
    operation_id: Mapped[str] = mapped_column(String(120), index=True)
    entity_type: Mapped[str] = mapped_column(String(80), index=True)
    entity_id: Mapped[str] = mapped_column(String(120), index=True)
    local_version: Mapped[int] = mapped_column(Integer, default=0)
    remote_version: Mapped[int] = mapped_column(Integer, default=0)
    local_payload: Mapped[dict] = mapped_column(JSON, default=dict)
    remote_payload: Mapped[dict] = mapped_column(JSON, default=dict)
    status: Mapped[str] = mapped_column(String(30), default="open", index=True)
    resolution: Mapped[str] = mapped_column(String(30), default="")
    resolved_payload: Mapped[dict] = mapped_column(JSON, default=dict)
    resolution_note: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class OfflineDiagnostic(Base):
    __tablename__ = "offline_diagnostics"

    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("diag"))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    device_id: Mapped[str] = mapped_column(String(180), index=True)
    queue_size: Mapped[int] = mapped_column(Integer, default=0)
    failed_operations: Mapped[int] = mapped_column(Integer, default=0)
    local_database_bytes: Mapped[int] = mapped_column(Integer, default=0)
    free_storage_bytes: Mapped[int] = mapped_column(Integer, default=0)
    clock_offset_seconds: Mapped[int] = mapped_column(Integer, default=0)
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    reported_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
