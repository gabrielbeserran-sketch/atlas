from __future__ import annotations
from datetime import datetime, timezone
from typing import Any
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Index, JSON, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column
from .database import Base
from .models import new_id

def utcnow(): return datetime.now(timezone.utc)

class AnimalRfidBinding(Base):
    __tablename__='animal_rfid_bindings'
    __table_args__=(UniqueConstraint('company_id','tag_code',name='uq_rfid_company_tag'),Index('ix_rfid_farm_animal','farm_id','animal_id'))
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('rfid'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),index=True)
    animal_id: Mapped[str]=mapped_column(ForeignKey('livestock_animals.id',ondelete='CASCADE'),index=True)
    tag_code: Mapped[str]=mapped_column(String(180),index=True)
    active: Mapped[bool]=mapped_column(Boolean,default=True)
    bound_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class DeviceAdapter(Base):
    __tablename__='precision_device_adapters'
    __table_args__=(UniqueConstraint('company_id','adapter_key',name='uq_precision_adapter_key'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('adapter'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    adapter_key: Mapped[str]=mapped_column(String(120),index=True)
    manufacturer: Mapped[str]=mapped_column(String(180),default='')
    protocol: Mapped[str]=mapped_column(String(60),default='http-json')
    configuration_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    secret_hash: Mapped[str]=mapped_column(String(128),default='')
    active: Mapped[bool]=mapped_column(Boolean,default=True)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class PrecisionEvent(Base):
    __tablename__='precision_events'
    __table_args__=(Index('ix_precision_event_farm_type_time','farm_id','event_type','occurred_at'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('pevent'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),index=True)
    device_id: Mapped[str|None]=mapped_column(ForeignKey('atlas_iot_devices_v2.id',ondelete='SET NULL'),nullable=True,index=True)
    animal_id: Mapped[str|None]=mapped_column(ForeignKey('livestock_animals.id',ondelete='SET NULL'),nullable=True,index=True)
    event_type: Mapped[str]=mapped_column(String(80),index=True)
    severity: Mapped[str]=mapped_column(String(20),default='info',index=True)
    payload_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    occurred_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow,index=True)

class PrecisionGeoFence(Base):
    __tablename__='precision_geofences'
    __table_args__=(Index('ix_precision_geofence_farm_active','farm_id','active'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('geofence'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),index=True)
    name: Mapped[str]=mapped_column(String(180))
    polygon_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    rule_type: Mapped[str]=mapped_column(String(30),default='inside')
    active: Mapped[bool]=mapped_column(Boolean,default=True)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class VisionHumanReview(Base):
    __tablename__='vision_human_reviews'
    __table_args__=(UniqueConstraint('analysis_id',name='uq_vision_review_analysis'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('vreview'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    analysis_id: Mapped[str]=mapped_column(ForeignKey('atlas_vision_analyses.id',ondelete='CASCADE'),index=True)
    reviewer_id: Mapped[str]=mapped_column(ForeignKey('users.id',ondelete='CASCADE'),index=True)
    decision: Mapped[str]=mapped_column(String(30),index=True)
    corrected_result_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    notes: Mapped[str]=mapped_column(Text,default='')
    reviewed_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class RemoteSensingScene(Base):
    __tablename__='remote_sensing_scenes'
    __table_args__=(Index('ix_remote_scene_farm_captured','farm_id','captured_at'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('scene'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),index=True)
    provider: Mapped[str]=mapped_column(String(100),default='manual')
    external_id: Mapped[str]=mapped_column(String(180),default='',index=True)
    captured_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow,index=True)
    cloud_percent: Mapped[float]=mapped_column(Float,default=0)
    indices_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    asset_uri: Mapped[str]=mapped_column(String(700),default='')
    status: Mapped[str]=mapped_column(String(30),default='registered',index=True)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)
