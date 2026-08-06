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

from ..enterprise_growth_models import EcosystemPartner, SupportConversation
router=APIRouter(prefix="/ecosystem",tags=["Atlas Ecosystem"])
class PartnerIn(BaseModel): partner_type:str; name:str; document:str=""; email:str=""; phone:str=""; service_regions:list[Any]=Field(default_factory=list); specialties:list[Any]=Field(default_factory=list)
class SupportIn(BaseModel): subject:str; priority:str="medium"; participants:list[Any]=Field(default_factory=list); message:str=""
@router.post("/partners")
def create_partner(payload:PartnerIn,farm_id:str|None=None,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("platform.manage"))):
 cid,tid,_=scope(ctx,farm_id); row=EcosystemPartner(company_id=cid,tenant_id=tid,farm_id=farm_id,partner_type=payload.partner_type,name=payload.name,document=payload.document,email=payload.email,phone=payload.phone,service_regions_json=payload.service_regions,specialties_json=payload.specialties); db.add(row); db.commit(); return {"id":row.id}
@router.get("/partners")
def list_partners(partner_type:str|None=None,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("platform.read"))):
 cid,tid,_=scope(ctx); q=select(EcosystemPartner).where(EcosystemPartner.company_id==cid,EcosystemPartner.active.is_(True));
 if partner_type:q=q.where(EcosystemPartner.partner_type==partner_type)
 return [{"id":p.id,"type":p.partner_type,"name":p.name,"verified":p.verified,"regions":p.service_regions_json,"specialties":p.specialties_json} for p in db.scalars(q)]
@router.post("/support")
def create_support(payload:SupportIn,farm_id:str|None=None,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("platform.read"))):
 cid,tid,uid=scope(ctx,farm_id); messages=[{"author_user_id":uid,"message":payload.message,"created_at":datetime.now(timezone.utc).isoformat()}] if payload.message else []; row=SupportConversation(company_id=cid,tenant_id=tid,farm_id=farm_id,subject=payload.subject,priority=payload.priority,participants_json=payload.participants,messages_json=messages); db.add(row); db.commit(); return {"id":row.id,"status":row.status}
@router.get("/dashboard")
def dashboard(db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("platform.read"))):
 cid,tid,_=scope(ctx); partners=list(db.scalars(select(EcosystemPartner).where(EcosystemPartner.company_id==cid,EcosystemPartner.active.is_(True)))); types={t:sum(1 for p in partners if p.partner_type==t) for t in ["marketplace","veterinarian","consultant","laboratory","slaughterhouse","supplier","carrier"]}; support=db.scalar(select(func.count()).select_from(SupportConversation).where(SupportConversation.company_id==cid,SupportConversation.status=="open")) or 0; return {"marketplace":types["marketplace"],"veterinarians":types["veterinarian"],"consultants":types["consultant"],"laboratories":types["laboratory"],"slaughterhouses":types["slaughterhouse"],"suppliers":types["supplier"],"carriers":types["carrier"],"producer_consultant_chat":"enabled_via_support_conversations","secure_data_sharing":"tenant_scoped","support_center":{"open_conversations":support}}
