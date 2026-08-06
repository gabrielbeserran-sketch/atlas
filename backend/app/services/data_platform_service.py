from __future__ import annotations
from datetime import datetime, timedelta, timezone
from math import ceil
from statistics import median
from sqlalchemy import select
from sqlalchemy.orm import Session
from ..data_platform_models import BackgroundJob, BenchmarkSnapshot, CacheEntry, DomainEventOutbox, RealtimeMetric

def utcnow(): return datetime.now(timezone.utc)

def percentile(values:list[float], p:float)->float:
    if not values: return 0.0
    ordered=sorted(values); idx=(len(ordered)-1)*p; low=int(idx); high=min(low+1,len(ordered)-1); fraction=idx-low
    return ordered[low]*(1-fraction)+ordered[high]*fraction

def benchmark_percentiles(values:list[float])->dict[str,float]:
    return {f'p{int(p*100)}':round(percentile(values,p),4) for p in (0.1,0.25,0.5,0.75,0.9)}

def cache_get(db:Session,company_id:str,key:str):
    row=db.scalar(select(CacheEntry).where(CacheEntry.company_id==company_id,CacheEntry.cache_key==key,CacheEntry.expires_at>utcnow()))
    return row.value_json if row else None

def enqueue(db:Session,tenant_id:str,company_id:str,job_type:str,payload:dict,max_attempts:int=5):
    row=BackgroundJob(tenant_id=tenant_id,company_id=company_id,job_type=job_type,payload_json=payload,max_attempts=max_attempts)
    db.add(row); return row

def claim_jobs(db:Session,limit:int=20):
    rows=list(db.scalars(select(BackgroundJob).where(BackgroundJob.status=='queued',BackgroundJob.available_at<=utcnow()).order_by(BackgroundJob.available_at).limit(limit)).all())
    for row in rows: row.status='running'; row.locked_at=utcnow(); row.attempts+=1
    return rows

def retry_delay(attempts:int)->timedelta: return timedelta(seconds=min(3600,2**max(0,attempts)*5))
