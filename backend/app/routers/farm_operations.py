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
from ..operations_intelligence_models import OperationalWorkOrder, FarmAsset
router=APIRouter(prefix="/farm-operations",tags=["Farm Operations"])
class WorkOrderIn(BaseModel): title:str; area:str; assigned_user_id:str|None=None; priority:str="medium"; scheduled_at:datetime|None=None; estimated_cost:float=0; checklist:list[Any]=Field(default_factory=list); notes:str=""
class AssetIn(BaseModel): name:str; asset_type:str; identifier:str=""; hour_meter:float=0; next_maintenance_at:datetime|None=None; metadata:dict[str,Any]=Field(default_factory=dict)
@router.post("/farms/{farm_id}/work-orders")
def create_work_order(farm_id:str,payload:WorkOrderIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("platform.manage"))):
 cid,tid,_=farm_scope(ctx,farm_id); row=OperationalWorkOrder(company_id=cid,tenant_id=tid,farm_id=farm_id,**payload.model_dump(exclude={"checklist"}),checklist_json=payload.checklist); db.add(row); db.commit(); return {"id":row.id,"status":row.status}
@router.patch("/work-orders/{work_order_id}/complete")
def complete(work_order_id:str,actual_cost:float=0,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("platform.manage"))):
 cid,tid,_=ctx_values(ctx); row=db.get(OperationalWorkOrder,work_order_id);
 if not row or row.company_id!=cid: raise HTTPException(404,"Work order not found")
 row.status="completed"; row.completed_at=datetime.now(timezone.utc); row.actual_cost=max(0,actual_cost); db.commit(); return {"id":row.id,"status":row.status}
@router.post("/farms/{farm_id}/assets")
def create_asset(farm_id:str,payload:AssetIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("platform.manage"))):
 cid,tid,_=farm_scope(ctx,farm_id); row=FarmAsset(company_id=cid,tenant_id=tid,farm_id=farm_id,**payload.model_dump(exclude={"metadata"}),metadata_json=payload.metadata); db.add(row); db.commit(); return {"id":row.id}
@router.get("/farms/{farm_id}/dashboard")
def dashboard(farm_id:str,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("platform.read"))):
 cid,tid,_=farm_scope(ctx,farm_id); orders=list(db.scalars(select(OperationalWorkOrder).where(OperationalWorkOrder.company_id==cid,OperationalWorkOrder.farm_id==farm_id))); assets=list(db.scalars(select(FarmAsset).where(FarmAsset.company_id==cid,FarmAsset.farm_id==farm_id))); now=datetime.now(timezone.utc); open_orders=[o for o in orders if o.status!="completed"]; overdue=[o for o in open_orders if o.scheduled_at and o.scheduled_at<now]; preventive=[a for a in assets if a.next_maintenance_at and a.next_maintenance_at<=now]; estimated=sum(o.estimated_cost for o in orders); actual=sum(o.actual_cost for o in orders); employee={};
 for o in orders:
  key=o.assigned_user_id or "unassigned"; employee.setdefault(key,{"total":0,"completed":0}); employee[key]["total"]+=1; employee[key]["completed"]+=1 if o.status=="completed" else 0
 return {"operational_agenda":[{"id":o.id,"title":o.title,"scheduled_at":o.scheduled_at.isoformat() if o.scheduled_at else None} for o in open_orders],"work_orders":{"total":len(orders),"open":len(open_orders),"overdue":len(overdue)},"teams":employee,"shifts":{"status":"supported_by_scheduled_at_and_assignee"},"machines":{"total":len(assets)},"preventive_maintenance":len(preventive),"corrective_maintenance":sum(1 for o in orders if o.area=="maintenance" and o.priority=="high"),"operational_checklists":sum(1 for o in orders if o.checklist_json),"operational_costs":{"estimated":estimated,"actual":actual},"operational_score":max(0,100-len(overdue)*10-len(preventive)*5)}
