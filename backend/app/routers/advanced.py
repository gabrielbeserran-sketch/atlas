from __future__ import annotations

from datetime import datetime, timedelta, timezone
from math import sqrt
from typing import Any, Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..advanced_models import AtlasAgricultureRecord, AtlasAiForecast, AtlasGeneticProfile, AtlasGeoAsset, AtlasPastureRecord
from ..authz import Principal, require_permission
from ..database import get_db
from ..models import Farm, FinancialEntry, HealthEvent, HerdLot, LivestockAnimal, NutritionEvent, ReproductionEvent, WeightRecord

router = APIRouter(prefix="/advanced", tags=["atlas-advanced-blocks-1-5"])

class GeoAssetPayload(BaseModel):
    asset_type: Literal["property","paddock","fence","water_trough","feed_bunk","road","field","animal_track"]
    name: str = Field(min_length=1, max_length=180)
    geometry_type: Literal["Point","LineString","Polygon"] = "Point"
    geometry_json: dict[str, Any] = Field(default_factory=dict)
    properties_json: dict[str, Any] = Field(default_factory=dict)
    source: str = "manual"

class PasturePayload(BaseModel):
    paddock_id: str | None = None
    record_type: Literal["inventory","reform","fertilization","liming","rotation","height","forage_offer","carrying_capacity","production_estimate"]
    observed_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    grass_species: str = ""
    area_ha: float = Field(default=0, ge=0)
    height_cm: float = Field(default=0, ge=0)
    forage_mass_kg_dm_ha: float = Field(default=0, ge=0)
    utilization_percent: float = Field(default=50, ge=0, le=100)
    stocking_au: float = Field(default=0, ge=0)
    days_available: float = Field(default=0, ge=0)
    input_name: str = ""
    input_quantity: float = Field(default=0, ge=0)
    input_unit: str = ""
    cost: float = Field(default=0, ge=0)
    notes: str = ""
    metadata_json: dict[str, Any] = Field(default_factory=dict)

class AgriculturePayload(BaseModel):
    field_id: str | None = None
    record_type: Literal["crop","planting","harvest","grain_stock","silage","hay","plan","nutrition_link","cost"]
    crop_name: str = ""
    cultivar: str = ""
    occurred_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    area_ha: float = Field(default=0, ge=0)
    quantity: float = Field(default=0, ge=0)
    unit: str = ""
    unit_cost: float = Field(default=0, ge=0)
    destination: str = ""
    linked_nutrition_plan_id: str | None = None
    notes: str = ""
    metadata_json: dict[str, Any] = Field(default_factory=dict)

class GeneticPayload(BaseModel):
    animal_id: str
    sire_animal_id: str | None = None
    dam_animal_id: str | None = None
    registry_number: str = ""
    breed_composition_json: dict[str, Any] = Field(default_factory=dict)
    dep_json: dict[str, Any] = Field(default_factory=dict)
    economic_index: float = 0
    dna_verified: bool = False
    source: str = "manual"
    notes: str = ""

class ForecastRequest(BaseModel):
    forecast_type: Literal["health","nutrition","reproduction","economic","risk","mortality","weight_gain","stocking","climate","explainable"]
    animal_id: str | None = None
    lot_id: str | None = None
    horizon_days: int = Field(default=30, ge=1, le=730)
    climate: dict[str, Any] = Field(default_factory=dict)


def _farm(principal: Principal, db: Session, farm_id: str) -> Farm:
    farm=db.scalar(select(Farm).where(Farm.id==farm_id,Farm.company_id==principal.company.id,Farm.active.is_(True)))
    if not farm: raise HTTPException(404,"Fazenda não encontrada.")
    return farm

def _animal(principal: Principal, db: Session, farm_id: str, animal_id: str) -> LivestockAnimal:
    item=db.scalar(select(LivestockAnimal).where(LivestockAnimal.id==animal_id,LivestockAnimal.company_id==principal.company.id,LivestockAnimal.farm_id==farm_id))
    if not item: raise HTTPException(404,"Animal não encontrado.")
    return item

def _geo_dict(x: AtlasGeoAsset) -> dict[str,Any]:
    return {"id":x.id,"asset_type":x.asset_type,"name":x.name,"geometry_type":x.geometry_type,"geometry_json":x.geometry_json,"properties_json":x.properties_json,"source":x.source,"active":x.active}

@router.post("/farms/{farm_id}/geo-assets")
def create_geo(farm_id:str,payload:GeoAssetPayload,db:Session=Depends(get_db),principal:Principal=Depends(require_permission("platform.manage"))):
    farm=_farm(principal,db,farm_id); row=AtlasGeoAsset(company_id=principal.company.id,tenant_id=farm.tenant_id,farm_id=farm_id,**payload.model_dump()); db.add(row); db.commit(); db.refresh(row); return _geo_dict(row)

@router.get("/farms/{farm_id}/geo-assets")
def list_geo(farm_id:str,asset_type:str|None=None,db:Session=Depends(get_db),principal:Principal=Depends(require_permission("platform.read"))):
    _farm(principal,db,farm_id); q=select(AtlasGeoAsset).where(AtlasGeoAsset.company_id==principal.company.id,AtlasGeoAsset.farm_id==farm_id,AtlasGeoAsset.active.is_(True));
    if asset_type:q=q.where(AtlasGeoAsset.asset_type==asset_type)
    return [_geo_dict(x) for x in db.scalars(q.order_by(AtlasGeoAsset.name)).all()]

@router.post("/farms/{farm_id}/geo/import")
def import_geojson(farm_id:str,feature_collection:dict[str,Any],db:Session=Depends(get_db),principal:Principal=Depends(require_permission("platform.manage"))):
    farm=_farm(principal,db,farm_id); created=[]
    for f in feature_collection.get("features",[]):
        p=f.get("properties",{}); g=f.get("geometry",{}); row=AtlasGeoAsset(company_id=principal.company.id,tenant_id=farm.tenant_id,farm_id=farm_id,asset_type=p.get("asset_type","paddock"),name=p.get("name","Área importada"),geometry_type=g.get("type","Polygon"),geometry_json=g,properties_json=p,source="geojson")
        db.add(row); created.append(row)
    db.commit(); return {"imported":len(created),"accepted_formats":["GeoJSON"],"kml_kmz_shapefile":"converter para GeoJSON no cliente ou serviço de importação"}

@router.post("/farms/{farm_id}/pasture")
def create_pasture(farm_id:str,payload:PasturePayload,db:Session=Depends(get_db),principal:Principal=Depends(require_permission("nutrition.write"))):
    farm=_farm(principal,db,farm_id); row=AtlasPastureRecord(company_id=principal.company.id,tenant_id=farm.tenant_id,farm_id=farm_id,**payload.model_dump()); db.add(row); db.commit(); db.refresh(row); return {"id":row.id,"record_type":row.record_type,"observed_at":row.observed_at,"carrying_capacity_au":_carrying(row)}

def _carrying(x:AtlasPastureRecord)->float:
    available=x.area_ha*x.forage_mass_kg_dm_ha*(x.utilization_percent/100)
    demand=max(x.days_available,1)*12.0
    return round(available/demand,2) if demand else 0

@router.get("/farms/{farm_id}/pasture/dashboard")
def pasture_dashboard(farm_id:str,db:Session=Depends(get_db),principal:Principal=Depends(require_permission("nutrition.read"))):
    _farm(principal,db,farm_id); rows=list(db.scalars(select(AtlasPastureRecord).where(AtlasPastureRecord.company_id==principal.company.id,AtlasPastureRecord.farm_id==farm_id).order_by(AtlasPastureRecord.observed_at.desc())).all()); latest={}
    for r in rows:
        key=r.paddock_id or "farm"; latest.setdefault(key,r)
    return {"records":len(rows),"paddocks":[{"paddock_id":k,"height_cm":v.height_cm,"forage_mass_kg_dm_ha":v.forage_mass_kg_dm_ha,"carrying_capacity_au":_carrying(v),"rotation_recommendation":("retirar animais" if v.height_cm and v.height_cm<15 else "manter monitoramento") } for k,v in latest.items()],"total_cost":round(sum(r.cost for r in rows),2)}

@router.post("/farms/{farm_id}/agriculture")
def create_agriculture(farm_id:str,payload:AgriculturePayload,db:Session=Depends(get_db),principal:Principal=Depends(require_permission("nutrition.write"))):
    farm=_farm(principal,db,farm_id); row=AtlasAgricultureRecord(company_id=principal.company.id,tenant_id=farm.tenant_id,farm_id=farm_id,**payload.model_dump()); db.add(row); db.commit(); db.refresh(row); return {"id":row.id,"record_type":row.record_type,"total_cost":row.quantity*row.unit_cost}

@router.get("/farms/{farm_id}/agriculture/dashboard")
def agriculture_dashboard(farm_id:str,db:Session=Depends(get_db),principal:Principal=Depends(require_permission("nutrition.read"))):
    _farm(principal,db,farm_id); rows=list(db.scalars(select(AtlasAgricultureRecord).where(AtlasAgricultureRecord.company_id==principal.company.id,AtlasAgricultureRecord.farm_id==farm_id)).all()); by_type={}
    for r in rows: by_type[r.record_type]=by_type.get(r.record_type,0)+r.quantity
    return {"records":len(rows),"quantity_by_type":by_type,"total_cost":round(sum(r.quantity*r.unit_cost for r in rows),2),"linked_to_nutrition":sum(1 for r in rows if r.linked_nutrition_plan_id)}

@router.put("/farms/{farm_id}/genetics")
def upsert_genetics(farm_id:str,payload:GeneticPayload,db:Session=Depends(get_db),principal:Principal=Depends(require_permission("herd.write"))):
    farm=_farm(principal,db,farm_id); animal=_animal(principal,db,farm_id,payload.animal_id)
    for pid in [payload.sire_animal_id,payload.dam_animal_id]:
        if pid:_animal(principal,db,farm_id,pid)
    row=db.scalar(select(AtlasGeneticProfile).where(AtlasGeneticProfile.company_id==principal.company.id,AtlasGeneticProfile.animal_id==payload.animal_id))
    data=payload.model_dump(); score=_genetic_score(data["dep_json"],data["economic_index"],data["dna_verified"])
    coef=_inbreeding(db,principal.company.id,payload.sire_animal_id,payload.dam_animal_id)
    if row:
        for k,v in data.items():setattr(row,k,v)
        row.genetic_score=score; row.inbreeding_coefficient=coef
    else:
        row=AtlasGeneticProfile(company_id=principal.company.id,tenant_id=farm.tenant_id,farm_id=farm_id,genetic_score=score,inbreeding_coefficient=coef,**data); db.add(row)
    db.commit(); db.refresh(row); return _genetic_dict(row)

def _genetic_score(dep:dict[str,Any],economic:float,verified:bool)->float:
    vals=[float(v) for v in dep.values() if isinstance(v,(int,float))]; base=(sum(vals)/len(vals)) if vals else 0; return round(max(0,min(100,50+base+economic*0.1+(5 if verified else 0))),2)

def _inbreeding(db:Session,cid:str,sire:str|None,dam:str|None)->float:
    if not sire or not dam:return 0
    sp=db.scalar(select(AtlasGeneticProfile).where(AtlasGeneticProfile.company_id==cid,AtlasGeneticProfile.animal_id==sire)); dp=db.scalar(select(AtlasGeneticProfile).where(AtlasGeneticProfile.company_id==cid,AtlasGeneticProfile.animal_id==dam))
    if not sp or not dp:return 0
    shared=len({sp.sire_animal_id,sp.dam_animal_id}-{None} & ({dp.sire_animal_id,dp.dam_animal_id}-{None})); return round(12.5*shared,2)

def _genetic_dict(x:AtlasGeneticProfile)->dict[str,Any]:
    return {"id":x.id,"animal_id":x.animal_id,"sire_animal_id":x.sire_animal_id,"dam_animal_id":x.dam_animal_id,"registry_number":x.registry_number,"breed_composition":x.breed_composition_json,"dep":x.dep_json,"economic_index":x.economic_index,"genetic_score":x.genetic_score,"inbreeding_coefficient":x.inbreeding_coefficient,"dna_verified":x.dna_verified}

@router.get("/farms/{farm_id}/genetics/ranking")
def genetics_ranking(farm_id:str,db:Session=Depends(get_db),principal:Principal=Depends(require_permission("herd.read"))):
    _farm(principal,db,farm_id); rows=db.scalars(select(AtlasGeneticProfile).where(AtlasGeneticProfile.company_id==principal.company.id,AtlasGeneticProfile.farm_id==farm_id).order_by(AtlasGeneticProfile.genetic_score.desc())).all(); return [_genetic_dict(x) for x in rows]

@router.get("/farms/{farm_id}/genetics/{animal_id}/pedigree")
def pedigree(farm_id:str,animal_id:str,generations:int=Query(default=3,ge=1,le=5),db:Session=Depends(get_db),principal:Principal=Depends(require_permission("herd.read"))):
    _farm(principal,db,farm_id); _animal(principal,db,farm_id,animal_id)
    def node(aid:str|None,depth:int):
        if not aid or depth>generations:return None
        a=db.scalar(select(LivestockAnimal).where(LivestockAnimal.id==aid,LivestockAnimal.company_id==principal.company.id)); p=db.scalar(select(AtlasGeneticProfile).where(AtlasGeneticProfile.company_id==principal.company.id,AtlasGeneticProfile.animal_id==aid))
        if not a:return None
        return {"animal_id":a.id,"tag":a.tag,"breed":a.breed,"sire":node(p.sire_animal_id,depth+1) if p else None,"dam":node(p.dam_animal_id,depth+1) if p else None}
    return node(animal_id,1)

@router.post("/farms/{farm_id}/genetics/mating-simulator")
def mating_simulator(farm_id:str,animal_ids:list[str],db:Session=Depends(get_db),principal:Principal=Depends(require_permission("herd.read"))):
    _farm(principal,db,farm_id); profiles=list(db.scalars(select(AtlasGeneticProfile).where(AtlasGeneticProfile.company_id==principal.company.id,AtlasGeneticProfile.farm_id==farm_id,AtlasGeneticProfile.animal_id.in_(animal_ids))).all()); pairs=[]
    for i,a in enumerate(profiles):
        for b in profiles[i+1:]:
            penalty=25 if ({a.sire_animal_id,a.dam_animal_id}-{None}) & ({b.sire_animal_id,b.dam_animal_id}-{None}) else 0
            score=round((a.genetic_score+b.genetic_score)/2-penalty,2); pairs.append({"animal_a":a.animal_id,"animal_b":b.animal_id,"projected_score":score,"inbreeding_risk":"high" if penalty else "low"})
    return sorted(pairs,key=lambda x:x["projected_score"],reverse=True)

@router.post("/farms/{farm_id}/ai/forecast")
def forecast(farm_id:str,payload:ForecastRequest,db:Session=Depends(get_db),principal:Principal=Depends(require_permission("platform.read"))):
    farm=_farm(principal,db,farm_id); prediction,evidence,score,confidence,recommendation=_forecast(db,principal.company.id,farm_id,payload)
    row=AtlasAiForecast(company_id=principal.company.id,tenant_id=farm.tenant_id,farm_id=farm_id,animal_id=payload.animal_id,lot_id=payload.lot_id,forecast_type=payload.forecast_type,horizon_days=payload.horizon_days,score=score,confidence_percent=confidence,prediction_json=prediction,evidence_json=evidence,recommendation=recommendation); db.add(row); db.commit(); db.refresh(row)
    return {"id":row.id,"type":row.forecast_type,"score":score,"confidence_percent":confidence,"prediction":prediction,"evidence":evidence,"recommendation":recommendation,"model_version":row.model_version}

def _forecast(db:Session,cid:str,fid:str,p:ForecastRequest):
    animals=list(db.scalars(select(LivestockAnimal).where(LivestockAnimal.company_id==cid,LivestockAnimal.farm_id==fid,LivestockAnimal.status=="active")).all()); evidence=[]; confidence=60.0; score=50.0; pred={}
    if p.animal_id:
        a=next((x for x in animals if x.id==p.animal_id),None)
        if not a:raise HTTPException(404,"Animal não encontrado.")
    else:a=None
    if p.forecast_type=="weight_gain":
        if not a:raise HTTPException(422,"animal_id é obrigatório.")
        ws=list(db.scalars(select(WeightRecord).where(WeightRecord.company_id==cid,WeightRecord.animal_id==a.id).order_by(WeightRecord.weighed_at.desc()).limit(2)).all()); gmd=0
        if len(ws)>=2:
            days=max((ws[0].weighed_at-ws[1].weighed_at).days,1); gmd=(ws[0].weight-ws[1].weight)/days; confidence=82
        predicted=a.current_weight+gmd*p.horizon_days; pred={"current_weight":a.current_weight,"daily_gain":round(gmd,3),"predicted_weight":round(predicted,2)}; score=min(100,max(0,50+gmd*30)); evidence=[f"{len(ws)} pesagens recentes",f"horizonte de {p.horizon_days} dias"]
    elif p.forecast_type=="reproduction":
        females=[x for x in animals if (x.sex or '').lower() in {'f','female','fêmea','femea'}]; pregnant=sum(1 for x in females if x.reproductive_status=='pregnant'); rate=100*pregnant/max(len(females),1); pred={"pregnancy_rate_percent":round(rate,2),"eligible_females":len(females)}; score=rate; confidence=75; evidence=[f"{len(females)} fêmeas",f"{pregnant} prenhes"]
    elif p.forecast_type=="health":
        since=datetime.now(timezone.utc)-timedelta(days=90); events=db.scalar(select(func.count()).select_from(HealthEvent).where(HealthEvent.company_id==cid,HealthEvent.farm_id==fid,HealthEvent.occurred_at>=since)) or 0; rate=events/max(len(animals),1); score=max(0,100-rate*20); pred={"events_90d":events,"events_per_animal":round(rate,3),"risk_level":"high" if rate>1 else "moderate" if rate>.3 else "low"}; confidence=70; evidence=[f"{events} eventos sanitários em 90 dias"]
    elif p.forecast_type=="nutrition":
        events=list(db.scalars(select(NutritionEvent).where(NutritionEvent.company_id==cid,NutritionEvent.farm_id==fid).order_by(NutritionEvent.occurred_at.desc()).limit(30)).all()); cost=sum(getattr(x,'total_cost',0) or 0 for x in events); pred={"recent_events":len(events),"recent_cost":round(cost,2),"cost_per_animal":round(cost/max(len(animals),1),2)}; score=max(0,100-min(cost/max(len(animals),1),100)); confidence=65; evidence=[f"{len(events)} fornecimentos recentes"]
    elif p.forecast_type in {'economic','risk'}:
        rows=list(db.scalars(select(FinancialEntry).where(FinancialEntry.company_id==cid,FinancialEntry.farm_id==fid)).all()); income=sum(x.amount for x in rows if x.entry_type=='income'); expense=sum(x.amount for x in rows if x.entry_type=='expense'); balance=income-expense; score=max(0,min(100,50+(balance/max(expense,1))*50)); pred={"income":income,"expense":expense,"projected_balance":balance,"risk_level":"high" if balance<0 else "low"}; confidence=80; evidence=[f"{len(rows)} lançamentos financeiros"]
    elif p.forecast_type=='mortality':
        deaths=sum(1 for x in animals if x.status in {'dead','deceased'}); risk=100*deaths/max(len(animals)+deaths,1); score=100-risk; pred={"mortality_risk_percent":round(risk,2)}; confidence=55; evidence=["histórico de situação dos animais"]
    elif p.forecast_type=='stocking':
        lots=list(db.scalars(select(HerdLot).where(HerdLot.company_id==cid,HerdLot.farm_id==fid,HerdLot.active.is_(True))).all()); per={l.id:sum(1 for a0 in animals if a0.lot_id==l.id) for l in lots}; pred={"animals_by_lot":per,"suggestion":"redistribuir" if per and max(per.values())-min(per.values())>10 else "distribuição equilibrada"}; score=75; confidence=65; evidence=[f"{len(lots)} lotes ativos"]
    elif p.forecast_type=='climate':
        temp=float(p.climate.get('temperature_c',25)); rain=float(p.climate.get('rain_mm_7d',0)); thi=float(p.climate.get('thi',temp+20)); stress=thi>=72; pred={"heat_stress":stress,"temperature_c":temp,"rain_mm_7d":rain,"pasture_risk":"high" if rain<10 else "low"}; score=40 if stress else 80; confidence=50 if not p.climate else 75; evidence=["dados climáticos fornecidos na requisição"]
    else:
        pred={"data_completeness_percent":round(100*sum(1 for a0 in animals if a0.current_weight>0)/max(len(animals),1),2),"animals":len(animals)}; score=pred['data_completeness_percent']; confidence=90; evidence=["cadastros oficiais de rebanho"]
    recommendation="Manter monitoramento e executar a ação de maior impacto indicada pelas evidências." if score>=60 else "Priorizar correção imediata e reavaliar após novos dados."
    return pred,evidence,round(score,2),round(confidence,2),recommendation

@router.get("/farms/{farm_id}/advanced-dashboard")
def advanced_dashboard(farm_id:str,db:Session=Depends(get_db),principal:Principal=Depends(require_permission("platform.read"))):
    _farm(principal,db,farm_id); cid=principal.company.id
    def count(model):return int(db.scalar(select(func.count()).select_from(model).where(model.company_id==cid,model.farm_id==farm_id)) or 0)
    return {"geo_assets":count(AtlasGeoAsset),"pasture_records":count(AtlasPastureRecord),"agriculture_records":count(AtlasAgricultureRecord),"genetic_profiles":count(AtlasGeneticProfile),"ai_forecasts":count(AtlasAiForecast),"implemented_blocks":["AI","Georreferenciamento","Pastagens","Agricultura integrada","Genética"]}
