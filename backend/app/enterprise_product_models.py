from __future__ import annotations
from datetime import datetime, timezone
from typing import Any
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Index, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column
from .database import Base
from .models import new_id

def utcnow(): return datetime.now(timezone.utc)

class AtlasBillingCustomer(Base):
    __tablename__='atlas_billing_customers'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('billcust'))
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),unique=True,index=True)
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    provider: Mapped[str]=mapped_column(String(40),default='manual')
    provider_customer_id: Mapped[str]=mapped_column(String(180),default='')
    email: Mapped[str]=mapped_column(String(320),default='')
    tax_id: Mapped[str]=mapped_column(String(40),default='')
    metadata_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class AtlasBillingSubscription(Base):
    __tablename__='atlas_billing_subscriptions_v2'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('billsub'))
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    customer_id: Mapped[str|None]=mapped_column(ForeignKey('atlas_billing_customers.id',ondelete='SET NULL'),nullable=True)
    provider: Mapped[str]=mapped_column(String(40),default='manual')
    provider_subscription_id: Mapped[str]=mapped_column(String(180),default='')
    plan_code: Mapped[str]=mapped_column(String(50),default='pilot')
    billing_cycle: Mapped[str]=mapped_column(String(20),default='monthly')
    status: Mapped[str]=mapped_column(String(30),default='trial',index=True)
    amount: Mapped[float]=mapped_column(Float,default=0)
    currency: Mapped[str]=mapped_column(String(10),default='BRL')
    current_period_start: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    current_period_end: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    cancel_at_period_end: Mapped[bool]=mapped_column(Boolean,default=False)
    metadata_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class AtlasBillingEvent(Base):
    __tablename__='atlas_billing_events'
    __table_args__=(Index('ix_billing_event_company_created','company_id','created_at'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('billevt'))
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    provider: Mapped[str]=mapped_column(String(40),default='manual')
    event_type: Mapped[str]=mapped_column(String(80),index=True)
    external_id: Mapped[str]=mapped_column(String(180),default='',index=True)
    payload_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    processed: Mapped[bool]=mapped_column(Boolean,default=False)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class AtlasPublicApiApp(Base):
    __tablename__='atlas_public_api_apps'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('apiapp'))
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    name: Mapped[str]=mapped_column(String(180))
    client_id: Mapped[str]=mapped_column(String(120),unique=True,index=True)
    client_secret_hash: Mapped[str]=mapped_column(String(255))
    scopes_json: Mapped[list[Any]]=mapped_column(JSON,default=list)
    rate_limit_per_minute: Mapped[int]=mapped_column(Integer,default=60)
    active: Mapped[bool]=mapped_column(Boolean,default=True)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class AtlasPublicApiEvent(Base):
    __tablename__='atlas_public_api_events'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('apievt'))
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    event_name: Mapped[str]=mapped_column(String(120),index=True)
    resource_type: Mapped[str]=mapped_column(String(80),default='')
    resource_id: Mapped[str]=mapped_column(String(80),default='')
    payload_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    occurred_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow,index=True)

class AtlasAnalyticsDataset(Base):
    __tablename__='atlas_analytics_datasets_v2'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('dataset'))
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    name: Mapped[str]=mapped_column(String(180))
    grain: Mapped[str]=mapped_column(String(60),default='daily')
    dimensions_json: Mapped[list[Any]]=mapped_column(JSON,default=list)
    measures_json: Mapped[list[Any]]=mapped_column(JSON,default=list)
    retention_days: Mapped[int]=mapped_column(Integer,default=730)
    active: Mapped[bool]=mapped_column(Boolean,default=True)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class AtlasAnalyticsFact(Base):
    __tablename__='atlas_analytics_facts_v2'
    __table_args__=(Index('ix_analytics_fact_dataset_period','dataset_id','period_start'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('fact'))
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    dataset_id: Mapped[str]=mapped_column(ForeignKey('atlas_analytics_datasets_v2.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str|None]=mapped_column(ForeignKey('farms.id',ondelete='SET NULL'),nullable=True,index=True)
    period_start: Mapped[datetime]=mapped_column(DateTime(timezone=True),index=True)
    period_end: Mapped[datetime]=mapped_column(DateTime(timezone=True))
    dimensions_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    measures_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class AtlasMlModelRegistry(Base):
    __tablename__='atlas_ml_model_registry_v2'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('mlmodel'))
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    name: Mapped[str]=mapped_column(String(180))
    task_type: Mapped[str]=mapped_column(String(80),index=True)
    version: Mapped[str]=mapped_column(String(50),default='1.0.0')
    status: Mapped[str]=mapped_column(String(30),default='draft',index=True)
    artifact_uri: Mapped[str]=mapped_column(String(600),default='')
    feature_schema_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    metrics_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    training_data_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    approved_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class AtlasMlPrediction(Base):
    __tablename__='atlas_ml_predictions_v2'
    __table_args__=(Index('ix_ml_prediction_model_created','model_id','created_at'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('mlpred'))
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    model_id: Mapped[str]=mapped_column(ForeignKey('atlas_ml_model_registry_v2.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str|None]=mapped_column(ForeignKey('farms.id',ondelete='SET NULL'),nullable=True,index=True)
    animal_id: Mapped[str|None]=mapped_column(ForeignKey('livestock_animals.id',ondelete='SET NULL'),nullable=True,index=True)
    input_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    output_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    confidence: Mapped[float]=mapped_column(Float,default=0)
    explanation_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class AtlasEnterpriseRelease(Base):
    __tablename__='atlas_enterprise_releases'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('release'))
    version: Mapped[str]=mapped_column(String(50),unique=True,index=True)
    channel: Mapped[str]=mapped_column(String(30),default='staging')
    status: Mapped[str]=mapped_column(String(30),default='draft',index=True)
    checklist_json: Mapped[list[Any]]=mapped_column(JSON,default=list)
    artifacts_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    notes: Mapped[str]=mapped_column(Text,default='')
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)
