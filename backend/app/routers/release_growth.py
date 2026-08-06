from __future__ import annotations
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session
from ..authz import Principal, require_farm_scope, require_permission
from ..database import get_db
from ..release_growth_models import *

router=APIRouter(prefix='/release-growth',tags=['Release & Growth'])
def read_dep(p=Depends(require_permission('release.read'))): return p
def manage_dep(p=Depends(require_permission('release.manage'))): return p
def now(): return datetime.now(timezone.utc)
class Payload(BaseModel):
    code:str=''; name:str=''; farm_id:str|None=None; data:dict=Field(default_factory=dict)

@router.post('/environments')
def environment(x:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=ReleaseEnvironment(tenant_id=p.company.tenant_id,company_id=p.company.id,code=x.code,name=x.name or x.code,base_url=x.data.get('base_url',''),configuration_json=x.data.get('configuration',{})); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}

@router.post('/pilots')
def pilot(x:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if x.farm_id: require_farm_scope(p,x.farm_id)
    kind=x.data.get('pilot_type','technical')
    if kind not in {'technical','commercial'}: raise HTTPException(422,'pilot_type inválido.')
    row=PilotProgram(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=x.farm_id,pilot_type=kind,name=x.name or 'Piloto Atlas',objectives_json=x.data.get('objectives',[]),metrics_json=x.data.get('metrics',{})); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}

@router.post('/mobile-profiles')
def mobile(x:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    platform=x.data.get('platform','android')
    if platform not in {'android','ios'}: raise HTTPException(422,'Plataforma inválida.')
    rollout=float(x.data.get('rollout_percent',0))
    if rollout<0 or rollout>100: raise HTTPException(422,'Rollout deve estar entre 0 e 100.')
    row=MobileReleaseProfile(platform=platform,application_id=x.code,version_name=x.data.get('version_name','1.0.0'),build_number=max(1,int(x.data.get('build_number',1))),signing_configured=bool(x.data.get('signing_configured',False)),privacy_url=x.data.get('privacy_url',''),rollout_percent=rollout,checklist_json=x.data.get('checklist',{})); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'platform':row.platform}

@router.post('/web-releases')
def web_release(x:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=WebRelease(version=x.code or '3.0.0',target=x.data.get('target','production'),features_json=x.data.get('features',[]),accessibility_score=float(x.data.get('accessibility_score',0)),performance_score=float(x.data.get('performance_score',0))); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}

@router.post('/learning-paths')
def learning(x:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=LearningPath(code=x.code,audience=x.data.get('audience','producer'),title=x.name or x.code,modules_json=x.data.get('modules',[]),certification_enabled=bool(x.data.get('certification_enabled',False))); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'code':row.code}

@router.post('/documentation')
def documentation(x:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=DocumentationPage(slug=x.code,title=x.name or x.code,category=x.data.get('category','general'),version=x.data.get('version','3.0'),content_uri=x.data.get('content_uri',''),metadata_json=x.data.get('metadata',{}),published=bool(x.data.get('published',False))); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'published':row.published}

@router.post('/growth-experiments')
def growth(x:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=GrowthExperiment(name=x.name or x.code,persona=x.data.get('persona','producer'),hypothesis=x.data.get('hypothesis',''),channel=x.data.get('channel','direct'),metrics_json=x.data.get('metrics',{})); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}

@router.post('/capability-reviews')
def capability(x:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    decision=x.data.get('decision','keep')
    if decision not in {'keep','improve','merge','remove'}: raise HTTPException(422,'Decisão inválida.')
    row=ProductCapabilityReview(capability_key=x.code,module=x.data.get('module','core'),usage_score=float(x.data.get('usage_score',0)),quality_score=float(x.data.get('quality_score',0)),decision=decision,notes=x.data.get('notes','')); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'decision':row.decision}

@router.post('/roadmaps')
def roadmap(x:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=AtlasRoadmap(name=x.name or 'Atlas 3.0',horizon_years=max(1,int(x.data.get('horizon_years',5))),vision=x.data.get('vision',''),pillars_json=x.data.get('pillars',[]),milestones_json=x.data.get('milestones',[])); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}

@router.post('/readiness')
def readiness(x:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    checks={str(k):bool(v) for k,v in x.data.get('checks',{}).items()}; total=len(checks); passed=sum(checks.values()); score=round((passed/total)*100,2) if total else 0; blockers=[k for k,v in checks.items() if not v]; status='ready' if score==100 else ('attention' if score>=80 else 'blocked')
    row=ReleaseReadinessAssessment(release_name=x.name or x.code or 'Atlas 3.0',checks_json=checks,blockers_json=blockers,score=score,status=status); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'score':score,'status':status,'blockers':blockers}

@router.get('/dashboard')
def dashboard(db:Session=Depends(get_db),p:Principal=Depends(read_dep)):
    def count(m): return db.scalar(select(func.count()).select_from(m)) or 0
    pilots=db.scalar(select(func.count()).select_from(PilotProgram).where(PilotProgram.company_id==p.company.id)) or 0
    envs=db.scalar(select(func.count()).select_from(ReleaseEnvironment).where(ReleaseEnvironment.company_id==p.company.id)) or 0
    latest=db.scalar(select(ReleaseReadinessAssessment).order_by(ReleaseReadinessAssessment.assessed_at.desc()).limit(1))
    return {'environments':envs,'pilots':pilots,'mobile_profiles':count(MobileReleaseProfile),'web_releases':count(WebRelease),'learning_paths':count(LearningPath),'documentation_pages':count(DocumentationPage),'growth_experiments':count(GrowthExperiment),'capability_reviews':count(ProductCapabilityReview),'roadmaps':count(AtlasRoadmap),'latest_readiness':({'score':latest.score,'status':latest.status} if latest else None)}
