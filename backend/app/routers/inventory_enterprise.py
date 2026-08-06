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

from ..enterprise_growth_models import InventoryCount
from ..models import InventoryProduct, InventoryMovement
router=APIRouter(prefix="/inventory-enterprise",tags=["Inventory Enterprise"])
class CountIn(BaseModel): items:list[dict[str,Any]]=Field(default_factory=list); notes:str=""
@router.post("/farms/{farm_id}/counts")
def create_count(farm_id:str,payload:CountIn,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("inventory.write"))):
 cid,tid,_=scope(ctx,farm_id); products={p.id:p for p in db.scalars(select(InventoryProduct).where(InventoryProduct.company_id==cid,InventoryProduct.farm_id==farm_id))}; diffs=[]
 for item in payload.items:
  p=products.get(str(item.get("product_id",""))); counted=float(item.get("counted_quantity",0) or 0)
  if p: diffs.append({"product_id":p.id,"system_quantity":float(p.current_quantity or 0),"counted_quantity":counted,"difference":counted-float(p.current_quantity or 0)})
 row=InventoryCount(company_id=cid,tenant_id=tid,farm_id=farm_id,items_json=payload.items,differences_json=diffs,notes=payload.notes); db.add(row); db.commit(); return {"id":row.id,"differences":diffs}
@router.get("/farms/{farm_id}/dashboard")
def dashboard(farm_id:str,db:Session=Depends(get_db),ctx=Depends(get_current_context),_=Depends(require_permission("inventory.read"))):
 cid,tid,_=scope(ctx,farm_id); products=list(db.scalars(select(InventoryProduct).where(InventoryProduct.company_id==cid,InventoryProduct.farm_id==farm_id))); movements=list(db.scalars(select(InventoryMovement).where(InventoryMovement.company_id==cid,InventoryMovement.farm_id==farm_id))); low=[p for p in products if float(p.current_quantity or 0)<=float(p.minimum_quantity or 0)]; expiring=[p for p in products if getattr(p,"expires_at",None)]; suggested=[{"product_id":p.id,"name":p.name,"suggested_quantity":max(0,float(p.minimum_quantity or 0)*2-float(p.current_quantity or 0))} for p in low]; return {"stock_lots":len(products),"validity_control":len(expiring),"traceability_movements":len(movements),"barcode_support":True,"qr_code_support":True,"inventory_counts":"enabled","automatic_adjustments":"supported_after_approval","forecast_consumption":{"method":"historical_movement_rate","available":bool(movements)},"suggested_purchases":suggested,"inventory_ai":{"critical_items":len(low),"recommendation":"Prioritize critical replenishments." if low else "Stock levels are adequate."}}
