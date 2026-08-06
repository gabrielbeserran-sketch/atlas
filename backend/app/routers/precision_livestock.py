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
from sqlalchemy import func
from ..operations_intelligence_models import PrecisionAssessment
from ..models import LivestockAnimal, LivestockLot, LivestockWeight, FinancialEntry
router=APIRouter(prefix="/precision-livestock",tags=["Precision Livestock"])
class AssessmentIn(BaseModel):
    assessment_type:str; lot_id:str|None=None; animal_id:str|None=None; score:float=0; confidence_percent:float=0; metrics:dict[str,Any]=Field(default_factory=dict); evidence:list[Any]=Field(default_factory=list); recommendation:str=""
@router.post("/farms/{farm_id}/assessments")
def create_assessment(farm_id:str,payload:AssessmentIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("platform.manage"))):
    cid,tid,_uid=farm_scope(ctx,farm_id); row=PrecisionAssessment(company_id=cid,tenant_id=tid,farm_id=farm_id,assessment_type=payload.assessment_type,lot_id=payload.lot_id,animal_id=payload.animal_id,score=max(0,min(100,payload.score)),confidence_percent=max(0,min(100,payload.confidence_percent)),metrics_json=payload.metrics,evidence_json=payload.evidence,recommendation=payload.recommendation); db.add(row); db.commit(); db.refresh(row); return {"id":row.id,"score":row.score}
@router.get("/farms/{farm_id}/dashboard")
def dashboard(farm_id:str,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("platform.read"))):
    cid,tid,_=farm_scope(ctx,farm_id)
    animals=list(db.scalars(select(LivestockAnimal).where(LivestockAnimal.company_id==cid,LivestockAnimal.farm_id==farm_id,LivestockAnimal.status=="active")))
    lots=list(db.scalars(select(LivestockLot).where(LivestockLot.company_id==cid,LivestockLot.farm_id==farm_id,LivestockLot.status=="active")))
    weights=[float(a.current_weight or 0) for a in animals if float(a.current_weight or 0)>0]
    avg_weight=sum(weights)/len(weights) if weights else 0
    lot_counts={l.id:sum(1 for a in animals if a.lot_id==l.id) for l in lots}
    outliers=[a.id for a in animals if weights and abs(float(a.current_weight or 0)-avg_weight)>max(50,avg_weight*.25)]
    welfare=max(0,100-(len(outliers)*5)-(sum(1 for a in animals if not a.lot_id)*2))
    efficiency=max(0,min(100,70+(len(weights)/max(1,len(animals))*20)-(len(outliers)*2)))
    sustainability=max(0,min(100,(welfare+efficiency)/2))
    farm_score=round((welfare*.3+efficiency*.4+sustainability*.3),2)
    return {"herd_efficiency_score":round(efficiency,2),"animal_welfare_score":round(welfare,2),"outlier_animals":outliers,"thermal_stress_prediction":{"status":"requires_climate_input"},"water_consumption_prediction":{"status":"prepared"},"climate_performance_correlation":{"status":"prepared"},"employee_efficiency":{"status":"requires_work_orders"},"productivity_map":{"lot_counts":lot_counts},"sustainability_score":round(sustainability,2),"atlas_farm_score":farm_score}
