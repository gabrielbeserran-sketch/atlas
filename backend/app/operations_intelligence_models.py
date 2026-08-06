from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from .database import Base
from .models import new_id


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class TenantEntityMixin:
    company_id: Mapped[str] = mapped_column(String(64), index=True)
    tenant_id: Mapped[str] = mapped_column(String(64), index=True)
    farm_id: Mapped[str] = mapped_column(String(64), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)


class PrecisionAssessment(Base, TenantEntityMixin):
    __tablename__ = "precision_assessments"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: new_id("precision"))
    assessment_type: Mapped[str] = mapped_column(String(48), index=True)
    lot_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    animal_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    score: Mapped[float] = mapped_column(Float, default=0)
    confidence_percent: Mapped[float] = mapped_column(Float, default=0)
    metrics_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    evidence_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    recommendation: Mapped[str] = mapped_column(Text, default="")


class ReproductionProtocolTemplate(Base, TenantEntityMixin):
    __tablename__ = "reproduction_protocol_templates_v2"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: new_id("repro_protocol"))
    name: Mapped[str] = mapped_column(String(180))
    protocol_type: Mapped[str] = mapped_column(String(48), index=True)
    steps_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    active: Mapped[bool] = mapped_column(Boolean, default=True)


class BreedingSeason(Base, TenantEntityMixin):
    __tablename__ = "breeding_seasons"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: new_id("season"))
    name: Mapped[str] = mapped_column(String(180))
    starts_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    ends_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    target_pregnancy_rate: Mapped[float] = mapped_column(Float, default=0)
    status: Mapped[str] = mapped_column(String(32), default="planned")
    settings_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)


class MedicineLibraryItem(Base, TenantEntityMixin):
    __tablename__ = "medicine_library_items"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: new_id("medicine"))
    name: Mapped[str] = mapped_column(String(180))
    active_ingredient: Mapped[str] = mapped_column(String(180), default="")
    dosage_guidance: Mapped[str] = mapped_column(Text, default="")
    meat_withdrawal_days: Mapped[int] = mapped_column(Integer, default=0)
    milk_withdrawal_days: Mapped[int] = mapped_column(Integer, default=0)
    inventory_product_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)


class EpidemiologicalOccurrence(Base, TenantEntityMixin):
    __tablename__ = "epidemiological_occurrences"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: new_id("epi"))
    disease_code: Mapped[str] = mapped_column(String(80), index=True)
    lot_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    animal_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    severity: Mapped[str] = mapped_column(String(24), default="medium")
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    details_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)


class NutritionSimulation(Base, TenantEntityMixin):
    __tablename__ = "nutrition_simulations"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: new_id("diet_sim"))
    lot_id: Mapped[str] = mapped_column(String(64), index=True)
    name: Mapped[str] = mapped_column(String(180))
    ingredients_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    targets_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    results_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    daily_cost: Mapped[float] = mapped_column(Float, default=0)
    projected_gain_kg_day: Mapped[float] = mapped_column(Float, default=0)


class OperationalWorkOrder(Base, TenantEntityMixin):
    __tablename__ = "operational_work_orders"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: new_id("work_order"))
    title: Mapped[str] = mapped_column(String(180))
    area: Mapped[str] = mapped_column(String(64), index=True)
    assigned_user_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    priority: Mapped[str] = mapped_column(String(24), default="medium")
    status: Mapped[str] = mapped_column(String(24), default="open")
    scheduled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    estimated_cost: Mapped[float] = mapped_column(Float, default=0)
    actual_cost: Mapped[float] = mapped_column(Float, default=0)
    checklist_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    notes: Mapped[str] = mapped_column(Text, default="")


class FarmAsset(Base, TenantEntityMixin):
    __tablename__ = "farm_assets"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: new_id("asset"))
    name: Mapped[str] = mapped_column(String(180))
    asset_type: Mapped[str] = mapped_column(String(48), index=True)
    identifier: Mapped[str] = mapped_column(String(120), default="")
    status: Mapped[str] = mapped_column(String(24), default="active")
    hour_meter: Mapped[float] = mapped_column(Float, default=0)
    next_maintenance_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
