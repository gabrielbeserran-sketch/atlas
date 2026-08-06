from __future__ import annotations
from datetime import datetime, timezone
from typing import Any
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Index, Integer, JSON, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column
from .database import Base
from .models import new_id

def utcnow(): return datetime.now(timezone.utc)

class DomainEventOutbox(Base):
    __tablename__='domain_event_outbox'
    __table_args__=(Index('ix_outbox_pending','status','occurred_at'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('event'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str|None]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),nullable=True,index=True)
    event_type: Mapped[str]=mapped_column(String(160),index=True)
    aggregate_type: Mapped[str]=mapped_column(String(100),index=True)
    aggregate_id: Mapped[str]=mapped_column(String(100),index=True)
    payload_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    idempotency_key: Mapped[str]=mapped_column(String(180),unique=True,index=True)
    status: Mapped[str]=mapped_column(String(30),default='pending',index=True)
    attempts: Mapped[int]=mapped_column(Integer,default=0)
    occurred_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow,index=True)
    published_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    last_error: Mapped[str]=mapped_column(Text,default='')

class DeadLetterEvent(Base):
    __tablename__='dead_letter_events'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('deadletter'))
    event_id: Mapped[str]=mapped_column(String(80),index=True)
    event_type: Mapped[str]=mapped_column(String(160),index=True)
    payload_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    error: Mapped[str]=mapped_column(Text,default='')
    failed_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class WarehouseDimension(Base):
    __tablename__='warehouse_dimensions'
    __table_args__=(UniqueConstraint('company_id','dimension_type','natural_key',name='uq_warehouse_dimension'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('dimension'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    dimension_type: Mapped[str]=mapped_column(String(80),index=True)
    natural_key: Mapped[str]=mapped_column(String(160),index=True)
    attributes_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    valid_from: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)
    valid_to: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)

class WarehouseFact(Base):
    __tablename__='warehouse_facts'
    __table_args__=(Index('ix_warehouse_fact_lookup','company_id','fact_type','occurred_at'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('fact'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str|None]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),nullable=True,index=True)
    fact_type: Mapped[str]=mapped_column(String(100),index=True)
    dimensions_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    measures_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    source_event_id: Mapped[str|None]=mapped_column(String(80),nullable=True,index=True)
    occurred_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow,index=True)

class KPIDefinition(Base):
    __tablename__='kpi_definitions'
    __table_args__=(UniqueConstraint('code','version',name='uq_kpi_code_version'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('kpi'))
    code: Mapped[str]=mapped_column(String(100),index=True)
    name: Mapped[str]=mapped_column(String(180))
    domain: Mapped[str]=mapped_column(String(80),index=True)
    version: Mapped[int]=mapped_column(Integer,default=1)
    formula: Mapped[str]=mapped_column(Text)
    source_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    periodicity: Mapped[str]=mapped_column(String(30),default='monthly')
    owner: Mapped[str]=mapped_column(String(160),default='')
    minimum_quality: Mapped[float]=mapped_column(Float,default=0.8)
    active: Mapped[bool]=mapped_column(Boolean,default=True)

class KPIObservation(Base):
    __tablename__='kpi_observations'
    __table_args__=(Index('ix_kpi_observation','company_id','kpi_code','period_end'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('kpiobs'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str|None]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),nullable=True,index=True)
    kpi_code: Mapped[str]=mapped_column(String(100),index=True)
    value: Mapped[float]=mapped_column(Float)
    period_start: Mapped[datetime]=mapped_column(DateTime(timezone=True))
    period_end: Mapped[datetime]=mapped_column(DateTime(timezone=True),index=True)
    quality_score: Mapped[float]=mapped_column(Float,default=1)
    dimensions_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)

class BenchmarkCohort(Base):
    __tablename__='benchmark_cohorts'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('cohort'))
    code: Mapped[str]=mapped_column(String(100),unique=True,index=True)
    description: Mapped[str]=mapped_column(Text,default='')
    filters_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    minimum_sample_size: Mapped[int]=mapped_column(Integer,default=5)
    active: Mapped[bool]=mapped_column(Boolean,default=True)

class BenchmarkSnapshot(Base):
    __tablename__='benchmark_snapshots'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('benchmark'))
    cohort_id: Mapped[str]=mapped_column(ForeignKey('benchmark_cohorts.id',ondelete='CASCADE'),index=True)
    kpi_code: Mapped[str]=mapped_column(String(100),index=True)
    period_end: Mapped[datetime]=mapped_column(DateTime(timezone=True),index=True)
    sample_size: Mapped[int]=mapped_column(Integer)
    percentiles_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    generated_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class ReportDefinition(Base):
    __tablename__='report_definitions_v2'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('reportdef'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    name: Mapped[str]=mapped_column(String(180))
    metrics_json: Mapped[list[str]]=mapped_column(JSON,default=list)
    filters_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    groupings_json: Mapped[list[str]]=mapped_column(JSON,default=list)
    visualization_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    schedule: Mapped[str]=mapped_column(String(80),default='')
    active: Mapped[bool]=mapped_column(Boolean,default=True)

class RealtimeMetric(Base):
    __tablename__='realtime_metrics'
    __table_args__=(UniqueConstraint('company_id','metric_key','scope_key',name='uq_realtime_metric_scope'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('rtmetric'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    metric_key: Mapped[str]=mapped_column(String(120),index=True)
    scope_key: Mapped[str]=mapped_column(String(180),default='global')
    value: Mapped[float]=mapped_column(Float,default=0)
    version: Mapped[int]=mapped_column(Integer,default=1)
    updated_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow,index=True)

class CacheEntry(Base):
    __tablename__='distributed_cache_entries'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('cache'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    cache_key: Mapped[str]=mapped_column(String(240),index=True)
    value_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    expires_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),index=True)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class BackgroundJob(Base):
    __tablename__='background_jobs'
    __table_args__=(Index('ix_background_job_queue','status','available_at'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('job'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    job_type: Mapped[str]=mapped_column(String(120),index=True)
    payload_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    status: Mapped[str]=mapped_column(String(30),default='queued',index=True)
    attempts: Mapped[int]=mapped_column(Integer,default=0)
    max_attempts: Mapped[int]=mapped_column(Integer,default=5)
    available_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow,index=True)
    locked_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    completed_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    last_error: Mapped[str]=mapped_column(Text,default='')
