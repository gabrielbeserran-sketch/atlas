from __future__ import annotations
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session
from ..authz import Principal, require_farm_scope, require_permission
from ..database import get_db
from ..enterprise_operations_models import ConsultantVisit,FarmTeam,AssetUsage,PurchaseRequest,SalesOpportunity,CrmLead,SupportTicket,WorkflowDefinition,WorkflowInstance,EnterpriseDocument

router=APIRouter(prefix='/enterprise-operations',tags=['Enterprise Operations'])
def read_dep(p=Depends(require_permission('platform.read'))): return p
def manage_dep(p=Depends(require_permission('platform.manage'))): return p
class Payload(BaseModel):
    farm_id:str|None=None
    name:str=''
    title:str=''
    category:str='general'
    status:str='draft'
    amount:float=0
    data:dict=Field(default_factory=dict)
    items:list[dict]=Field(default_factory=list)
    tags:list[str]=Field(default_factory=list)

@router.post('/consulting/visits')
def create_visit(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if not payload.farm_id: raise HTTPException(422,'farm_id obrigatório.')
    require_farm_scope(p,payload.farm_id)
    row=ConsultantVisit(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=payload.farm_id,consultant_id=p.user.id,status=payload.status,checklist_json=payload.data.get('checklist',{}),findings_json=payload.data.get('findings',{}),action_plan_json=payload.data.get('action_plan',{}),report_uri=payload.data.get('report_uri',''))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}

@router.post('/teams')
def create_team(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if payload.farm_id: require_farm_scope(p,payload.farm_id)
    row=FarmTeam(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=payload.farm_id,name=payload.name or payload.title,supervisor_id=payload.data.get('supervisor_id'),members_json=payload.data.get('members',[]))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'active':row.active}

@router.post('/assets/usage')
def asset_usage(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if not payload.farm_id: raise HTTPException(422,'farm_id obrigatório.')
    require_farm_scope(p,payload.farm_id)
    row=AssetUsage(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=payload.farm_id,asset_id=payload.data.get('asset_id',''),usage_type=payload.data.get('usage_type','operation'),meter_value=float(payload.data.get('meter_value',0)),cost=float(payload.data.get('cost',0)),details_json=payload.data)
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id}

@router.post('/purchases')
def purchase(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if payload.farm_id: require_farm_scope(p,payload.farm_id)
    total=sum(float(x.get('quantity',0))*float(x.get('unit_price',0)) for x in payload.items)
    row=PurchaseRequest(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=payload.farm_id,requester_id=p.user.id,status=payload.status,items_json=payload.items,quotations_json=payload.data.get('quotations',[]),total_amount=total)
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'total_amount':row.total_amount}

@router.post('/sales')
def sale(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if payload.farm_id: require_farm_scope(p,payload.farm_id)
    row=SalesOpportunity(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=payload.farm_id,customer_name=payload.name or payload.title,stage=payload.status or 'proposal',reserved_entities_json=payload.items,amount=payload.amount,margin=float(payload.data.get('margin',0)),contract_uri=payload.data.get('contract_uri',''),logistics_json=payload.data.get('logistics',{}))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'stage':row.stage}

@router.post('/crm/leads')
def lead(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=CrmLead(tenant_id=p.company.tenant_id,company_id=p.company.id,name=payload.name or payload.title,source=payload.data.get('source','manual'),stage=payload.status or 'new',contact_json=payload.data.get('contact',{}),estimated_value=payload.amount,next_follow_up_at=payload.data.get('next_follow_up_at'))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'stage':row.stage}

@router.post('/support/tickets')
def ticket(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=SupportTicket(tenant_id=p.company.tenant_id,company_id=p.company.id,requester_id=p.user.id,title=payload.title or payload.name,description=payload.data.get('description',''),priority=payload.data.get('priority','normal'),status='open',sla_due_at=payload.data.get('sla_due_at'),metadata_json=payload.data)
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}

@router.post('/workflows/definitions')
def workflow(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=WorkflowDefinition(tenant_id=p.company.tenant_id,company_id=p.company.id,name=payload.name or payload.title,entity_type=payload.data.get('entity_type','generic'),steps_json=payload.data.get('steps',[]),conditions_json=payload.data.get('conditions',{}))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'version':row.version}

@router.post('/workflows/{definition_id}/start')
def start_workflow(definition_id:str,payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    definition=db.scalar(select(WorkflowDefinition).where(WorkflowDefinition.id==definition_id,WorkflowDefinition.company_id==p.company.id))
    if not definition: raise HTTPException(404,'Workflow não encontrado.')
    row=WorkflowInstance(tenant_id=p.company.tenant_id,company_id=p.company.id,definition_id=definition_id,entity_id=payload.data.get('entity_id',''),history_json=[{'event':'started','at':datetime.utcnow().isoformat(),'by':p.user.id}])
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}

@router.post('/documents')
def document(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if payload.farm_id: require_farm_scope(p,payload.farm_id)
    uri=payload.data.get('storage_uri','')
    if not uri: raise HTTPException(422,'storage_uri obrigatório.')
    row=EnterpriseDocument(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=payload.farm_id,title=payload.title or payload.name,category=payload.category,storage_uri=uri,tags_json=payload.tags,permissions_json=payload.data.get('permissions',{}),expires_at=payload.data.get('expires_at'),retention_policy=payload.data.get('retention_policy','standard'))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'version':row.version}

@router.get('/dashboard')
def dashboard(db:Session=Depends(get_db),p:Principal=Depends(read_dep)):
    c=p.company.id
    count=lambda model: db.scalar(select(func.count()).select_from(model).where(model.company_id==c)) or 0
    return {'consulting_visits':count(ConsultantVisit),'teams':count(FarmTeam),'asset_usage_records':count(AssetUsage),'purchase_requests':count(PurchaseRequest),'sales_opportunities':count(SalesOpportunity),'crm_leads':count(CrmLead),'support_tickets':count(SupportTicket),'workflow_definitions':count(WorkflowDefinition),'workflow_instances':count(WorkflowInstance),'documents':count(EnterpriseDocument)}
