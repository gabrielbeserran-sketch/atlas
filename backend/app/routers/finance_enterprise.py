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

from ..enterprise_growth_models import AnnualBudget
from ..models import FinancialEntry, LivestockAnimal
router=APIRouter(prefix="/finance-enterprise",tags=["Finance Enterprise"])
class BudgetIn(BaseModel): year:int; cost_center:str="General"; revenue_budget:float=0; expense_budget:float=0; assumptions:dict[str,Any]=Field(default_factory=dict)
@router.post("/farms/{farm_id}/budgets")
def create_budget(farm_id:str,payload:BudgetIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("finance.write"))):
 cid,tid,_=scope(ctx,farm_id); row=AnnualBudget(company_id=cid,tenant_id=tid,farm_id=farm_id,year=payload.year,cost_center=payload.cost_center,revenue_budget=max(0,payload.revenue_budget),expense_budget=max(0,payload.expense_budget),assumptions_json=payload.assumptions); db.add(row); db.commit(); return {"id":row.id}
@router.get("/farms/{farm_id}/dashboard")
def dashboard(farm_id:str,year:int|None=None,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("finance.read"))):
 cid,tid,_=scope(ctx,farm_id); y=year or datetime.now(timezone.utc).year; entries=list(db.scalars(select(FinancialEntry).where(FinancialEntry.company_id==cid,FinancialEntry.farm_id==farm_id))); budgets=list(db.scalars(select(AnnualBudget).where(AnnualBudget.company_id==cid,AnnualBudget.farm_id==farm_id,AnnualBudget.year==y))); rev=sum(float(getattr(e,"amount",0) or 0) for e in entries if getattr(e,"entry_type","")=="income"); exp=sum(float(getattr(e,"amount",0) or 0) for e in entries if getattr(e,"entry_type","")!="income"); br=sum(b.revenue_budget for b in budgets); be=sum(b.expense_budget for b in budgets); animals=db.scalar(select(func.count()).select_from(LivestockAnimal).where(LivestockAnimal.company_id==cid,LivestockAnimal.farm_id==farm_id)) or 0; margin=rev-exp; return {"daily_cash_flow":{"income":rev,"expense":exp,"balance":margin},"projected_cash_flow":{"budget_revenue":br,"budget_expense":be,"projected_balance":br-be},"advanced_cost_centers":[{"name":b.cost_center,"revenue_budget":b.revenue_budget,"expense_budget":b.expense_budget} for b in budgets],"annual_budget":{"year":y,"revenue":br,"expense":be},"budget_vs_actual":{"revenue_variance":rev-br,"expense_variance":exp-be},"financial_indicators":{"margin":margin,"margin_percent":round((margin/rev*100),2) if rev else 0,"cost_per_animal":round(exp/animals,2) if animals else 0},"management_income_statement":{"revenue":rev,"expenses":exp,"result":margin},"simplified_balance_sheet":{"assets_proxy":max(0,rev),"liabilities_proxy":max(0,exp),"equity_proxy":margin},"liquidity":{"current_ratio":round(rev/exp,2) if exp else None},"advanced_financial_ai":{"method":"rule_based_financial_v2","recommendation":"Preserve positive cash generation." if margin>=0 else "Reduce expenses or strengthen revenues."}}
