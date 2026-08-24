from __future__ import annotations
from datetime import datetime, timezone
from typing import Any
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Index, Integer, JSON, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column
from .database import Base
from .models import new_id

def utcnow(): return datetime.now(timezone.utc)

class SaaSPlan(Base):
    __tablename__='saas_plans'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('plan'))
    code: Mapped[str]=mapped_column(String(60),unique=True,index=True)
    name: Mapped[str]=mapped_column(String(160))
    price_monthly: Mapped[float]=mapped_column(Float,default=0)
    limits_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    features_json: Mapped[list[str]]=mapped_column(JSON,default=list)
    active: Mapped[bool]=mapped_column(Boolean,default=True)

class CompanySubscription(Base):
    __tablename__='company_subscriptions_v3'
    __table_args__=(UniqueConstraint('company_id',name='uq_company_subscription_v3'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('subscription'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    plan_id: Mapped[str]=mapped_column(ForeignKey('saas_plans.id',ondelete='RESTRICT'),index=True)
    status: Mapped[str]=mapped_column(String(30),default='trial',index=True)
    trial_ends_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    current_period_end: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    cancel_at_period_end: Mapped[bool]=mapped_column(Boolean,default=False)
    provider: Mapped[str]=mapped_column(String(40),default='manual')
    provider_subscription_id: Mapped[str]=mapped_column(String(180),default='')

class BillingInvoice(Base):
    __tablename__='billing_invoices_v3'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('invoice'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    subscription_id: Mapped[str|None]=mapped_column(ForeignKey('company_subscriptions_v3.id',ondelete='SET NULL'),nullable=True)
    number: Mapped[str]=mapped_column(String(80),unique=True,index=True)
    status: Mapped[str]=mapped_column(String(30),default='open',index=True)
    amount: Mapped[float]=mapped_column(Float,default=0)
    discount: Mapped[float]=mapped_column(Float,default=0)
    tax: Mapped[float]=mapped_column(Float,default=0)
    currency: Mapped[str]=mapped_column(String(3),default='BRL')
    due_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    paid_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    provider_payload_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)

class FeatureFlag(Base):
    __tablename__='feature_flags_v2'
    __table_args__=(Index('ix_feature_flag_scope','key','company_id','plan_code'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('flag'))
    key: Mapped[str]=mapped_column(String(120),index=True)
    description: Mapped[str]=mapped_column(Text,default='')
    enabled: Mapped[bool]=mapped_column(Boolean,default=False)
    company_id: Mapped[str|None]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),nullable=True,index=True)
    plan_code: Mapped[str|None]=mapped_column(String(60),nullable=True,index=True)
    rollout_percent: Mapped[int]=mapped_column(Integer,default=100)
    starts_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    ends_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)

class CommunicationTemplate(Base):
    __tablename__='communication_templates'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('template'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str|None]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),nullable=True,index=True)
    channel: Mapped[str]=mapped_column(String(30),index=True)
    code: Mapped[str]=mapped_column(String(100),index=True)
    subject: Mapped[str]=mapped_column(String(220),default='')
    body: Mapped[str]=mapped_column(Text)
    active: Mapped[bool]=mapped_column(Boolean,default=True)

class CommunicationDelivery(Base):
    __tablename__='communication_deliveries'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('delivery'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    template_id: Mapped[str|None]=mapped_column(ForeignKey('communication_templates.id',ondelete='SET NULL'),nullable=True)
    channel: Mapped[str]=mapped_column(String(30))
    recipient: Mapped[str]=mapped_column(String(220))
    status: Mapped[str]=mapped_column(String(30),default='queued',index=True)
    payload_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class OnboardingProgress(Base):
    __tablename__='onboarding_progress'
    __table_args__=(
        UniqueConstraint('company_id','farm_id',name='uq_onboarding_progress_company_farm'),
    )
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('onboarding'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str|None]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),nullable=True,index=True)
    steps_json: Mapped[dict[str,bool]]=mapped_column(JSON,default=dict)
    completion_percent: Mapped[float]=mapped_column(Float,default=0)
    completed_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)

class DataImportJob(Base):
    __tablename__='data_import_jobs'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('import'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str|None]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),nullable=True,index=True)
    entity_type: Mapped[str]=mapped_column(String(80),index=True)
    source_uri: Mapped[str]=mapped_column(String(700))
    mapping_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    preview_json: Mapped[list[dict[str,Any]]]=mapped_column(JSON,default=list)
    status: Mapped[str]=mapped_column(String(30),default='draft',index=True)
    total_rows: Mapped[int]=mapped_column(Integer,default=0)
    success_rows: Mapped[int]=mapped_column(Integer,default=0)
    error_rows: Mapped[int]=mapped_column(Integer,default=0)
    error_report_json: Mapped[list[dict[str,Any]]]=mapped_column(JSON,default=list)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class DataExportJob(Base):
    __tablename__='data_export_jobs'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('export'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str|None]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),nullable=True,index=True)
    entity_type: Mapped[str]=mapped_column(String(80),index=True)
    format: Mapped[str]=mapped_column(String(20),default='csv')
    filters_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    status: Mapped[str]=mapped_column(String(30),default='queued',index=True)
    output_uri: Mapped[str]=mapped_column(String(700),default='')
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class AdminAuditAction(Base):
    __tablename__='admin_audit_actions'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('adminaudit'))
    actor_id: Mapped[str]=mapped_column(ForeignKey('users.id',ondelete='SET NULL'),nullable=True,index=True)
    company_id: Mapped[str|None]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),nullable=True,index=True)
    action: Mapped[str]=mapped_column(String(100),index=True)
    details_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow,index=True)
