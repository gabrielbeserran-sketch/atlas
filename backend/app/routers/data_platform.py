from __future__ import annotations
from datetime import datetime, timedelta, timezone
from hashlib import sha256
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import delete, func, select
from sqlalchemy.orm import Session
from ..authz import Principal, require_farm_scope, require_permission
from ..database import get_db
from ..data_platform_models import *
from ..services.data_platform_service import benchmark_percentiles, cache_get, claim_jobs, enqueue, retry_delay

router=APIRouter(prefix='/data-platform',tags=['Data Platform'])
def read_dep(p=Depends(require_permission('platform.read'))): return p
def manage_dep(p=Depends(require_permission('platform.manage'))): return p
def now(): return datetime.now(timezone.utc)
class Payload(BaseModel):
    code:str=''; name:str=''; farm_id:str|None=None; value:float=0; data:dict=Field(default_factory=dict); items:list[dict]=Field(default_factory=list)

@router.post('/events')
def create_event(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if payload.farm_id: require_farm_scope(p,payload.farm_id)
    event_type=payload.code or payload.data.get('event_type','')
    if not event_type: raise HTTPException(422,'event_type obrigatório.')
    idem=payload.data.get('idempotency_key') or sha256(f"{p.company.id}:{event_type}:{payload.data}".encode()).hexdigest()
    existing=db.scalar(select(DomainEventOutbox).where(DomainEventOutbox.idempotency_key==idem))
    if existing: return {'id':existing.id,'status':existing.status,'duplicate':True}
    row=DomainEventOutbox(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=payload.farm_id,event_type=event_type,aggregate_type=payload.data.get('aggregate_type','generic'),aggregate_id=payload.data.get('aggregate_id',''),payload_json=payload.data.get('payload',{}),idempotency_key=idem)
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status,'duplicate':False}

@router.post('/events/publish')
def publish_events(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    limit=max(1,min(500,int(payload.data.get('limit',100))))
    rows=list(db.scalars(select(DomainEventOutbox).where(DomainEventOutbox.company_id==p.company.id,DomainEventOutbox.status=='pending').order_by(DomainEventOutbox.occurred_at).limit(limit)).all())
    for row in rows: row.status='published'; row.published_at=now(); row.attempts+=1
    db.commit(); return {'published':len(rows)}

@router.post('/warehouse/dimensions')
def dimension(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    dtype=payload.code or payload.data.get('dimension_type',''); key=payload.data.get('natural_key','')
    if not dtype or not key: raise HTTPException(422,'dimension_type e natural_key são obrigatórios.')
    row=db.scalar(select(WarehouseDimension).where(WarehouseDimension.company_id==p.company.id,WarehouseDimension.dimension_type==dtype,WarehouseDimension.natural_key==key))
    if row is None: row=WarehouseDimension(tenant_id=p.company.tenant_id,company_id=p.company.id,dimension_type=dtype,natural_key=key)
    row.attributes_json=payload.data.get('attributes',{}); db.add(row); db.commit(); db.refresh(row); return {'id':row.id}

@router.post('/warehouse/facts')
def fact(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if payload.farm_id: require_farm_scope(p,payload.farm_id)
    row=WarehouseFact(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=payload.farm_id,fact_type=payload.code or 'generic',dimensions_json=payload.data.get('dimensions',{}),measures_json=payload.data.get('measures',{}),source_event_id=payload.data.get('source_event_id'))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id}

@router.post('/kpis/definitions')
def kpi_definition(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if not payload.code: raise HTTPException(422,'code obrigatório.')
    version=int(payload.data.get('version',1))
    if db.scalar(select(KPIDefinition).where(KPIDefinition.code==payload.code,KPIDefinition.version==version)): raise HTTPException(409,'Versão do KPI já existe.')
    row=KPIDefinition(code=payload.code,name=payload.name or payload.code,domain=payload.data.get('domain','general'),version=version,formula=payload.data.get('formula',''),source_json=payload.data.get('source',{}),periodicity=payload.data.get('periodicity','monthly'),owner=payload.data.get('owner',''),minimum_quality=max(0,min(1,float(payload.data.get('minimum_quality',.8)))))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'version':row.version}

@router.post('/kpis/observations')
def kpi_observation(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if payload.farm_id: require_farm_scope(p,payload.farm_id)
    end=payload.data.get('period_end') or now(); start=payload.data.get('period_start') or end
    row=KPIObservation(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=payload.farm_id,kpi_code=payload.code,value=payload.value,period_start=start,period_end=end,quality_score=max(0,min(1,float(payload.data.get('quality_score',1)))),dimensions_json=payload.data.get('dimensions',{}))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'value':row.value}

@router.post('/benchmarks/cohorts')
def cohort(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    minimum=max(5,int(payload.data.get('minimum_sample_size',5)))
    row=BenchmarkCohort(code=payload.code,description=payload.data.get('description',''),filters_json=payload.data.get('filters',{}),minimum_sample_size=minimum)
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'minimum_sample_size':minimum}

@router.post('/benchmarks/generate')
def generate_benchmark(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    cohort=db.scalar(select(BenchmarkCohort).where(BenchmarkCohort.code==payload.data.get('cohort_code')))
    if not cohort: raise HTTPException(404,'Coorte não encontrada.')
    rows=list(db.scalars(select(KPIObservation).where(KPIObservation.kpi_code==payload.code)).all())
    company_values={r.company_id:r.value for r in rows}
    if len(company_values)<cohort.minimum_sample_size: raise HTTPException(409,'Amostra insuficiente para benchmark anonimizado.')
    result=benchmark_percentiles(list(company_values.values()))
    snap=BenchmarkSnapshot(cohort_id=cohort.id,kpi_code=payload.code,period_end=now(),sample_size=len(company_values),percentiles_json=result)
    db.add(snap); db.commit(); db.refresh(snap); return {'id':snap.id,'sample_size':snap.sample_size,'percentiles':result}

@router.post('/reports')
def report(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=ReportDefinition(tenant_id=p.company.tenant_id,company_id=p.company.id,name=payload.name or 'Relatório',metrics_json=payload.data.get('metrics',[]),filters_json=payload.data.get('filters',{}),groupings_json=payload.data.get('groupings',[]),visualization_json=payload.data.get('visualization',{}),schedule=payload.data.get('schedule',''))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id}

@router.post('/realtime/metrics')
def realtime_metric(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    scope=payload.data.get('scope_key','global')
    row=db.scalar(select(RealtimeMetric).where(RealtimeMetric.company_id==p.company.id,RealtimeMetric.metric_key==payload.code,RealtimeMetric.scope_key==scope))
    if row is None: row=RealtimeMetric(tenant_id=p.company.tenant_id,company_id=p.company.id,metric_key=payload.code,scope_key=scope)
    row.value=payload.value; row.version+=1; row.updated_at=now(); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'version':row.version}

@router.get('/realtime/metrics')
def realtime_metrics(db:Session=Depends(get_db),p:Principal=Depends(read_dep)):
    rows=db.scalars(select(RealtimeMetric).where(RealtimeMetric.company_id==p.company.id)).all(); return {'metrics':[{'key':r.metric_key,'scope':r.scope_key,'value':r.value,'version':r.version} for r in rows]}

@router.post('/cache')
def cache_put(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    ttl=max(1,min(86400,int(payload.data.get('ttl_seconds',300))))
    db.execute(delete(CacheEntry).where(CacheEntry.company_id==p.company.id,CacheEntry.cache_key==payload.code))
    row=CacheEntry(tenant_id=p.company.tenant_id,company_id=p.company.id,cache_key=payload.code,value_json=payload.data.get('value',{}),expires_at=now()+timedelta(seconds=ttl))
    db.add(row); db.commit(); return {'key':row.cache_key,'expires_at':row.expires_at}

@router.get('/cache/{key}')
def cache_read(key:str,db:Session=Depends(get_db),p:Principal=Depends(read_dep)):
    value=cache_get(db,p.company.id,key)
    if value is None: raise HTTPException(404,'Cache ausente ou expirado.')
    return {'key':key,'value':value}

@router.post('/jobs')
def job(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=enqueue(db,p.company.tenant_id,p.company.id,payload.code or 'generic',payload.data.get('payload',{}),max(1,min(20,int(payload.data.get('max_attempts',5)))))
    db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}

@router.post('/jobs/claim')
def jobs_claim(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    rows=[r for r in claim_jobs(db,max(1,min(100,int(payload.data.get('limit',20))))) if r.company_id==p.company.id]
    db.commit(); return {'jobs':[{'id':r.id,'type':r.job_type,'payload':r.payload_json,'attempts':r.attempts} for r in rows]}

@router.get('/dashboard')
def dashboard(db:Session=Depends(get_db),p:Principal=Depends(read_dep)):
    count=lambda m: db.scalar(select(func.count()).select_from(m).where(m.company_id==p.company.id)) if hasattr(m,'company_id') else db.scalar(select(func.count()).select_from(m))
    return {'events_pending':db.scalar(select(func.count()).select_from(DomainEventOutbox).where(DomainEventOutbox.company_id==p.company.id,DomainEventOutbox.status=='pending')) or 0,'facts':count(WarehouseFact) or 0,'kpi_observations':count(KPIObservation) or 0,'reports':count(ReportDefinition) or 0,'realtime_metrics':count(RealtimeMetric) or 0,'queued_jobs':db.scalar(select(func.count()).select_from(BackgroundJob).where(BackgroundJob.company_id==p.company.id,BackgroundJob.status=='queued')) or 0}
