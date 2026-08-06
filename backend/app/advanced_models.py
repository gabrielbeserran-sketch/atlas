from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Index, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from .database import Base
from .models import new_id


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class AtlasGeoAsset(Base):
    __tablename__ = "atlas_geo_assets"
    __table_args__ = (
        Index("ix_atlas_geo_assets_company_farm_type", "company_id", "farm_id", "asset_type"),
    )
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("geo"))
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), index=True)
    asset_type: Mapped[str] = mapped_column(String(50), index=True)
    name: Mapped[str] = mapped_column(String(180))
    geometry_type: Mapped[str] = mapped_column(String(30), default="Point")
    geometry_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    properties_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    source: Mapped[str] = mapped_column(String(60), default="manual")
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)


class AtlasPastureRecord(Base):
    __tablename__ = "atlas_pasture_records"
    __table_args__ = (Index("ix_atlas_pasture_farm_paddock_date", "farm_id", "paddock_id", "observed_at"),)
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("pasture"))
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), index=True)
    paddock_id: Mapped[str | None] = mapped_column(ForeignKey("atlas_geo_assets.id", ondelete="SET NULL"), index=True, nullable=True)
    record_type: Mapped[str] = mapped_column(String(50), index=True)
    observed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    grass_species: Mapped[str] = mapped_column(String(120), default="")
    area_ha: Mapped[float] = mapped_column(Float, default=0)
    height_cm: Mapped[float] = mapped_column(Float, default=0)
    forage_mass_kg_dm_ha: Mapped[float] = mapped_column(Float, default=0)
    utilization_percent: Mapped[float] = mapped_column(Float, default=50)
    stocking_au: Mapped[float] = mapped_column(Float, default=0)
    days_available: Mapped[float] = mapped_column(Float, default=0)
    input_name: Mapped[str] = mapped_column(String(160), default="")
    input_quantity: Mapped[float] = mapped_column(Float, default=0)
    input_unit: Mapped[str] = mapped_column(String(40), default="")
    cost: Mapped[float] = mapped_column(Float, default=0)
    notes: Mapped[str] = mapped_column(Text, default="")
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class AtlasAgricultureRecord(Base):
    __tablename__ = "atlas_agriculture_records"
    __table_args__ = (Index("ix_atlas_agriculture_farm_crop_date", "farm_id", "crop_name", "occurred_at"),)
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("agri"))
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), index=True)
    field_id: Mapped[str | None] = mapped_column(ForeignKey("atlas_geo_assets.id", ondelete="SET NULL"), nullable=True, index=True)
    record_type: Mapped[str] = mapped_column(String(50), index=True)
    crop_name: Mapped[str] = mapped_column(String(120), default="")
    cultivar: Mapped[str] = mapped_column(String(120), default="")
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    area_ha: Mapped[float] = mapped_column(Float, default=0)
    quantity: Mapped[float] = mapped_column(Float, default=0)
    unit: Mapped[str] = mapped_column(String(40), default="")
    unit_cost: Mapped[float] = mapped_column(Float, default=0)
    destination: Mapped[str] = mapped_column(String(120), default="")
    linked_nutrition_plan_id: Mapped[str | None] = mapped_column(String(80), nullable=True)
    notes: Mapped[str] = mapped_column(Text, default="")
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class AtlasGeneticProfile(Base):
    __tablename__ = "atlas_genetic_profiles"
    __table_args__ = (Index("ix_atlas_genetics_company_animal", "company_id", "animal_id", unique=True),)
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("genetic"))
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), index=True)
    animal_id: Mapped[str] = mapped_column(ForeignKey("livestock_animals.id", ondelete="CASCADE"), index=True)
    sire_animal_id: Mapped[str | None] = mapped_column(ForeignKey("livestock_animals.id", ondelete="SET NULL"), nullable=True)
    dam_animal_id: Mapped[str | None] = mapped_column(ForeignKey("livestock_animals.id", ondelete="SET NULL"), nullable=True)
    registry_number: Mapped[str] = mapped_column(String(120), default="")
    breed_composition_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    dep_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    economic_index: Mapped[float] = mapped_column(Float, default=0)
    genetic_score: Mapped[float] = mapped_column(Float, default=0)
    inbreeding_coefficient: Mapped[float] = mapped_column(Float, default=0)
    dna_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    source: Mapped[str] = mapped_column(String(80), default="manual")
    notes: Mapped[str] = mapped_column(Text, default="")
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)


class AtlasAiForecast(Base):
    __tablename__ = "atlas_ai_forecasts"
    __table_args__ = (Index("ix_atlas_ai_forecast_farm_type", "farm_id", "forecast_type", "generated_at"),)
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("forecast"))
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), index=True)
    animal_id: Mapped[str | None] = mapped_column(ForeignKey("livestock_animals.id", ondelete="SET NULL"), nullable=True, index=True)
    lot_id: Mapped[str | None] = mapped_column(ForeignKey("herd_lots.id", ondelete="SET NULL"), nullable=True, index=True)
    forecast_type: Mapped[str] = mapped_column(String(60), index=True)
    horizon_days: Mapped[int] = mapped_column(Integer, default=30)
    score: Mapped[float] = mapped_column(Float, default=0)
    confidence_percent: Mapped[float] = mapped_column(Float, default=0)
    prediction_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    evidence_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    recommendation: Mapped[str] = mapped_column(Text, default="")
    model_version: Mapped[str] = mapped_column(String(60), default="rules-v1")
    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
