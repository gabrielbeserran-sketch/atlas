from __future__ import annotations
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session
from ..ai_governance_models import AiContextSnapshot, AiModelGovernance, AiRecommendationRecord, AiSupervisedAutomation
from ..authz import Principal, require_farm_scope, require_permission
from ..database import get_db
from ..innovation_models import AtlasBrainMemory
from ..models import new_id
from ..services.ai_operational_service import build_official_context, generate_recommendations
router=APIRouter(prefix='/ai-operational', tags=['AI Operational'])
class DecisionIn(BaseModel): decision:str; result:dict=Field(default_factory=dict)
class MemoryIn(BaseModel): area:str; title:str; summary:str=''; evidence:list=Field(default_factory=list); decision:dict=Field(default_factory=dict); result:dict=Field(default_factory=dict); confidence:float=0
class SimulationIn(BaseModel): sale_amount:float=0; extra_cost:float=0; investment:float=0; expected_return:float=0
class AutomationIn(BaseModel): recommendation_id:str|None=None; action_type:str; payload:dict=Field(default_factory=dict); requires_approval:bool=True; financial_limit:float=0
class ModelIn(BaseModel): model_key:str; version:str; owner:str; authorized_data:list=Field(default_factory=list); minimum_metrics:dict=Field(default_factory=dict); current_metrics:dict=Field(default_factory=dict); rollback_version:str=''

def principal_dep(p=Depends(require_permission('ai.read'))): return p
@router.post('/farms/{farm_id}/context')
def context(farm_id:str, period_days:int=90, db:Session=Depends(get_db), p:Principal=Depends(principal_dep)):
    require_farm_scope(p,farm_id)
    try: built=build_official_context(db,company_id=p.company.id,farm_id=farm_id,period_days=period_days)
    except ValueError as e: raise HTTPException(404,str(e))
    row=AiContextSnapshot(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=farm_id,context_hash=built['context_hash'],payload=built['payload'],quality=built['quality'],created_by=p.user.id)
    db.add(row); db.commit(); db.refresh(row)
    return {'id':row.id,**built}
@router.post('/farms/{farm_id}/recommendations')
def recommendations(farm_id:str, db:Session=Depends(get_db), p:Principal=Depends(principal_dep)):
    require_farm_scope(p,farm_id); built=build_official_context(db,company_id=p.company.id,farm_id=farm_id)
    snapshot=AiContextSnapshot(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=farm_id,context_hash=built['context_hash'],payload=built['payload'],quality=built['quality'],created_by=p.user.id); db.add(snapshot); db.flush()
    out=[]
    for item in generate_recommendations(built):
        row=AiRecommendationRecord(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=farm_id,context_snapshot_id=snapshot.id,area=item['area'],title=item['title'],description=item['description'],evidence=item['evidence'],limitations=item['limitations'],confidence=item['confidence'],priority=item['priority'],recommended_action=item['recommended_action'])
        db.add(row); db.flush(); out.append({'id':row.id,**item})
    db.commit(); return {'context_snapshot_id':snapshot.id,'recommendations':out}
@router.post('/recommendations/{recommendation_id}/decision')
def decision(recommendation_id:str, payload:DecisionIn, db:Session=Depends(get_db), p:Principal=Depends(principal_dep)):
    row=db.scalar(select(AiRecommendationRecord).where(AiRecommendationRecord.id==recommendation_id,AiRecommendationRecord.company_id==p.company.id));
    if not row: raise HTTPException(404,'Recomendação não encontrada.')
    if payload.decision not in {'accepted','rejected','deferred','completed'}: raise HTTPException(422,'Decisão inválida.')
    row.human_decision=payload.decision; row.observed_result=payload.result; row.decided_at=datetime.now(timezone.utc); db.commit(); return {'id':row.id,'decision':row.human_decision}
@router.post('/farms/{farm_id}/memory')
def memory(farm_id:str,payload:MemoryIn,db:Session=Depends(get_db),p:Principal=Depends(principal_dep)):
    require_farm_scope(p,farm_id); row=AtlasBrainMemory(company_id=p.company.id,tenant_id=p.company.tenant_id,farm_id=farm_id,area=payload.area,title=payload.title,summary=payload.summary,evidence_json=payload.evidence,decision_json=payload.decision,result_json=payload.result,confidence=payload.confidence); db.add(row); db.commit(); db.refresh(row); return {'id':row.id}
@router.post('/farms/{farm_id}/simulate')
def simulate(farm_id:str,payload:SimulationIn,p:Principal=Depends(principal_dep)):
    require_farm_scope(p,farm_id); net=payload.sale_amount+payload.expected_return-payload.extra_cost-payload.investment
    return {'farm_id':farm_id,'projected_variation':net,'roi_percent':round((payload.expected_return-payload.investment)/payload.investment*100,2) if payload.investment else None,'assumptions':payload.model_dump(),'confidence':0.7}
@router.post('/farms/{farm_id}/automations')
def create_automation(farm_id:str,payload:AutomationIn,db:Session=Depends(get_db),p:Principal=Depends(require_permission('automation.manage'))):
    require_farm_scope(p,farm_id); status='pending_approval' if payload.requires_approval else 'approved'; row=AiSupervisedAutomation(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=farm_id,recommendation_id=payload.recommendation_id,action_type=payload.action_type,payload=payload.payload,requires_approval=payload.requires_approval,financial_limit=payload.financial_limit,status=status); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}
@router.post('/automations/{automation_id}/approve')
def approve(automation_id:str,db:Session=Depends(get_db),p:Principal=Depends(require_permission('automation.manage'))):
    row=db.scalar(select(AiSupervisedAutomation).where(AiSupervisedAutomation.id==automation_id,AiSupervisedAutomation.company_id==p.company.id));
    if not row: raise HTTPException(404,'Automação não encontrada.')
    row.status='approved'; row.approved_by=p.user.id; row.approved_at=datetime.now(timezone.utc); db.commit(); return {'id':row.id,'status':row.status}
@router.post('/governance/models')
def register_model(payload:ModelIn,db:Session=Depends(get_db),p:Principal=Depends(require_permission('ai.manage'))):
    row=AiModelGovernance(tenant_id=p.company.tenant_id,company_id=p.company.id,model_key=payload.model_key,version=payload.version,owner=payload.owner,authorized_data=payload.authorized_data,minimum_metrics=payload.minimum_metrics,current_metrics=payload.current_metrics,rollback_version=payload.rollback_version); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}
@router.post('/governance/models/{model_id}/approve')
def approve_model(model_id:str,db:Session=Depends(get_db),p:Principal=Depends(require_permission('ai.manage'))):
    row=db.scalar(select(AiModelGovernance).where(AiModelGovernance.id==model_id,AiModelGovernance.company_id==p.company.id));
    if not row: raise HTTPException(404,'Modelo não encontrado.')
    missing=[k for k,v in row.minimum_metrics.items() if float(row.current_metrics.get(k,0))<float(v)]
    if missing: raise HTTPException(409,{'message':'Métricas mínimas não atendidas.','metrics':missing})
    row.status='approved'; row.approved_at=datetime.now(timezone.utc); db.commit(); return {'id':row.id,'status':row.status}
