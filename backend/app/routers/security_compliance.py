from __future__ import annotations
from datetime import datetime, timezone
from hashlib import sha256
import json
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session
from ..authz import Principal, require_farm_scope, require_permission
from ..database import get_db
from ..security_compliance_models import *

router=APIRouter(prefix='/security-compliance',tags=['Security & Compliance'])
def read_dep(p=Depends(require_permission('compliance.read'))): return p
def manage_dep(p=Depends(require_permission('compliance.manage'))): return p
def now(): return datetime.now(timezone.utc)
class Payload(BaseModel):
    code:str=''; name:str=''; farm_id:str|None=None; data:dict=Field(default_factory=dict)

def scoped(model,db,p): return select(model).where(model.company_id==p.company.id)

@router.post('/roles')
def role(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=SecurityRole(tenant_id=p.company.tenant_id,company_id=p.company.id,code=payload.code,name=payload.name or payload.code,permissions_json=payload.data.get('permissions',[]),farm_ids_json=payload.data.get('farm_ids',[])); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'code':row.code}

@router.post('/incidents')
def incident(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=SecurityIncident(tenant_id=p.company.tenant_id,company_id=p.company.id,category=payload.code or 'security',severity=payload.data.get('severity','medium'),details_json=payload.data); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}

@router.post('/audit')
def audit(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    previous=db.scalar(select(ImmutableAuditRecord).where(ImmutableAuditRecord.company_id==p.company.id).order_by(ImmutableAuditRecord.created_at.desc()).limit(1)); prev=previous.record_hash if previous else ''
    body={'company':p.company.id,'actor':p.user.id,'action':payload.code,'entity_type':payload.data.get('entity_type','generic'),'entity_id':payload.data.get('entity_id',''),'before':payload.data.get('before',{}),'after':payload.data.get('after',{}),'previous_hash':prev,'at':now().isoformat()}
    digest=sha256(json.dumps(body,sort_keys=True,default=str).encode()).hexdigest(); row=ImmutableAuditRecord(tenant_id=p.company.tenant_id,company_id=p.company.id,actor_id=p.user.id,action=payload.code,entity_type=body['entity_type'],entity_id=body['entity_id'],before_json=body['before'],after_json=body['after'],previous_hash=prev,record_hash=digest); db.add(row); db.commit(); return {'id':row.id,'hash':digest}

@router.get('/audit/verify')
def verify_audit(db:Session=Depends(get_db),p:Principal=Depends(read_dep)):
    rows=list(db.scalars(select(ImmutableAuditRecord).where(ImmutableAuditRecord.company_id==p.company.id).order_by(ImmutableAuditRecord.created_at)).all()); ok=True; prev=''
    for r in rows:
        if r.previous_hash!=prev: ok=False; break
        prev=r.record_hash
    return {'valid':ok,'records':len(rows),'last_hash':prev}

@router.post('/privacy/requests')
def privacy(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    allowed={'access','correction','deletion','anonymization','portability','objection'}
    if payload.code not in allowed: raise HTTPException(422,'Tipo de solicitação LGPD inválido.')
    row=PrivacyRequest(tenant_id=p.company.tenant_id,company_id=p.company.id,request_type=payload.code,subject_reference=payload.data.get('subject_reference',''),legal_basis=payload.data.get('legal_basis','')); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}

@router.post('/backups')
def backup(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=BackupExecution(tenant_id=p.company.tenant_id,company_id=p.company.id,backup_type=payload.code or 'full',storage_uri=payload.data.get('storage_uri',''),encrypted=bool(payload.data.get('encrypted',True))); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}

@router.post('/availability-targets')
def availability(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    target=float(payload.data.get('target_percent',99.9));
    if target<90 or target>100: raise HTTPException(422,'SLO deve estar entre 90 e 100.')
    row=AvailabilityTarget(service_name=payload.code,target_percent=target,rpo_minutes=max(0,int(payload.data.get('rpo_minutes',1440))),rto_minutes=max(0,int(payload.data.get('rto_minutes',240))),architecture_json=payload.data.get('architecture',{})); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'target_percent':row.target_percent}

@router.post('/translations')
def translation(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    locale=payload.data.get('locale','pt-BR'); row=TranslationResource(locale=locale,resource_key=payload.code,value=payload.data.get('value',''),version=int(payload.data.get('version',1))); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'locale':locale}

@router.post('/regional-policies')
def regional(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=RegionalPolicy(country_code=payload.data.get('country_code','BRA'),region_code=payload.data.get('region_code','*'),policy_type=payload.code,settings_json=payload.data.get('settings',{})); db.add(row); db.commit(); db.refresh(row); return {'id':row.id}

@router.post('/certifications')
def certification(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if payload.farm_id: require_farm_scope(p,payload.farm_id)
    row=ComplianceCertification(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=payload.farm_id,certification_type=payload.code,issuer=payload.data.get('issuer',''),checklist_json=payload.data.get('checklist',{}),evidence_json=payload.data.get('evidence',[])); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}

@router.post('/continuity-plans')
def continuity(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=ContinuityPlan(tenant_id=p.company.tenant_id,company_id=p.company.id,name=payload.name or 'Plano de continuidade',severity_matrix_json=payload.data.get('severity_matrix',{}),contacts_json=payload.data.get('contacts',[]),runbooks_json=payload.data.get('runbooks',[])); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}

@router.get('/dashboard')
def dashboard(db:Session=Depends(get_db),p:Principal=Depends(read_dep)):
    def count(m): return db.scalar(select(func.count()).select_from(m).where(m.company_id==p.company.id)) or 0
    return {'roles':count(SecurityRole),'open_incidents':db.scalar(select(func.count()).select_from(SecurityIncident).where(SecurityIncident.company_id==p.company.id,SecurityIncident.status=='open')) or 0,'audit_records':count(ImmutableAuditRecord),'privacy_requests':count(PrivacyRequest),'backups':db.scalar(select(func.count()).select_from(BackupExecution).where(BackupExecution.company_id==p.company.id)) or 0,'certifications':count(ComplianceCertification),'continuity_plans':count(ContinuityPlan)}
