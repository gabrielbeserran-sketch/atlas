from __future__ import annotations
from datetime import datetime
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, JSON, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column
from .database import Base
from .models import new_id, utcnow

class AiContextSnapshot(Base):
    __tablename__ = 'ai_context_snapshots'
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id('aictx'))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(ForeignKey('companies.id', ondelete='CASCADE'), index=True)
    farm_id: Mapped[str] = mapped_column(ForeignKey('farms.id', ondelete='CASCADE'), index=True)
    context_version: Mapped[str] = mapped_column(String(40), default='1.0')
    context_hash: Mapped[str] = mapped_column(String(64), index=True)
    period_start: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    period_end: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    quality: Mapped[dict] = mapped_column(JSON, default=dict)
    created_by: Mapped[str] = mapped_column(String(80))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)

class AiRecommendationRecord(Base):
    __tablename__ = 'ai_recommendation_records'
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id('airec'))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(ForeignKey('companies.id', ondelete='CASCADE'), index=True)
    farm_id: Mapped[str] = mapped_column(ForeignKey('farms.id', ondelete='CASCADE'), index=True)
    context_snapshot_id: Mapped[str | None] = mapped_column(ForeignKey('ai_context_snapshots.id', ondelete='SET NULL'), nullable=True)
    area: Mapped[str] = mapped_column(String(50), index=True)
    title: Mapped[str] = mapped_column(String(220))
    description: Mapped[str] = mapped_column(Text, default='')
    algorithm: Mapped[str] = mapped_column(String(100), default='atlas-rules')
    model_version: Mapped[str] = mapped_column(String(80), default='rules-v1')
    evidence: Mapped[list] = mapped_column(JSON, default=list)
    limitations: Mapped[list] = mapped_column(JSON, default=list)
    confidence: Mapped[float] = mapped_column(Float, default=0)
    expected_impact: Mapped[dict] = mapped_column(JSON, default=dict)
    recommended_action: Mapped[str] = mapped_column(Text, default='')
    priority: Mapped[str] = mapped_column(String(30), default='medium', index=True)
    human_decision: Mapped[str] = mapped_column(String(30), default='pending', index=True)
    observed_result: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    decided_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

class AiSupervisedAutomation(Base):
    __tablename__ = 'ai_supervised_automations'
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id('aiauto'))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(ForeignKey('companies.id', ondelete='CASCADE'), index=True)
    farm_id: Mapped[str] = mapped_column(ForeignKey('farms.id', ondelete='CASCADE'), index=True)
    recommendation_id: Mapped[str | None] = mapped_column(ForeignKey('ai_recommendation_records.id', ondelete='SET NULL'), nullable=True)
    action_type: Mapped[str] = mapped_column(String(60), index=True)
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    requires_approval: Mapped[bool] = mapped_column(Boolean, default=True)
    financial_limit: Mapped[float] = mapped_column(Float, default=0)
    status: Mapped[str] = mapped_column(String(30), default='pending_approval', index=True)
    approved_by: Mapped[str] = mapped_column(String(80), default='')
    executed_by: Mapped[str] = mapped_column(String(80), default='')
    result: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    approved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    executed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

class AiModelGovernance(Base):
    __tablename__ = 'ai_model_governance'
    __table_args__ = (UniqueConstraint('company_id','model_key','version', name='uq_ai_model_governance_version'),)
    id: Mapped[str] = mapped_column(String(80), primary_key=True, default=lambda: new_id('aigov'))
    tenant_id: Mapped[str] = mapped_column(String(80), index=True)
    company_id: Mapped[str] = mapped_column(ForeignKey('companies.id', ondelete='CASCADE'), index=True)
    model_key: Mapped[str] = mapped_column(String(120), index=True)
    version: Mapped[str] = mapped_column(String(80))
    owner: Mapped[str] = mapped_column(String(180))
    status: Mapped[str] = mapped_column(String(30), default='draft', index=True)
    authorized_data: Mapped[list] = mapped_column(JSON, default=list)
    minimum_metrics: Mapped[dict] = mapped_column(JSON, default=dict)
    current_metrics: Mapped[dict] = mapped_column(JSON, default=dict)
    drift_status: Mapped[str] = mapped_column(String(30), default='unknown')
    bias_status: Mapped[str] = mapped_column(String(30), default='unknown')
    rollback_version: Mapped[str] = mapped_column(String(80), default='')
    incident_notes: Mapped[str] = mapped_column(Text, default='')
    approved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
