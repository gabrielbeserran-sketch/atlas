from __future__ import annotations
import hashlib, secrets
from datetime import datetime, timedelta, timezone
from typing import Any
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session
from ..authz import require_permission
from ..database import get_db
from ..dependencies import get_current_context
from ..enterprise_product_models import *

router=APIRouter(prefix='/sprints-16-20',tags=['sprints-16-20'])

def now(): return datetime.now(timezone.utc)
def ctx_values(ctx):
    company=getattr(ctx,'company',None); user=getattr(ctx,'user',None)
    return getattr(company,'id',''), getattr(company,'tenant_id',''), getattr(user,'id',None)

class SubscriptionIn(BaseModel):
    plan_code:str='professional'; billing_cycle:str='monthly'; amount:float=0; provider:str='manual'; email:str=''
class PublicAppIn(BaseModel):
    name:str; scopes:list[str]=Field(default_factory=lambda:['read']); rate_limit_per_minute:int=60
class AnalyticsDatasetIn(BaseModel):
    name:str; grain:str='daily'; dimensions:list[str]=Field(default_factory=list); measures:list[str]=Field(default_factory=list)
class AnalyticsFactIn(BaseModel):
    dataset_id:str; farm_id:str|None=None; period_start:datetime; period_end:datetime; dimensions:dict[str,Any]=Field(default_factory=dict); measures:dict[str,Any]=Field(default_factory=dict)
class MlModelIn(BaseModel):
    name:str; task_type:str; version:str='1.0.0'; artifact_uri:str=''; feature_schema:dict[str,Any]=Field(default_factory=dict); metrics:dict[str,Any]=Field(default_factory=dict); training_data:dict[str,Any]=Field(default_factory=dict)
class MlPredictionIn(BaseModel):
    farm_id:str|None=None; animal_id:str|None=None; features:dict[str,Any]=Field(default_factory=dict)
class ReleaseIn(BaseModel):
    version:str; channel:str='staging'; notes:str=''

@router.get('/dashboard')
def dashboard(db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission('platform.read'))):
    cid,tid,_uid=ctx_values(ctx)
    def count(model): return db.scalar(select(func.count()).select_from(model).where(model.company_id==cid)) or 0
    sub=db.scalar(select(AtlasBillingSubscription).where(AtlasBillingSubscription.company_id==cid).order_by(AtlasBillingSubscription.created_at.desc()))
    return {'billing':{'subscription_status':sub.status if sub else 'none','plan_code':sub.plan_code if sub else 'none','events':count(AtlasBillingEvent)},'public_api':{'apps':count(AtlasPublicApiApp),'events':count(AtlasPublicApiEvent)},'analytics':{'datasets':count(AtlasAnalyticsDataset),'facts':count(AtlasAnalyticsFact)},'machine_learning':{'models':count(AtlasMlModelRegistry),'predictions':count(AtlasMlPrediction)},'enterprise_1_0':enterprise_readiness(db,ctx)}

@router.post('/billing/subscriptions')
def create_subscription(payload:SubscriptionIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission('platform.manage'))):
    cid,tid,_=ctx_values(ctx)
    customer=db.scalar(select(AtlasBillingCustomer).where(AtlasBillingCustomer.company_id==cid))
    if not customer:
        customer=AtlasBillingCustomer(company_id=cid,tenant_id=tid,provider=payload.provider,email=payload.email); db.add(customer); db.flush()
    sub=AtlasBillingSubscription(company_id=cid,tenant_id=tid,customer_id=customer.id,provider=payload.provider,plan_code=payload.plan_code,billing_cycle=payload.billing_cycle,amount=payload.amount,status='trial',current_period_start=now(),current_period_end=now()+timedelta(days=30 if payload.billing_cycle=='monthly' else 365))
    db.add(sub); db.commit(); db.refresh(sub); return {'id':sub.id,'status':sub.status,'plan_code':sub.plan_code,'provider':sub.provider}

@router.post('/billing/webhooks/{provider}')
def billing_webhook(provider:str,payload:dict[str,Any],db:Session=Depends(get_db),ctx=Depends(get_current_context)):
    cid,tid,_=ctx_values(ctx); ext=str(payload.get('id',''))
    event=AtlasBillingEvent(company_id=cid,tenant_id=tid,provider=provider,event_type=str(payload.get('type','unknown')),external_id=ext,payload_json=payload,processed=False)
    db.add(event); db.commit(); return {'accepted':True,'event_id':event.id,'processed':False,'note':'Provider signature validation must be enabled before production.'}

@router.post('/public-api/apps')
def create_public_app(payload:PublicAppIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission('platform.manage'))):
    cid,tid,_=ctx_values(ctx); secret=secrets.token_urlsafe(32); client_id='atlas_'+secrets.token_hex(10)
    app=AtlasPublicApiApp(company_id=cid,tenant_id=tid,name=payload.name,client_id=client_id,client_secret_hash=hashlib.sha256(secret.encode()).hexdigest(),scopes_json=payload.scopes,rate_limit_per_minute=max(1,payload.rate_limit_per_minute))
    db.add(app); db.commit(); return {'id':app.id,'client_id':client_id,'client_secret':secret,'scopes':payload.scopes,'warning':'The secret is displayed only once.'}

@router.get('/public-api/openapi-contract')
def public_openapi_contract(ctx=Depends(get_current_context),_=Depends(require_permission('platform.read'))):
    return {'authentication':'OAuth2 client credentials contract','rate_limits':'per application','webhooks':'signed delivery contract','events':['animal.created','animal.updated','weight.created','health.created','finance.created'],'sdk_targets':['dart','python','typescript'],'developer_portal':'prepared'}

@router.post('/analytics/datasets')
def create_dataset(payload:AnalyticsDatasetIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission('platform.manage'))):
    cid,tid,_=ctx_values(ctx); row=AtlasAnalyticsDataset(company_id=cid,tenant_id=tid,name=payload.name,grain=payload.grain,dimensions_json=payload.dimensions,measures_json=payload.measures); db.add(row); db.commit(); return {'id':row.id,'name':row.name}

@router.post('/analytics/facts')
def create_fact(payload:AnalyticsFactIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission('platform.manage'))):
    cid,tid,_=ctx_values(ctx); ds=db.get(AtlasAnalyticsDataset,payload.dataset_id)
    if not ds or ds.company_id!=cid: raise HTTPException(404,'Dataset not found')
    row=AtlasAnalyticsFact(company_id=cid,tenant_id=tid,dataset_id=ds.id,farm_id=payload.farm_id,period_start=payload.period_start,period_end=payload.period_end,dimensions_json=payload.dimensions,measures_json=payload.measures); db.add(row); db.commit(); return {'id':row.id}

@router.get('/analytics/kpis')
def analytics_kpis(dataset_id:str|None=Query(None),db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission('platform.read'))):
    cid,tid,_=ctx_values(ctx); q=select(AtlasAnalyticsFact).where(AtlasAnalyticsFact.company_id==cid)
    if dataset_id:q=q.where(AtlasAnalyticsFact.dataset_id==dataset_id)
    rows=list(db.scalars(q.order_by(AtlasAnalyticsFact.period_start.desc()).limit(500)))
    totals={}
    for r in rows:
        for k,v in (r.measures_json or {}).items():
            if isinstance(v,(int,float)): totals[k]=totals.get(k,0)+v
    return {'facts':len(rows),'totals':totals,'forecast':{'method':'historical_run_rate','status':'available_when_time_series_is_sufficient'},'exports':['json','csv','power_bi_contract']}

@router.post('/ml/models')
def register_model(payload:MlModelIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission('platform.manage'))):
    cid,tid,_=ctx_values(ctx); row=AtlasMlModelRegistry(company_id=cid,tenant_id=tid,name=payload.name,task_type=payload.task_type,version=payload.version,artifact_uri=payload.artifact_uri,feature_schema_json=payload.feature_schema,metrics_json=payload.metrics,training_data_json=payload.training_data,status='draft'); db.add(row); db.commit(); return {'id':row.id,'status':row.status,'task_type':row.task_type}

@router.patch('/ml/models/{model_id}/approve')
def approve_model(model_id:str,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission('platform.manage'))):
    cid,_,_=ctx_values(ctx); row=db.get(AtlasMlModelRegistry,model_id)
    if not row or row.company_id!=cid: raise HTTPException(404,'Model not found')
    if not row.artifact_uri or not row.metrics_json: raise HTTPException(409,'Artifact and validation metrics are required')
    row.status='approved'; row.approved_at=now(); db.commit(); return {'id':row.id,'status':row.status}

@router.post('/ml/models/{model_id}/predict')
def predict(model_id:str,payload:MlPredictionIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission('platform.read'))):
    cid,tid,_=ctx_values(ctx); model=db.get(AtlasMlModelRegistry,model_id)
    if not model or model.company_id!=cid: raise HTTPException(404,'Model not found')
    if model.status!='approved': raise HTTPException(409,'Only approved models can produce production predictions')
    if not model.artifact_uri: raise HTTPException(503,'Inference artifact is not configured')
    raise HTTPException(501,'Inference adapter must be configured for this artifact URI')

@router.post('/enterprise/releases')
def create_release(payload:ReleaseIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission('platform.manage'))):
    checklist=[{'key':'tests','status':'pending'},{'key':'security','status':'pending'},{'key':'lgpd','status':'pending'},{'key':'android','status':'manual_pending'},{'key':'ios','status':'manual_pending'},{'key':'staging','status':'pending'},{'key':'pilot','status':'pending'}]
    row=AtlasEnterpriseRelease(version=payload.version,channel=payload.channel,status='draft',checklist_json=checklist,notes=payload.notes); db.add(row); db.commit(); return {'id':row.id,'version':row.version,'status':row.status,'checklist':checklist}

def enterprise_readiness(db:Session,ctx):
    cid,tid,_=ctx_values(ctx)
    sub=db.scalar(select(AtlasBillingSubscription).where(AtlasBillingSubscription.company_id==cid).order_by(AtlasBillingSubscription.created_at.desc()))
    approved=db.scalar(select(func.count()).select_from(AtlasMlModelRegistry).where(AtlasMlModelRegistry.company_id==cid,AtlasMlModelRegistry.status=='approved')) or 0
    checks=[{'key':'billing','status':'ready' if sub else 'pending'},{'key':'public_api','status':'ready'},{'key':'analytics','status':'ready'},{'key':'ml_governance','status':'ready' if approved else 'prepared'},{'key':'lgpd','status':'manual_review_required'},{'key':'android_store','status':'manual_pending'},{'key':'ios_store','status':'manual_pending'},{'key':'pilot','status':'manual_pending'}]
    score=round(sum(1 for c in checks if c['status']=='ready')/len(checks)*100)
    return {'version':'1.0.0','score':score,'checks':checks,'release_status':'not_released'}

@router.get('/enterprise/readiness')
def readiness(db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission('platform.read'))): return enterprise_readiness(db,ctx)
