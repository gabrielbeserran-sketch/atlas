from __future__ import annotations
from datetime import datetime, timezone
from typing import Any
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, JSON, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column
from .database import Base
from .models import new_id

def utcnow(): return datetime.now(timezone.utc)

class SecurityRole(Base):
    __tablename__='security_roles_v2'
    __table_args__=(UniqueConstraint('company_id','code',name='uq_security_role_company_code'),)
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('role'))
    tenant_id:Mapped[str]=mapped_column(String(80),index=True); company_id:Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    code:Mapped[str]=mapped_column(String(100),index=True); name:Mapped[str]=mapped_column(String(180)); permissions_json:Mapped[list[str]]=mapped_column(JSON,default=list); farm_ids_json:Mapped[list[str]]=mapped_column(JSON,default=list); active:Mapped[bool]=mapped_column(Boolean,default=True)

class SecurityIncident(Base):
    __tablename__='security_incidents'
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('incident')); tenant_id:Mapped[str]=mapped_column(String(80),index=True); company_id:Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    category:Mapped[str]=mapped_column(String(100),index=True); severity:Mapped[str]=mapped_column(String(30),default='medium',index=True); status:Mapped[str]=mapped_column(String(30),default='open',index=True); details_json:Mapped[dict[str,Any]]=mapped_column(JSON,default=dict); detected_at:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow); resolved_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)

class ImmutableAuditRecord(Base):
    __tablename__='immutable_audit_records'
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('auditx')); tenant_id:Mapped[str]=mapped_column(String(80),index=True); company_id:Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True); actor_id:Mapped[str|None]=mapped_column(String(80),nullable=True,index=True); action:Mapped[str]=mapped_column(String(160),index=True); entity_type:Mapped[str]=mapped_column(String(100)); entity_id:Mapped[str]=mapped_column(String(100)); before_json:Mapped[dict[str,Any]]=mapped_column(JSON,default=dict); after_json:Mapped[dict[str,Any]]=mapped_column(JSON,default=dict); previous_hash:Mapped[str]=mapped_column(String(64),default=''); record_hash:Mapped[str]=mapped_column(String(64),unique=True,index=True); created_at:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow,index=True)

class PrivacyRequest(Base):
    __tablename__='compliance_privacy_requests'
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('privacy')); tenant_id:Mapped[str]=mapped_column(String(80),index=True); company_id:Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True); request_type:Mapped[str]=mapped_column(String(50),index=True); subject_reference:Mapped[str]=mapped_column(String(180),index=True); legal_basis:Mapped[str]=mapped_column(String(180),default=''); status:Mapped[str]=mapped_column(String(30),default='open',index=True); response_json:Mapped[dict[str,Any]]=mapped_column(JSON,default=dict); due_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True); completed_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True); created_at:Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class BackupExecution(Base):
    __tablename__='backup_executions_v2'
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('backup')); tenant_id:Mapped[str]=mapped_column(String(80),index=True); company_id:Mapped[str|None]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),nullable=True,index=True); backup_type:Mapped[str]=mapped_column(String(40),default='full'); status:Mapped[str]=mapped_column(String(30),default='scheduled',index=True); storage_uri:Mapped[str]=mapped_column(Text,default=''); encrypted:Mapped[bool]=mapped_column(Boolean,default=True); size_bytes:Mapped[int]=mapped_column(Integer,default=0); checksum:Mapped[str]=mapped_column(String(128),default=''); started_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True); completed_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True); restore_tested_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)

class AvailabilityTarget(Base):
    __tablename__='availability_targets'
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('slo')); service_name:Mapped[str]=mapped_column(String(120),unique=True,index=True); target_percent:Mapped[float]=mapped_column(Float,default=99.9); rpo_minutes:Mapped[int]=mapped_column(Integer,default=1440); rto_minutes:Mapped[int]=mapped_column(Integer,default=240); architecture_json:Mapped[dict[str,Any]]=mapped_column(JSON,default=dict); active:Mapped[bool]=mapped_column(Boolean,default=True)

class TranslationResource(Base):
    __tablename__='translation_resources'
    __table_args__=(UniqueConstraint('locale','resource_key',name='uq_translation_locale_key'),)
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('i18n')); locale:Mapped[str]=mapped_column(String(20),index=True); resource_key:Mapped[str]=mapped_column(String(240),index=True); value:Mapped[str]=mapped_column(Text); version:Mapped[int]=mapped_column(Integer,default=1); active:Mapped[bool]=mapped_column(Boolean,default=True)

class RegionalPolicy(Base):
    __tablename__='regional_policies'
    __table_args__=(UniqueConstraint('country_code','region_code','policy_type',name='uq_regional_policy'),)
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('regional')); country_code:Mapped[str]=mapped_column(String(3),index=True); region_code:Mapped[str]=mapped_column(String(40),default='*'); policy_type:Mapped[str]=mapped_column(String(100),index=True); settings_json:Mapped[dict[str,Any]]=mapped_column(JSON,default=dict); valid_from:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True); valid_to:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True); active:Mapped[bool]=mapped_column(Boolean,default=True)

class ComplianceCertification(Base):
    __tablename__='compliance_certifications_v2'
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('certx')); tenant_id:Mapped[str]=mapped_column(String(80),index=True); company_id:Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True); farm_id:Mapped[str|None]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),nullable=True,index=True); certification_type:Mapped[str]=mapped_column(String(120),index=True); issuer:Mapped[str]=mapped_column(String(180),default=''); status:Mapped[str]=mapped_column(String(30),default='preparation',index=True); checklist_json:Mapped[dict[str,Any]]=mapped_column(JSON,default=dict); evidence_json:Mapped[list[dict[str,Any]]]=mapped_column(JSON,default=list); expires_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)

class ContinuityPlan(Base):
    __tablename__='continuity_plans_v2'
    id:Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('continuity')); tenant_id:Mapped[str]=mapped_column(String(80),index=True); company_id:Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True); name:Mapped[str]=mapped_column(String(180)); severity_matrix_json:Mapped[dict[str,Any]]=mapped_column(JSON,default=dict); contacts_json:Mapped[list[dict[str,Any]]]=mapped_column(JSON,default=list); runbooks_json:Mapped[list[dict[str,Any]]]=mapped_column(JSON,default=list); status:Mapped[str]=mapped_column(String(30),default='draft'); last_exercised_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True); next_review_at:Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
