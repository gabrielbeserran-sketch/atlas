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
from ..operations_intelligence_models import NutritionSimulation
from ..models import NutritionIngredient, NutritionPlan, NutritionEvent
router=APIRouter(prefix="/nutrition-intelligence",tags=["Nutrition Intelligence"])
class SimulationIn(BaseModel): lot_id:str; name:str; ingredients:list[dict[str,Any]]=Field(default_factory=list); targets:dict[str,Any]=Field(default_factory=dict)
@router.post("/farms/{farm_id}/simulations")
def simulate(farm_id:str,payload:SimulationIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("nutrition.write"))):
 cid,tid,_=farm_scope(ctx,farm_id); total_qty=sum(float(i.get("quantity_kg",0)) for i in payload.ingredients); daily_cost=sum(float(i.get("quantity_kg",0))*float(i.get("unit_cost",0)) for i in payload.ingredients); protein=sum(float(i.get("quantity_kg",0))*float(i.get("crude_protein_percent",0))/100 for i in payload.ingredients); expected_gain=float(payload.targets.get("expected_gain_kg_day",0)); result={"total_quantity_kg":total_qty,"protein_kg":protein,"daily_cost":daily_cost,"cost_per_kg":daily_cost/max(1,total_qty),"expected_gain_kg_day":expected_gain,"cost_per_kg_gain":daily_cost/max(.001,expected_gain)}; row=NutritionSimulation(company_id=cid,tenant_id=tid,farm_id=farm_id,lot_id=payload.lot_id,name=payload.name,ingredients_json=payload.ingredients,targets_json=payload.targets,results_json=result,daily_cost=daily_cost,projected_gain_kg_day=expected_gain); db.add(row); db.commit(); return {"id":row.id,"results":result}
@router.get("/farms/{farm_id}/dashboard")
def dashboard(farm_id:str,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("nutrition.read"))):
 cid,tid,_=farm_scope(ctx,farm_id); ingredients=list(db.scalars(select(NutritionIngredient).where(NutritionIngredient.company_id==cid,NutritionIngredient.farm_id==farm_id))); plans=list(db.scalars(select(NutritionPlan).where(NutritionPlan.company_id==cid,NutritionPlan.farm_id==farm_id))); events=list(db.scalars(select(NutritionEvent).where(NutritionEvent.company_id==cid,NutritionEvent.farm_id==farm_id))); sims=list(db.scalars(select(NutritionSimulation).where(NutritionSimulation.company_id==cid,NutritionSimulation.farm_id==farm_id).order_by(NutritionSimulation.created_at.desc()).limit(20))); total_cost=sum(float(getattr(e,"total_cost",0) or 0) for e in events); supplied=sum(float(getattr(e,"supplied_quantity",0) or 0) for e in events); gain_values=[float(getattr(e,"observed_daily_gain",0) or 0) for e in events if float(getattr(e,"observed_daily_gain",0) or 0)>0]; avg_gain=sum(gain_values)/len(gain_values) if gain_values else 0
 return {"diet_formulation":{"plans":len(plans)},"ingredient_library":len(ingredients),"diet_simulations":len(sims),"cost_comparison":[{"id":s.id,"name":s.name,"daily_cost":s.daily_cost} for s in sims],"individual_consumption":{"status":"requires_iot_or_individual_feeding"},"lot_consumption_kg":supplied,"feed_efficiency":{"average_daily_gain":avg_gain},"feed_conversion":supplied/max(.001,avg_gain) if avg_gain else 0,"diet_economic_simulation":{"total_cost":total_cost},"advanced_nutrition_ai":{"status":"explainable_rule_engine","recommendation":"Compare simulations and actual lot performance."}}
