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

from ..enterprise_growth_models import StrategicPlan, CorporateScenario
from ..models import Farm, LivestockAnimal, FinancialEntry
router=APIRouter(prefix="/corporate-intelligence",tags=["Corporate Intelligence"])
class PlanIn(BaseModel): title:str; horizon_days:int=365; objectives:list[Any]=Field(default_factory=list); kpis:list[Any]=Field(default_factory=list); initiatives:list[Any]=Field(default_factory=list)
class ScenarioIn(BaseModel): name:str; scenario_type:str="custom"; assumptions:dict[str,Any]=Field(default_factory=dict)
@router.post("/plans")
def create_plan(payload:PlanIn,farm_id:str|None=None,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("platform.manage"))):
 cid,tid,_=scope(ctx,farm_id); row=StrategicPlan(company_id=cid,tenant_id=tid,farm_id=farm_id,title=payload.title,horizon_days=payload.horizon_days,objectives_json=payload.objectives,kpis_json=payload.kpis,initiatives_json=payload.initiatives); db.add(row); db.commit(); return {"id":row.id}
@router.post("/scenarios")
def create_scenario(payload:ScenarioIn,farm_id:str|None=None,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("platform.manage"))):
 cid,tid,_=scope(ctx,farm_id); investment=float(payload.assumptions.get("investment",0) or 0); expected=float(payload.assumptions.get("expected_return",0) or 0); roi=((expected-investment)/investment*100) if investment else 0; results={"investment":investment,"expected_return":expected,"net_return":expected-investment}; row=CorporateScenario(company_id=cid,tenant_id=tid,farm_id=farm_id,name=payload.name,scenario_type=payload.scenario_type,assumptions_json=payload.assumptions,results_json=results,roi_percent=roi); db.add(row); db.commit(); return {"id":row.id,"results":results,"roi_percent":roi}
@router.get("/executive-board")
def executive_board(db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("platform.read"))):
 cid,tid,_=scope(ctx); farms=list(db.scalars(select(Farm).where(Farm.company_id==cid))); animals=db.scalar(select(func.count()).select_from(LivestockAnimal).where(LivestockAnimal.company_id==cid)) or 0; entries=list(db.scalars(select(FinancialEntry).where(FinancialEntry.company_id==cid))); rev=sum(float(e.amount or 0) for e in entries if e.entry_type=="income"); exp=sum(float(e.amount or 0) for e in entries if e.entry_type!="income"); plans=db.scalar(select(func.count()).select_from(StrategicPlan).where(StrategicPlan.company_id==cid)) or 0; scenarios=list(db.scalars(select(CorporateScenario).where(CorporateScenario.company_id==cid))); return {"regional_benchmark":{"status":"requires_anonymized_peer_dataset"},"national_benchmark":{"status":"requires_anonymized_peer_dataset"},"breed_indicators":"available_when_breed_data_is_complete","production_system_indicators":"available_by_farm_metadata","historical_comparison":{"farms":len(farms),"animals":animals},"strategic_planning":{"active_plans":plans},"scenario_simulations":len(scenarios),"investment_roi":[{"id":s.id,"name":s.name,"roi_percent":s.roi_percent} for s in scenarios],"strategic_ai":{"method":"explainable_corporate_rules_v1","recommendation":"Protect margin and data quality." if rev-exp>=0 else "Prioritize cash recovery and cost control."},"atlas_executive_board":{"revenue":rev,"expenses":exp,"result":rev-exp,"farms":len(farms),"animals":animals}}
