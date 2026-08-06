from __future__ import annotations
from datetime import datetime, timezone
from typing import Any
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Index, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column
from .database import Base
from .models import new_id

def utcnow(): return datetime.now(timezone.utc)

class AtlasBrainMemory(Base):
    __tablename__='atlas_brain_memories'
    __table_args__=(Index('ix_brain_memory_company_farm_area','company_id','farm_id','area'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('brainmem'))
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    farm_id: Mapped[str]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),index=True)
    area: Mapped[str]=mapped_column(String(40),index=True)
    title: Mapped[str]=mapped_column(String(180))
    summary: Mapped[str]=mapped_column(Text,default='')
    evidence_json: Mapped[list[Any]]=mapped_column(JSON,default=list)
    decision_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    result_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    confidence: Mapped[float]=mapped_column(Float,default=0)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class AtlasBrainPlan(Base):
    __tablename__='atlas_brain_plans'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('brainplan'))
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    farm_id: Mapped[str]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),index=True)
    horizon: Mapped[str]=mapped_column(String(30),default='weekly')
    title: Mapped[str]=mapped_column(String(180))
    items_json: Mapped[list[Any]]=mapped_column(JSON,default=list)
    priority_score: Mapped[float]=mapped_column(Float,default=0)
    status: Mapped[str]=mapped_column(String(30),default='active')
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class AtlasVisionAnalysis(Base):
    __tablename__='atlas_vision_analyses'
    __table_args__=(Index('ix_vision_company_farm_type_created','company_id','farm_id','analysis_type','created_at'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('vision'))
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    farm_id: Mapped[str]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),index=True)
    animal_id: Mapped[str|None]=mapped_column(ForeignKey('livestock_animals.id',ondelete='SET NULL'),nullable=True,index=True)
    analysis_type: Mapped[str]=mapped_column(String(50),index=True)
    media_url: Mapped[str]=mapped_column(String(600),default='')
    input_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    result_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    confidence: Mapped[float]=mapped_column(Float,default=0)
    model_version: Mapped[str]=mapped_column(String(80),default='rules-v1')
    status: Mapped[str]=mapped_column(String(30),default='processed')
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class AtlasIotDevice(Base):
    __tablename__='atlas_iot_devices_v2'
    __table_args__=(Index('ix_iot_device_company_farm_type','company_id','farm_id','device_type'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('iotdev'))
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    farm_id: Mapped[str]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),index=True)
    name: Mapped[str]=mapped_column(String(180))
    device_type: Mapped[str]=mapped_column(String(50),index=True)
    external_id: Mapped[str]=mapped_column(String(180),default='',index=True)
    status: Mapped[str]=mapped_column(String(30),default='offline',index=True)
    configuration_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    last_seen_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    active: Mapped[bool]=mapped_column(Boolean,default=True)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class AtlasIotTelemetry(Base):
    __tablename__='atlas_iot_telemetry_v2'
    __table_args__=(Index('ix_iot_telemetry_device_occurred','device_id','occurred_at'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('telemetry'))
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    farm_id: Mapped[str]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),index=True)
    device_id: Mapped[str]=mapped_column(ForeignKey('atlas_iot_devices_v2.id',ondelete='CASCADE'),index=True)
    metric: Mapped[str]=mapped_column(String(80),index=True)
    value: Mapped[float]=mapped_column(Float)
    unit: Mapped[str]=mapped_column(String(30),default='')
    payload_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    occurred_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow,index=True)

class AtlasCloudJob(Base):
    __tablename__='atlas_cloud_jobs'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('cloudjob'))
    company_id: Mapped[str|None]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),nullable=True,index=True)
    tenant_id: Mapped[str]=mapped_column(String(80),default='',index=True)
    job_type: Mapped[str]=mapped_column(String(60),index=True)
    queue_name: Mapped[str]=mapped_column(String(80),default='default')
    status: Mapped[str]=mapped_column(String(30),default='pending',index=True)
    payload_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    result_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    attempts: Mapped[int]=mapped_column(Integer,default=0)
    scheduled_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)
    started_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    finished_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class AtlasWebWorkspace(Base):
    __tablename__='atlas_web_workspaces'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('workspace'))
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    user_id: Mapped[str|None]=mapped_column(ForeignKey('users.id',ondelete='SET NULL'),nullable=True,index=True)
    portal_type: Mapped[str]=mapped_column(String(40),default='producer')
    layout_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    widgets_json: Mapped[list[Any]]=mapped_column(JSON,default=list)
    preferences_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    updated_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow,onupdate=utcnow)
