from __future__ import annotations
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session
from ..authz import Principal, require_farm_scope, require_permission
from ..database import get_db
from ..saas_growth_models import SaaSPlan,CompanySubscription,BillingInvoice,FeatureFlag,CommunicationTemplate,CommunicationDelivery,OnboardingProgress,DataImportJob,DataExportJob,AdminAuditAction

router=APIRouter(prefix='/saas-growth',tags=['SaaS Growth'])
def read_dep(p=Depends(require_permission('platform.read'))): return p
def manage_dep(p=Depends(require_permission('platform.manage'))): return p
class Payload(BaseModel):
    code:str=''; name:str=''; status:str=''; amount:float=0; farm_id:str|None=None
    data:dict=Field(default_factory=dict); items:list[dict]=Field(default_factory=list)

def now(): return datetime.now(timezone.utc)

@router.post('/plans')
def create_plan(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if not payload.code: raise HTTPException(422,'code obrigatório.')
    if db.scalar(select(SaaSPlan).where(SaaSPlan.code==payload.code)): raise HTTPException(409,'Plano já existe.')
    row=SaaSPlan(code=payload.code,name=payload.name or payload.code,price_monthly=payload.amount,limits_json=payload.data.get('limits',{}),features_json=payload.data.get('features',[]))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'code':row.code}

@router.post('/subscriptions')
def subscribe(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    plan=db.scalar(select(SaaSPlan).where(SaaSPlan.code==payload.code,SaaSPlan.active.is_(True)))
    if not plan: raise HTTPException(404,'Plano não encontrado.')
    row=db.scalar(select(CompanySubscription).where(CompanySubscription.company_id==p.company.id))
    if row is None:
        row=CompanySubscription(tenant_id=p.company.tenant_id,company_id=p.company.id,plan_id=plan.id)
        db.add(row)
    row.plan_id=plan.id; row.status=payload.status or 'active'; row.cancel_at_period_end=bool(payload.data.get('cancel_at_period_end',False)); row.provider=payload.data.get('provider','manual')
    db.add(AdminAuditAction(actor_id=p.user.id,company_id=p.company.id,action='subscription.updated',details_json={'plan':plan.code,'status':row.status}))
    db.commit(); db.refresh(row); return {'id':row.id,'status':row.status,'plan_code':plan.code}

@router.post('/invoices')
def invoice(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    number=payload.data.get('number') or f"INV-{int(now().timestamp())}-{p.company.id[-6:]}"
    discount=max(0,float(payload.data.get('discount',0))); tax=max(0,float(payload.data.get('tax',0)))
    row=BillingInvoice(tenant_id=p.company.tenant_id,company_id=p.company.id,number=number,status=payload.status or 'open',amount=max(0,payload.amount),discount=discount,tax=tax,currency=payload.data.get('currency','BRL'),due_at=payload.data.get('due_at'),provider_payload_json=payload.data.get('provider_payload',{}))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'number':row.number,'total':max(0,row.amount-row.discount+row.tax)}

@router.post('/feature-flags')
def feature_flag(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if not payload.code: raise HTTPException(422,'code obrigatório.')
    row=FeatureFlag(key=payload.code,description=payload.data.get('description',''),enabled=bool(payload.data.get('enabled',False)),company_id=payload.data.get('global',False) and None or p.company.id,plan_code=payload.data.get('plan_code'),rollout_percent=max(0,min(100,int(payload.data.get('rollout_percent',100)))))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'key':row.key,'enabled':row.enabled}

@router.get('/feature-flags/effective')
def effective_flags(db:Session=Depends(get_db),p:Principal=Depends(read_dep)):
    rows=db.scalars(select(FeatureFlag).where((FeatureFlag.company_id.is_(None))|(FeatureFlag.company_id==p.company.id))).all()
    return {'flags':{r.key:r.enabled for r in rows}}

@router.post('/communications/templates')
def communication_template(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=CommunicationTemplate(tenant_id=p.company.tenant_id,company_id=p.company.id,channel=payload.data.get('channel','email'),code=payload.code or payload.name,subject=payload.data.get('subject',''),body=payload.data.get('body',''))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'code':row.code}

@router.post('/communications/deliveries')
def communication_delivery(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    recipient=payload.data.get('recipient','')
    if not recipient: raise HTTPException(422,'recipient obrigatório.')
    row=CommunicationDelivery(tenant_id=p.company.tenant_id,company_id=p.company.id,template_id=payload.data.get('template_id'),channel=payload.data.get('channel','email'),recipient=recipient,status='queued',payload_json=payload.data)
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}

@router.post('/onboarding')
def onboarding(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=db.scalar(select(OnboardingProgress).where(OnboardingProgress.company_id==p.company.id))
    steps={str(k):bool(v) for k,v in payload.data.get('steps',{}).items()}
    percent=(sum(1 for v in steps.values() if v)/len(steps)*100) if steps else 0
    if row is None: row=OnboardingProgress(tenant_id=p.company.tenant_id,company_id=p.company.id)
    row.steps_json=steps; row.completion_percent=percent; row.completed_at=now() if percent==100 else None
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'completion_percent':row.completion_percent}

@router.post('/imports')
def create_import(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if payload.farm_id: require_farm_scope(p,payload.farm_id)
    uri=payload.data.get('source_uri','')
    if not uri: raise HTTPException(422,'source_uri obrigatório.')
    preview=payload.data.get('preview',[])[:100]
    row=DataImportJob(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=payload.farm_id,entity_type=payload.code or 'animals',source_uri=uri,mapping_json=payload.data.get('mapping',{}),preview_json=preview,status='validated' if preview else 'draft',total_rows=int(payload.data.get('total_rows',len(preview))))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status,'preview_rows':len(preview)}

@router.post('/exports')
def create_export(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if payload.farm_id: require_farm_scope(p,payload.farm_id)
    fmt=payload.data.get('format','csv').lower()
    if fmt not in {'csv','xlsx','pdf','json'}: raise HTTPException(422,'Formato inválido.')
    row=DataExportJob(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=payload.farm_id,entity_type=payload.code or 'animals',format=fmt,filters_json=payload.data.get('filters',{}))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status,'format':row.format}

@router.get('/client-portal')
def client_portal(db:Session=Depends(get_db),p:Principal=Depends(read_dep)):
    sub=db.scalar(select(CompanySubscription).where(CompanySubscription.company_id==p.company.id))
    invoices=db.scalar(select(func.count()).select_from(BillingInvoice).where(BillingInvoice.company_id==p.company.id)) or 0
    onboarding=db.scalar(select(OnboardingProgress).where(OnboardingProgress.company_id==p.company.id))
    return {'company_id':p.company.id,'subscription_status':sub.status if sub else 'none','invoice_count':invoices,'onboarding_percent':onboarding.completion_percent if onboarding else 0}

@router.get('/admin/dashboard')
def admin_dashboard(db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    count=lambda m: db.scalar(select(func.count()).select_from(m)) or 0
    return {'plans':count(SaaSPlan),'subscriptions':count(CompanySubscription),'invoices':count(BillingInvoice),'feature_flags':count(FeatureFlag),'deliveries':count(CommunicationDelivery),'imports':count(DataImportJob),'exports':count(DataExportJob)}
