from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Index, Integer, JSON, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from .database import Base
from .models import new_id


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class AtlasBusinessParty(Base):
    __tablename__ = "atlas_business_parties"
    __table_args__ = (Index("ix_atlas_party_company_type_name", "company_id", "party_type", "name"),)
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("party"))
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    party_type: Mapped[str] = mapped_column(String(30), index=True)  # customer | supplier | partner
    name: Mapped[str] = mapped_column(String(180), index=True)
    document: Mapped[str] = mapped_column(String(40), default="")
    email: Mapped[str] = mapped_column(String(180), default="")
    phone: Mapped[str] = mapped_column(String(40), default="")
    address_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    crm_stage: Mapped[str] = mapped_column(String(40), default="active")
    notes: Mapped[str] = mapped_column(Text, default="")
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)


class AtlasCommercialDocument(Base):
    __tablename__ = "atlas_commercial_documents"
    __table_args__ = (Index("ix_atlas_commercial_company_farm_type_date", "company_id", "farm_id", "document_type", "occurred_at"),)
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("commercial"))
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(ForeignKey("farms.id", ondelete="SET NULL"), nullable=True, index=True)
    party_id: Mapped[str | None] = mapped_column(ForeignKey("atlas_business_parties.id", ondelete="SET NULL"), nullable=True, index=True)
    document_type: Mapped[str] = mapped_column(String(40), index=True)  # purchase, sale, contract, auction, invoice, transport
    number: Mapped[str] = mapped_column(String(80), default="")
    status: Mapped[str] = mapped_column(String(30), default="draft", index=True)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    total_amount: Mapped[float] = mapped_column(Float, default=0)
    currency: Mapped[str] = mapped_column(String(10), default="BRL")
    items_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    logistics_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    fiscal_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    notes: Mapped[str] = mapped_column(Text, default="")
    created_by: Mapped[str | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class AtlasConsultingVisit(Base):
    __tablename__ = "atlas_consulting_visits"
    __table_args__ = (Index("ix_atlas_visit_company_farm_scheduled", "company_id", "farm_id", "scheduled_at"),)
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("visit"))
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), index=True)
    consultant_user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    title: Mapped[str] = mapped_column(String(180))
    status: Mapped[str] = mapped_column(String(30), default="scheduled", index=True)
    scheduled_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    checklist_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    photos_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    findings_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    report_text: Mapped[str] = mapped_column(Text, default="")
    opinion_text: Mapped[str] = mapped_column(Text, default="")
    signature_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    previous_visit_id: Mapped[str | None] = mapped_column(ForeignKey("atlas_consulting_visits.id", ondelete="SET NULL"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)


class AtlasActionPlanItem(Base):
    __tablename__ = "atlas_action_plan_items"
    __table_args__ = (
        Index("ix_atlas_action_company_farm_status_due", "company_id", "farm_id", "status", "due_at"),
        UniqueConstraint(
            "company_id",
            "farm_id",
            "idempotency_key",
            name="uq_atlas_action_company_farm_idempotency",
        ),
    )
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("action"))
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str] = mapped_column(ForeignKey("farms.id", ondelete="CASCADE"), index=True)
    visit_id: Mapped[str | None] = mapped_column(ForeignKey("atlas_consulting_visits.id", ondelete="SET NULL"), nullable=True)
    title: Mapped[str] = mapped_column(String(180))
    description: Mapped[str] = mapped_column(Text, default="")
    area: Mapped[str] = mapped_column(String(50), default="general", index=True)
    priority: Mapped[str] = mapped_column(String(20), default="medium", index=True)
    status: Mapped[str] = mapped_column(String(30), default="open", index=True)
    assigned_user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    follow_up_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    expected_result: Mapped[str] = mapped_column(Text, default="")
    actual_result: Mapped[str] = mapped_column(Text, default="")
    completed_by_user_id: Mapped[str | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    execution_evidence_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    source_entity_type: Mapped[str] = mapped_column(String(80), default="", index=True)
    source_entity_id: Mapped[str] = mapped_column(String(120), default="", index=True)
    baseline_metrics_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    outcome_metrics_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    outcome_status: Mapped[str] = mapped_column(String(30), default="pending", index=True)
    outcome_measured_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    idempotency_key: Mapped[str | None] = mapped_column(String(160), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class AtlasWorkflowDefinition(Base):
    __tablename__ = "atlas_workflow_definitions"
    __table_args__ = (Index("ix_atlas_workflow_company_code", "company_id", "code", unique=True),)
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("workflow"))
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    code: Mapped[str] = mapped_column(String(80))
    name: Mapped[str] = mapped_column(String(180))
    entity_type: Mapped[str] = mapped_column(String(60), default="generic")
    steps_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class AtlasWorkflowInstance(Base):
    __tablename__ = "atlas_workflow_instances"
    __table_args__ = (Index("ix_atlas_workflow_instance_company_status", "company_id", "status"),)
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("flowrun"))
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    workflow_id: Mapped[str] = mapped_column(ForeignKey("atlas_workflow_definitions.id", ondelete="CASCADE"), index=True)
    entity_type: Mapped[str] = mapped_column(String(60))
    entity_id: Mapped[str] = mapped_column(String(80), index=True)
    current_step: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[str] = mapped_column(String(30), default="pending", index=True)
    history_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    started_by: Mapped[str | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class AtlasApiCredential(Base):
    __tablename__ = "atlas_api_credentials"
    __table_args__ = (Index("ix_atlas_api_credential_company_prefix", "company_id", "key_prefix", unique=True),)
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("apikey"))
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    name: Mapped[str] = mapped_column(String(120))
    key_prefix: Mapped[str] = mapped_column(String(24))
    key_hash: Mapped[str] = mapped_column(String(160))
    scopes_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    last_used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class AtlasWebhookEndpoint(Base):
    __tablename__ = "atlas_webhook_endpoints"
    __table_args__ = (Index("ix_atlas_webhook_company_active", "company_id", "active"),)
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("webhook"))
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    name: Mapped[str] = mapped_column(String(120))
    url: Mapped[str] = mapped_column(String(500))
    events_json: Mapped[list[Any]] = mapped_column(JSON, default=list)
    secret_hash: Mapped[str] = mapped_column(String(160), default="")
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    last_delivery_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_status_code: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class AtlasSubscription(Base):
    __tablename__ = "atlas_subscriptions"
    __table_args__ = (Index("ix_atlas_subscription_company_status", "company_id", "status"),)
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("subscription"))
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    plan_code: Mapped[str] = mapped_column(String(50), default="pilot")
    status: Mapped[str] = mapped_column(String(30), default="trial", index=True)
    billing_cycle: Mapped[str] = mapped_column(String(20), default="monthly")
    amount: Mapped[float] = mapped_column(Float, default=0)
    provider: Mapped[str] = mapped_column(String(40), default="manual")
    provider_customer_id: Mapped[str] = mapped_column(String(160), default="")
    provider_subscription_id: Mapped[str] = mapped_column(String(160), default="")
    trial_ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    current_period_ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)


class AtlasAnalyticsSnapshot(Base):
    __tablename__ = "atlas_analytics_snapshots"
    __table_args__ = (Index("ix_atlas_snapshot_company_farm_period", "company_id", "farm_id", "period_start"),)
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id("snapshot"))
    company_id: Mapped[str] = mapped_column(ForeignKey("companies.id", ondelete="CASCADE"), index=True)
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    farm_id: Mapped[str | None] = mapped_column(ForeignKey("farms.id", ondelete="SET NULL"), nullable=True, index=True)
    period_start: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    period_end: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    metrics_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    benchmark_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    forecast_json: Mapped[dict[str, Any]] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
