from __future__ import annotations
from datetime import datetime
from hashlib import sha256
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session
from ..advanced_models import AtlasGeoAsset
from ..authz import Principal, require_farm_scope, require_permission
from ..database import get_db
from ..innovation_models import AtlasIotDevice, AtlasVisionAnalysis
from ..models import LivestockAnimal
from ..precision_hub_models import AnimalRfidBinding, DeviceAdapter, PrecisionEvent, PrecisionGeoFence, RemoteSensingScene, VisionHumanReview
from ..services.precision_hub_service import ingest
router=APIRouter(prefix='/precision-hub',tags=['Precision Hub'])
class AdapterIn(BaseModel): adapter_key:str; manufacturer:str=''; protocol:str='http-json'; configuration:dict=Field(default_factory=dict); secret:str=''
class DeviceIn(BaseModel): name:str; device_type:str; external_id:str=''; configuration:dict=Field(default_factory=dict)
class RfidIn(BaseModel): animal_id:str; tag_code:str
class TelemetryIn(BaseModel): metric:str; value:float; unit:str=''; animal_id:str|None=None; occurred_at:datetime|None=None; payload:dict=Field(default_factory=dict)
class FenceIn(BaseModel): name:str; polygon:dict; rule_type:str='inside'
class GeoIn(BaseModel): asset_type:str; name:str; geometry_type:str; geometry:dict; properties:dict=Field(default_factory=dict); source:str='manual'
class VisionIn(BaseModel): analysis_type:str; media_url:str=''; animal_id:str|None=None; input:dict=Field(default_factory=dict); result:dict=Field(default_factory=dict); confidence:float=0; model_version:str='pending-adapter'; status:str='pending'
class ReviewIn(BaseModel): decision:str; corrected_result:dict=Field(default_factory=dict); notes:str=''
class SceneIn(BaseModel): provider:str='manual'; external_id:str=''; captured_at:datetime|None=None; cloud_percent:float=0; indices:dict=Field(default_factory=dict); asset_uri:str=''
def read_dep(p=Depends(require_permission('platform.read'))): return p
def manage_dep(p=Depends(require_permission('platform.manage'))): return p
@router.post('/adapters')
def adapter(payload:AdapterIn,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=DeviceAdapter(tenant_id=p.company.tenant_id,company_id=p.company.id,adapter_key=payload.adapter_key,manufacturer=payload.manufacturer,protocol=payload.protocol,configuration_json=payload.configuration,secret_hash=sha256(payload.secret.encode()).hexdigest() if payload.secret else '')
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'adapter_key':row.adapter_key}
@router.post('/farms/{farm_id}/devices')
def device(farm_id:str,payload:DeviceIn,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    require_farm_scope(p,farm_id); row=AtlasIotDevice(company_id=p.company.id,tenant_id=p.company.tenant_id,farm_id=farm_id,name=payload.name,device_type=payload.device_type,external_id=payload.external_id,configuration_json=payload.configuration); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}
@router.post('/farms/{farm_id}/rfid-bindings')
def rfid(farm_id:str,payload:RfidIn,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    require_farm_scope(p,farm_id); animal=db.scalar(select(LivestockAnimal).where(LivestockAnimal.id==payload.animal_id,LivestockAnimal.company_id==p.company.id,LivestockAnimal.farm_id==farm_id));
    if not animal: raise HTTPException(404,'Animal não encontrado.')
    row=AnimalRfidBinding(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=farm_id,animal_id=payload.animal_id,tag_code=payload.tag_code); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'tag_code':row.tag_code}
@router.post('/devices/{device_id}/telemetry')
def telemetry(device_id:str,payload:TelemetryIn,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    device=db.scalar(select(AtlasIotDevice).where(AtlasIotDevice.id==device_id,AtlasIotDevice.company_id==p.company.id));
    if not device: raise HTTPException(404,'Dispositivo não encontrado.')
    require_farm_scope(p,device.farm_id); row,events,animal_id=ingest(db,company_id=p.company.id,tenant_id=p.company.tenant_id,farm_id=device.farm_id,device=device,metric=payload.metric,value=payload.value,unit=payload.unit,payload=payload.payload,animal_id=payload.animal_id,occurred_at=payload.occurred_at,created_by=p.user.id); db.commit(); db.refresh(row)
    return {'id':row.id,'animal_id':animal_id,'events':[{'type':x[0],'severity':x[1],'payload':x[2]} for x in events]}
@router.post('/farms/{farm_id}/geofences')
def geofence(farm_id:str,payload:FenceIn,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    require_farm_scope(p,farm_id)
    if payload.rule_type not in {'inside','outside'}: raise HTTPException(422,'rule_type inválido.')
    row=PrecisionGeoFence(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=farm_id,name=payload.name,polygon_json=payload.polygon,rule_type=payload.rule_type); db.add(row); db.commit(); db.refresh(row); return {'id':row.id}
@router.post('/farms/{farm_id}/geo-assets')
def geo(farm_id:str,payload:GeoIn,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    require_farm_scope(p,farm_id)
    if payload.geometry_type not in {'Point','LineString','Polygon','MultiPolygon'}: raise HTTPException(422,'Geometria não suportada.')
    row=AtlasGeoAsset(company_id=p.company.id,tenant_id=p.company.tenant_id,farm_id=farm_id,asset_type=payload.asset_type,name=payload.name,geometry_type=payload.geometry_type,geometry_json=payload.geometry,properties_json=payload.properties,source=payload.source); db.add(row); db.commit(); db.refresh(row); return {'id':row.id}
@router.post('/farms/{farm_id}/vision')
def vision(farm_id:str,payload:VisionIn,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    require_farm_scope(p,farm_id); row=AtlasVisionAnalysis(company_id=p.company.id,tenant_id=p.company.tenant_id,farm_id=farm_id,animal_id=payload.animal_id,analysis_type=payload.analysis_type,media_url=payload.media_url,input_json=payload.input,result_json=payload.result,confidence=payload.confidence,model_version=payload.model_version,status=payload.status); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}
@router.post('/vision/{analysis_id}/review')
def review(analysis_id:str,payload:ReviewIn,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    analysis=db.scalar(select(AtlasVisionAnalysis).where(AtlasVisionAnalysis.id==analysis_id,AtlasVisionAnalysis.company_id==p.company.id));
    if not analysis: raise HTTPException(404,'Análise não encontrada.')
    if payload.decision not in {'confirmed','corrected','rejected'}: raise HTTPException(422,'Decisão inválida.')
    row=VisionHumanReview(tenant_id=p.company.tenant_id,company_id=p.company.id,analysis_id=analysis_id,reviewer_id=p.user.id,decision=payload.decision,corrected_result_json=payload.corrected_result,notes=payload.notes); analysis.status='reviewed';
    if payload.corrected_result: analysis.result_json=payload.corrected_result
    db.add(row); db.commit(); return {'id':row.id,'status':analysis.status}
@router.post('/farms/{farm_id}/remote-sensing/scenes')
def scene(farm_id:str,payload:SceneIn,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    require_farm_scope(p,farm_id); row=RemoteSensingScene(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=farm_id,provider=payload.provider,external_id=payload.external_id,captured_at=payload.captured_at or datetime.utcnow(),cloud_percent=payload.cloud_percent,indices_json=payload.indices,asset_uri=payload.asset_uri); db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}
@router.get('/farms/{farm_id}/dashboard')
def dashboard(farm_id:str,db:Session=Depends(get_db),p:Principal=Depends(read_dep)):
    require_farm_scope(p,farm_id); c=p.company.id
    return {'farm_id':farm_id,'devices':db.scalar(select(func.count()).select_from(AtlasIotDevice).where(AtlasIotDevice.company_id==c,AtlasIotDevice.farm_id==farm_id)) or 0,'rfid_bindings':db.scalar(select(func.count()).select_from(AnimalRfidBinding).where(AnimalRfidBinding.company_id==c,AnimalRfidBinding.farm_id==farm_id)) or 0,'alerts':db.scalar(select(func.count()).select_from(PrecisionEvent).where(PrecisionEvent.company_id==c,PrecisionEvent.farm_id==farm_id,PrecisionEvent.severity.in_(['warning','critical']))) or 0,'vision_analyses':db.scalar(select(func.count()).select_from(AtlasVisionAnalysis).where(AtlasVisionAnalysis.company_id==c,AtlasVisionAnalysis.farm_id==farm_id)) or 0,'geo_assets':db.scalar(select(func.count()).select_from(AtlasGeoAsset).where(AtlasGeoAsset.company_id==c,AtlasGeoAsset.farm_id==farm_id)) or 0,'remote_sensing_scenes':db.scalar(select(func.count()).select_from(RemoteSensingScene).where(RemoteSensingScene.company_id==c,RemoteSensingScene.farm_id==farm_id)) or 0}
