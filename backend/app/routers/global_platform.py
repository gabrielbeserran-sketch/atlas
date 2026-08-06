from __future__ import annotations
from datetime import datetime, timezone
from typing import Any
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.orm import Session
from ..authz import require_permission
from ..database import get_db
from ..dependencies import get_current_context

def scope(ctx, farm_id: str | None = None):
    company=getattr(ctx,"company",None); user=getattr(ctx,"user",None)
    company_id=getattr(company,"id",""); tenant_id=getattr(company,"tenant_id","")
    if not company_id or not tenant_id: raise HTTPException(403,"Company context required")
    return company_id, tenant_id, getattr(user,"id",None)

from ..enterprise_growth_models import LocalizationProfile, CertificationRecord, TrainingResource
router=APIRouter(prefix="/global-platform",tags=["Atlas Global"])
class LocaleIn(BaseModel): locale:str="pt-BR"; currency:str="BRL"; measurement_system:str="metric"; timezone_name:str="America/Sao_Paulo"; settings:dict[str,Any]=Field(default_factory=dict)
class CertificationIn(BaseModel): certification_type:str; issuer:str=""; valid_from:datetime|None=None; valid_until:datetime|None=None; evidence:list[Any]=Field(default_factory=list)
class TrainingIn(BaseModel): resource_type:str="course"; title:str; language:str="pt-BR"; content_uri:str=""; metadata:dict[str,Any]=Field(default_factory=dict); published:bool=False
@router.put("/localization")
def set_localization(payload:LocaleIn,farm_id:str|None=None,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("platform.manage"))):
 cid,tid,_=scope(ctx,farm_id); row=db.scalar(select(LocalizationProfile).where(LocalizationProfile.company_id==cid,LocalizationProfile.farm_id==farm_id));
 if not row: row=LocalizationProfile(company_id=cid,tenant_id=tid,farm_id=farm_id); db.add(row)
 row.locale=payload.locale; row.currency=payload.currency; row.measurement_system=payload.measurement_system; row.timezone_name=payload.timezone_name; row.settings_json=payload.settings; db.commit(); return {"id":row.id}
@router.post("/certifications")
def create_cert(payload:CertificationIn,farm_id:str|None=None,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("platform.manage"))):
 cid,tid,_=scope(ctx,farm_id); row=CertificationRecord(company_id=cid,tenant_id=tid,farm_id=farm_id,certification_type=payload.certification_type,issuer=payload.issuer,valid_from=payload.valid_from,valid_until=payload.valid_until,evidence_json=payload.evidence); db.add(row); db.commit(); return {"id":row.id}
@router.post("/training")
def create_training(payload:TrainingIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("platform.manage"))):
 cid,tid,_=scope(ctx); row=TrainingResource(company_id=cid,tenant_id=tid,farm_id=None,resource_type=payload.resource_type,title=payload.title,language=payload.language,content_uri=payload.content_uri,metadata_json=payload.metadata,published=payload.published); db.add(row); db.commit(); return {"id":row.id}
@router.get("/readiness")
def readiness(db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("platform.read"))):
 cid,tid,_=scope(ctx); locales=list(db.scalars(select(LocalizationProfile).where(LocalizationProfile.company_id==cid))); certs=list(db.scalars(select(CertificationRecord).where(CertificationRecord.company_id==cid))); training=db.scalar(select(func.count()).select_from(TrainingResource).where(TrainingResource.company_id==cid,TrainingResource.published.is_(True))) or 0; return {"internationalization":True,"multiple_languages":sorted({p.locale for p in locales}|{"pt-BR","en-US","es-ES"}),"multiple_currencies":sorted({p.currency for p in locales}|{"BRL","USD","EUR"}),"configurable_units":True,"multi_region":"prepared","certifications":{"records":len(certs)},"partner_program":"prepared_by_ecosystem","training_program":{"published_resources":training},"documentation_center":"prepared","atlas_enterprise_global_2_0":{"status":"foundation_ready","external_regulatory_review_required":True}}
