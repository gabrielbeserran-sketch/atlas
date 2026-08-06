from __future__ import annotations
from datetime import datetime, timezone
from typing import Any
from sqlalchemy import Boolean, DateTime, Float, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column
from .database import Base
from .models import new_id

def utcnow() -> datetime:
    return datetime.now(timezone.utc)

class ScopedEntityMixin:
    company_id: Mapped[str] = mapped_column(String(64), index=True)
    tenant_id: Mapped[str] = mapped_column(String(64), index=True)
    farm_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

class AnnualBudget(Base, ScopedEntityMixin):
    __tablename__ = "annual_budgets"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: new_id("budget"))
    year: Mapped[int] = mapped_column(Integer, index=True)
    cost_center: Mapped[str] = mapped_column(String(120), default="General", index=True)
    revenue_budget: Mapped[float] = mapped_column(Float, default=0)
    expense_budget: Mapped[float] = mapped_column(Float, default=0)
    assumptions_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)

class InventoryCount(Base, ScopedEntityMixin):
    __tablename__ = "inventory_counts"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: new_id("inventory_count"))
    status: Mapped[str] = mapped_column(String(32), default="open", index=True)
    counted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    items_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    differences_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    notes: Mapped[str] = mapped_column(Text, default="")

class EcosystemPartner(Base, ScopedEntityMixin):
    __tablename__ = "ecosystem_partners"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: new_id("partner"))
    partner_type: Mapped[str] = mapped_column(String(48), index=True)
    name: Mapped[str] = mapped_column(String(180))
    document: Mapped[str] = mapped_column(String(64), default="")
    email: Mapped[str] = mapped_column(String(180), default="")
    phone: Mapped[str] = mapped_column(String(64), default="")
    service_regions_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    specialties_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    verified: Mapped[bool] = mapped_column(Boolean, default=False)
    active: Mapped[bool] = mapped_column(Boolean, default=True)

class SupportConversation(Base, ScopedEntityMixin):
    __tablename__ = "support_conversations"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: new_id("support"))
    subject: Mapped[str] = mapped_column(String(220))
    status: Mapped[str] = mapped_column(String(32), default="open", index=True)
    priority: Mapped[str] = mapped_column(String(24), default="medium")
    participants_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    messages_json: Mapped[list[Any]] = mapped_column(JSON, default=list)

class StrategicPlan(Base, ScopedEntityMixin):
    __tablename__ = "strategic_plans_v2"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: new_id("strategy"))
    title: Mapped[str] = mapped_column(String(220))
    horizon_days: Mapped[int] = mapped_column(Integer, default=365)
    status: Mapped[str] = mapped_column(String(32), default="draft")
    objectives_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    kpis_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    initiatives_json: Mapped[list[Any]] = mapped_column(JSON, default=list)

class CorporateScenario(Base, ScopedEntityMixin):
    __tablename__ = "corporate_scenarios"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: new_id("scenario"))
    name: Mapped[str] = mapped_column(String(180))
    scenario_type: Mapped[str] = mapped_column(String(48), default="custom")
    assumptions_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    results_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    roi_percent: Mapped[float] = mapped_column(Float, default=0)

class LocalizationProfile(Base, ScopedEntityMixin):
    __tablename__ = "localization_profiles"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: new_id("locale"))
    locale: Mapped[str] = mapped_column(String(16), default="pt-BR")
    currency: Mapped[str] = mapped_column(String(8), default="BRL")
    measurement_system: Mapped[str] = mapped_column(String(24), default="metric")
    timezone_name: Mapped[str] = mapped_column(String(64), default="America/Sao_Paulo")
    settings_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)

class CertificationRecord(Base, ScopedEntityMixin):
    __tablename__ = "certification_records"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: new_id("certification"))
    certification_type: Mapped[str] = mapped_column(String(100), index=True)
    issuer: Mapped[str] = mapped_column(String(180), default="")
    valid_from: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    valid_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str] = mapped_column(String(32), default="pending")
    evidence_json: Mapped[list[Any]] = mapped_column(JSON, default=list)

class TrainingResource(Base, ScopedEntityMixin):
    __tablename__ = "training_resources"
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: new_id("training"))
    resource_type: Mapped[str] = mapped_column(String(48), default="course")
    title: Mapped[str] = mapped_column(String(220))
    language: Mapped[str] = mapped_column(String(16), default="pt-BR")
    content_uri: Mapped[str] = mapped_column(Text, default="")
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    published: Mapped[bool] = mapped_column(Boolean, default=False)
