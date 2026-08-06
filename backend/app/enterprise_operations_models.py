from __future__ import annotations
from datetime import datetime, timezone
from typing import Any
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Index, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column
from .database import Base
from .models import new_id

def utcnow():
    return datetime.now(timezone.utc)

class ConsultantVisit(Base):
    __tablename__='consultant_visits'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('visit'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),index=True)
    consultant_id: Mapped[str]=mapped_column(ForeignKey('users.id',ondelete='CASCADE'),index=True)
    scheduled_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow,index=True)
    status: Mapped[str]=mapped_column(String(30),default='scheduled',index=True)
    checklist_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    findings_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    action_plan_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    report_uri: Mapped[str]=mapped_column(String(700),default='')
    signed_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)

class FarmTeam(Base):
    __tablename__='farm_teams'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('team'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str|None]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),nullable=True,index=True)
    name: Mapped[str]=mapped_column(String(180))
    supervisor_id: Mapped[str|None]=mapped_column(ForeignKey('users.id',ondelete='SET NULL'),nullable=True)
    members_json: Mapped[list[str]]=mapped_column(JSON,default=list)
    active: Mapped[bool]=mapped_column(Boolean,default=True)

class AssetUsage(Base):
    __tablename__='asset_usage_records'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('usage'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),index=True)
    asset_id: Mapped[str]=mapped_column(ForeignKey('farm_assets.id',ondelete='CASCADE'),index=True)
    usage_type: Mapped[str]=mapped_column(String(50),index=True)
    meter_value: Mapped[float]=mapped_column(Float,default=0)
    cost: Mapped[float]=mapped_column(Float,default=0)
    occurred_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow,index=True)
    details_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)

class PurchaseRequest(Base):
    __tablename__='purchase_requests'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('purchase'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str|None]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),nullable=True,index=True)
    requester_id: Mapped[str]=mapped_column(ForeignKey('users.id',ondelete='CASCADE'))
    status: Mapped[str]=mapped_column(String(30),default='draft',index=True)
    items_json: Mapped[list[dict[str,Any]]]=mapped_column(JSON,default=list)
    quotations_json: Mapped[list[dict[str,Any]]]=mapped_column(JSON,default=list)
    approved_by: Mapped[str|None]=mapped_column(ForeignKey('users.id',ondelete='SET NULL'),nullable=True)
    total_amount: Mapped[float]=mapped_column(Float,default=0)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class SalesOpportunity(Base):
    __tablename__='sales_opportunities'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('sale'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str|None]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),nullable=True,index=True)
    customer_name: Mapped[str]=mapped_column(String(180))
    stage: Mapped[str]=mapped_column(String(40),default='proposal',index=True)
    reserved_entities_json: Mapped[list[dict[str,Any]]]=mapped_column(JSON,default=list)
    amount: Mapped[float]=mapped_column(Float,default=0)
    margin: Mapped[float]=mapped_column(Float,default=0)
    contract_uri: Mapped[str]=mapped_column(String(700),default='')
    logistics_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)

class CrmLead(Base):
    __tablename__='crm_leads'
    __table_args__=(Index('ix_crm_company_stage','company_id','stage'),)
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('lead'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    name: Mapped[str]=mapped_column(String(180))
    source: Mapped[str]=mapped_column(String(80),default='manual')
    stage: Mapped[str]=mapped_column(String(40),default='new')
    contact_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    estimated_value: Mapped[float]=mapped_column(Float,default=0)
    next_follow_up_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    converted_company_id: Mapped[str|None]=mapped_column(ForeignKey('companies.id',ondelete='SET NULL'),nullable=True)

class SupportTicket(Base):
    __tablename__='support_tickets_v2'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('ticket'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    requester_id: Mapped[str]=mapped_column(ForeignKey('users.id',ondelete='CASCADE'))
    title: Mapped[str]=mapped_column(String(220))
    description: Mapped[str]=mapped_column(Text,default='')
    priority: Mapped[str]=mapped_column(String(20),default='normal',index=True)
    status: Mapped[str]=mapped_column(String(30),default='open',index=True)
    sla_due_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    resolution: Mapped[str]=mapped_column(Text,default='')
    metadata_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)

class WorkflowDefinition(Base):
    __tablename__='enterprise_workflow_definitions'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('workflow'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    name: Mapped[str]=mapped_column(String(180))
    entity_type: Mapped[str]=mapped_column(String(80),index=True)
    steps_json: Mapped[list[dict[str,Any]]]=mapped_column(JSON,default=list)
    conditions_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    active: Mapped[bool]=mapped_column(Boolean,default=True)
    version: Mapped[int]=mapped_column(default=1)

class WorkflowInstance(Base):
    __tablename__='enterprise_workflow_instances'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('wfinst'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    definition_id: Mapped[str]=mapped_column(ForeignKey('enterprise_workflow_definitions.id',ondelete='CASCADE'),index=True)
    entity_id: Mapped[str]=mapped_column(String(80),index=True)
    current_step: Mapped[int]=mapped_column(default=0)
    status: Mapped[str]=mapped_column(String(30),default='running',index=True)
    history_json: Mapped[list[dict[str,Any]]]=mapped_column(JSON,default=list)

class EnterpriseDocument(Base):
    __tablename__='enterprise_documents'
    id: Mapped[str]=mapped_column(String(80),primary_key=True,default=lambda:new_id('document'))
    tenant_id: Mapped[str]=mapped_column(String(80),index=True)
    company_id: Mapped[str]=mapped_column(ForeignKey('companies.id',ondelete='CASCADE'),index=True)
    farm_id: Mapped[str|None]=mapped_column(ForeignKey('farms.id',ondelete='CASCADE'),nullable=True,index=True)
    title: Mapped[str]=mapped_column(String(220))
    category: Mapped[str]=mapped_column(String(80),index=True)
    storage_uri: Mapped[str]=mapped_column(String(700))
    version: Mapped[int]=mapped_column(default=1)
    tags_json: Mapped[list[str]]=mapped_column(JSON,default=list)
    permissions_json: Mapped[dict[str,Any]]=mapped_column(JSON,default=dict)
    expires_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    signed_at: Mapped[datetime|None]=mapped_column(DateTime(timezone=True),nullable=True)
    retention_policy: Mapped[str]=mapped_column(String(80),default='standard')
    created_at: Mapped[datetime]=mapped_column(DateTime(timezone=True),default=utcnow)
