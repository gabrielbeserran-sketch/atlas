from __future__ import annotations
from datetime import datetime, timezone
from typing import Any
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, JSON, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column
from .database import Base
from .models import new_id

def utcnow(): return datetime.now(timezone.utc)

class ReleaseEnvironment(Base):
    __tablename__='release_environments_v2'
    __table_args__=(UniqueConstraint('company_id','code',name='uq_release_env_company_code'),)
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('env')); tenant_id:Mapped[str]=mapped_column(String(80),index=True); company_id:Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True); code:Mapped[str]=mapped_column(String(80)); name:Mapped[str]=mapped_column(String(180)); base_url:Mapped[str]=mapped_column(Text,default=''); configuration_json:Mapped[dict[str,Any]]=mapped_column(JSON,default=dict); status:Mapped[str]=mapped_column(String(30),default='preparing',index=True); smoke_tested_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True); approved_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)

class PilotProgram(Base):
    __tablename__='pilot_programs_v2'
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('pilot')); tenant_id:Mapped[str]=mapped_column(String(80),index=True); company_id:Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True); farm_id:Mapped[str|None]=mapped_column(ForeignKey('farms.id',ondelete='SET NULL'),nullable=True,index=True); pilot_type:Mapped[str]=mapped_column(String(30),index=True); name:Mapped[str]=mapped_column(String(180)); objectives_json:Mapped[list[str]]=mapped_column(JSON,default=list); metrics_json:Mapped[dict[str,Any]]=mapped_column(JSON,default=dict); findings_json:Mapped[list[dict[str,Any]]]=mapped_column(JSON,default=list); status:Mapped[str]=mapped_column(String(30),default='planned',index=True); started_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True); completed_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)

class MobileReleaseProfile(Base):
    __tablename__='mobile_release_profiles'
    __table_args__=(UniqueConstraint('platform','application_id',name='uq_mobile_platform_app'),)
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('mobile')); platform:Mapped[str]=mapped_column(String(20),index=True); application_id:Mapped[str]=mapped_column(String(180)); version_name:Mapped[str]=mapped_column(String(40)); build_number:Mapped[int]=mapped_column(Integer,default=1); signing_configured:Mapped[bool]=mapped_column(Boolean,default=False); privacy_url:Mapped[str]=mapped_column(Text,default=''); store_status:Mapped[str]=mapped_column(String(30),default='draft'); rollout_percent:Mapped[float]=mapped_column(Float,default=0); checklist_json:Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)

class WebRelease(Base):
    __tablename__='web_releases_v2'
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('webrel')); version:Mapped[str]=mapped_column(String(40),index=True); target:Mapped[str]=mapped_column(String(50),default='production'); features_json:Mapped[list[str]]=mapped_column(JSON,default=list); accessibility_score:Mapped[float]=mapped_column(Float,default=0); performance_score:Mapped[float]=mapped_column(Float,default=0); status:Mapped[str]=mapped_column(String(30),default='draft'); deployed_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)

class LearningPath(Base):
    __tablename__='learning_paths_v2'
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('learning')); code:Mapped[str]=mapped_column(String(100),unique=True,index=True); audience:Mapped[str]=mapped_column(String(80),index=True); title:Mapped[str]=mapped_column(String(180)); modules_json:Mapped[list[dict[str,Any]]]=mapped_column(JSON,default=list); certification_enabled:Mapped[bool]=mapped_column(Boolean,default=False); version:Mapped[int]=mapped_column(Integer,default=1); active:Mapped[bool]=mapped_column(Boolean,default=True)

class DocumentationPage(Base):
    __tablename__='documentation_pages_v2'
    __table_args__=(UniqueConstraint('slug','version',name='uq_doc_slug_version'),)
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('docpage')); slug:Mapped[str]=mapped_column(String(180),index=True); title:Mapped[str]=mapped_column(String(220)); category:Mapped[str]=mapped_column(String(80),index=True); version:Mapped[str]=mapped_column(String(40),default='3.0'); content_uri:Mapped[str]=mapped_column(Text,default=''); metadata_json:Mapped[dict[str,Any]]=mapped_column(JSON,default=dict); published:Mapped[bool]=mapped_column(Boolean,default=False); updated_at:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class GrowthExperiment(Base):
    __tablename__='growth_experiments_v2'
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('growth')); name:Mapped[str]=mapped_column(String(180)); persona:Mapped[str]=mapped_column(String(120)); hypothesis:Mapped[str]=mapped_column(Text); channel:Mapped[str]=mapped_column(String(80)); metrics_json:Mapped[dict[str,Any]]=mapped_column(JSON,default=dict); status:Mapped[str]=mapped_column(String(30),default='planned'); started_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True); completed_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)

class ProductCapabilityReview(Base):
    __tablename__='product_capability_reviews'
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('review')); capability_key:Mapped[str]=mapped_column(String(160),index=True); module:Mapped[str]=mapped_column(String(100),index=True); usage_score:Mapped[float]=mapped_column(Float,default=0); quality_score:Mapped[float]=mapped_column(Float,default=0); decision:Mapped[str]=mapped_column(String(30),default='keep'); notes:Mapped[str]=mapped_column(Text,default=''); reviewed_at:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class AtlasRoadmap(Base):
    __tablename__='atlas_roadmaps_v2'
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('roadmap')); name:Mapped[str]=mapped_column(String(180)); horizon_years:Mapped[int]=mapped_column(Integer,default=5); vision:Mapped[str]=mapped_column(Text); pillars_json:Mapped[list[dict[str,Any]]]=mapped_column(JSON,default=list); milestones_json:Mapped[list[dict[str,Any]]]=mapped_column(JSON,default=list); status:Mapped[str]=mapped_column(String(30),default='draft'); published_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)

class ReleaseReadinessAssessment(Base):
    __tablename__='release_readiness_assessments'
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('ready')); release_name:Mapped[str]=mapped_column(String(120),index=True); checks_json:Mapped[dict[str,bool]]=mapped_column(JSON,default=dict); blockers_json:Mapped[list[str]]=mapped_column(JSON,default=list); score:Mapped[float]=mapped_column(Float,default=0); status:Mapped[str]=mapped_column(String(30),default='blocked'); assessed_at:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)
