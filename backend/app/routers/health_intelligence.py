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
from ..operations_intelligence_models import MedicineLibraryItem, EpidemiologicalOccurrence
from ..models import LivestockHealthEvent, InventoryProduct
router=APIRouter(prefix="/health-intelligence",tags=["Health Intelligence"])
class MedicineIn(BaseModel): name:str; active_ingredient:str=""; dosage_guidance:str=""; meat_withdrawal_days:int=0; milk_withdrawal_days:int=0; inventory_product_id:str|None=None; metadata:dict[str,Any]=Field(default_factory=dict)
class OccurrenceIn(BaseModel): disease_code:str; lot_id:str|None=None; animal_id:str|None=None; severity:str="medium"; occurred_at:datetime|None=None; latitude:float|None=None; longitude:float|None=None; details:dict[str,Any]=Field(default_factory=dict)
@router.post("/farms/{farm_id}/medicines")
def create_medicine(farm_id:str,payload:MedicineIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("health.write"))):
 cid,tid,_=farm_scope(ctx,farm_id); row=MedicineLibraryItem(company_id=cid,tenant_id=tid,farm_id=farm_id,**payload.model_dump(exclude={"metadata"}),metadata_json=payload.metadata); db.add(row); db.commit(); return {"id":row.id,"name":row.name}
@router.post("/farms/{farm_id}/occurrences")
def create_occurrence(farm_id:str,payload:OccurrenceIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("health.write"))):
 cid,tid,_=farm_scope(ctx,farm_id); data=payload.model_dump(exclude={"details"}); data["occurred_at"]=data["occurred_at"] or datetime.now(timezone.utc); row=EpidemiologicalOccurrence(company_id=cid,tenant_id=tid,farm_id=farm_id,**data,details_json=payload.details); db.add(row); db.commit(); return {"id":row.id}
@router.get("/farms/{farm_id}/dashboard")
def dashboard(farm_id:str,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("health.read"))):
 cid,tid,_=farm_scope(ctx,farm_id); events=list(db.scalars(select(LivestockHealthEvent).where(LivestockHealthEvent.company_id==cid,LivestockHealthEvent.farm_id==farm_id))); occurrences=list(db.scalars(select(EpidemiologicalOccurrence).where(EpidemiologicalOccurrence.company_id==cid,EpidemiologicalOccurrence.farm_id==farm_id))); medicines=list(db.scalars(select(MedicineLibraryItem).where(MedicineLibraryItem.company_id==cid,MedicineLibraryItem.farm_id==farm_id))); now=datetime.now(timezone.utc)
 withdrawals=sum(1 for e in events if any(d and d>now for d in [getattr(e,"withdrawal_meat_until",None),getattr(e,"withdrawal_milk_until",None)])); by_disease={};
 for o in occurrences: by_disease[o.disease_code]=by_disease.get(o.disease_code,0)+1
 risk=min(100,len(occurrences)*8+withdrawals*2); score=max(0,100-risk)
 return {"automatic_calendar":[{"event_id":e.id,"next_date":e.next_application_at.isoformat() if getattr(e,"next_application_at",None) else None} for e in events if getattr(e,"next_application_at",None)],"medicine_library_count":len(medicines),"protocols":"integrated_with_existing_health_protocols","withdrawal_controls":withdrawals,"medicine_inventory":"linked_by_inventory_product_id","outbreak_prediction":{"risk_percent":risk,"method":"epidemiological_rule_v1"},"epidemiological_history":by_disease,"health_map":[{"lat":o.latitude,"lng":o.longitude,"disease":o.disease_code} for o in occurrences if o.latitude is not None and o.longitude is not None],"automatic_alerts":risk>25,"health_score":score}
