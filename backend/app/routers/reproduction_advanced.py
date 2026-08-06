from __future__ import annotations
from datetime import datetime, timezone
from typing import Any
from fastapi import Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from ..authz import require_permission
from ..database import get_db
from ..dependencies import get_current_context

def ctx_values(ctx):
    company=getattr(ctx,"company",None); user=getattr(ctx,"user",None)
    return getattr(company,"id",""), getattr(company,"tenant_id",""), getattr(user,"id",None)

def farm_scope(ctx, farm_id: str):
    company_id, tenant_id, user_id = ctx_values(ctx)
    if not company_id or not tenant_id: raise HTTPException(403,"Company context required")
    return company_id, tenant_id, user_id

from fastapi import APIRouter
from pydantic import BaseModel, Field
from ..operations_intelligence_models import ReproductionProtocolTemplate, BreedingSeason
from ..models import LivestockAnimal, LivestockReproductionEvent
router=APIRouter(prefix="/reproduction-advanced",tags=["Advanced Reproduction"])
class ProtocolIn(BaseModel): name:str; protocol_type:str="iatf"; steps:list[Any]=Field(default_factory=list)
class SeasonIn(BaseModel): name:str; starts_at:datetime; ends_at:datetime; target_pregnancy_rate:float=0; settings:dict[str,Any]=Field(default_factory=dict)
@router.post("/farms/{farm_id}/protocols")
def create_protocol(farm_id:str,payload:ProtocolIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("reproduction.write"))):
 cid,tid,_=farm_scope(ctx,farm_id); row=ReproductionProtocolTemplate(company_id=cid,tenant_id=tid,farm_id=farm_id,name=payload.name,protocol_type=payload.protocol_type,steps_json=payload.steps); db.add(row); db.commit(); return {"id":row.id,"name":row.name}
@router.get("/farms/{farm_id}/protocols")
def list_protocols(farm_id:str,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("reproduction.read"))):
 cid,tid,_=farm_scope(ctx,farm_id); rows=db.scalars(select(ReproductionProtocolTemplate).where(ReproductionProtocolTemplate.company_id==cid,ReproductionProtocolTemplate.farm_id==farm_id,ReproductionProtocolTemplate.active.is_(True))); return [{"id":r.id,"name":r.name,"protocol_type":r.protocol_type,"steps":r.steps_json} for r in rows]
@router.post("/farms/{farm_id}/seasons")
def create_season(farm_id:str,payload:SeasonIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("reproduction.write"))):
 cid,tid,_=farm_scope(ctx,farm_id); row=BreedingSeason(company_id=cid,tenant_id=tid,farm_id=farm_id,name=payload.name,starts_at=payload.starts_at,ends_at=payload.ends_at,target_pregnancy_rate=payload.target_pregnancy_rate,settings_json=payload.settings); db.add(row); db.commit(); return {"id":row.id,"status":row.status}
@router.get("/farms/{farm_id}/dashboard")
def dashboard(farm_id:str,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("reproduction.read"))):
 cid,tid,_=farm_scope(ctx,farm_id); females=list(db.scalars(select(LivestockAnimal).where(LivestockAnimal.company_id==cid,LivestockAnimal.farm_id==farm_id,LivestockAnimal.sex.in_(["female","F","fêmea","Fêmea"]))))
 events=list(db.scalars(select(LivestockReproductionEvent).where(LivestockReproductionEvent.company_id==cid,LivestockReproductionEvent.farm_id==farm_id)))
 served={e.animal_id for e in events if e.event_type in {"ai","iatf","natural_service"}}; pregnant={a.id for a in females if getattr(a,"reproductive_status","")=="pregnant"}; rate=round(len(pregnant)/max(1,len(served))*100,2)
 by_protocol={};
 for e in events:
  p=getattr(e,"protocol","") or "Sem protocolo"; by_protocol[p]=by_protocol.get(p,0)+1
 return {"smart_calendar":sorted([{"animal_id":e.animal_id,"date":e.expected_date.isoformat() if e.expected_date else None,"type":e.event_type} for e in events if getattr(e,"expected_date",None)],key=lambda x:x["date"] or ""),"iatf_events":sum(1 for e in events if e.event_type=="iatf"),"ai_events":sum(1 for e in events if e.event_type=="ai"),"natural_service_events":sum(1 for e in events if e.event_type=="natural_service"),"breeding_season_planning":"available","future_pregnancy_simulation":{"served":len(served),"expected_pregnancies":round(len(served)*rate/100)},"protocol_comparison":by_protocol,"reproductive_efficiency_ranking":{"pregnancy_rate":rate}}
