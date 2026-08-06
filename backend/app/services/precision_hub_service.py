from __future__ import annotations
from datetime import datetime, timezone
from math import sqrt
from sqlalchemy import select
from sqlalchemy.orm import Session
from ..innovation_models import AtlasIotDevice, AtlasIotTelemetry, AtlasVisionAnalysis
from ..models import LivestockAnimal, WeightRecord, new_id
from ..precision_hub_models import AnimalRfidBinding, PrecisionEvent, PrecisionGeoFence

def utcnow(): return datetime.now(timezone.utc)

def thi(temp_c:float, humidity:float)->float:
    return round((1.8*temp_c+32)-((0.55-0.0055*humidity)*(1.8*temp_c-26)),2)

def point_in_polygon(lat:float, lon:float, polygon:list[list[float]])->bool:
    inside=False; j=len(polygon)-1
    for i,p in enumerate(polygon):
        xi,yi=p[0],p[1]; xj,yj=polygon[j][0],polygon[j][1]
        if ((yi>lat)!=(yj>lat)) and (lon < (xj-xi)*(lat-yi)/(yj-yi+1e-12)+xi): inside=not inside
        j=i
    return inside

def resolve_rfid(db:Session,company_id:str,tag_code:str):
    binding=db.scalar(select(AnimalRfidBinding).where(AnimalRfidBinding.company_id==company_id,AnimalRfidBinding.tag_code==tag_code,AnimalRfidBinding.active.is_(True)))
    return binding.animal_id if binding else None

def ingest(db:Session,*,company_id:str,tenant_id:str,farm_id:str,device:AtlasIotDevice,metric:str,value:float,unit:str,payload:dict,animal_id:str|None,occurred_at:datetime|None,created_by:str):
    occurred_at=occurred_at or utcnow()
    if not animal_id and payload.get('rfid'): animal_id=resolve_rfid(db,company_id,str(payload['rfid']))
    telemetry=AtlasIotTelemetry(company_id=company_id,tenant_id=tenant_id,farm_id=farm_id,device_id=device.id,metric=metric,value=value,unit=unit,payload_json=payload,occurred_at=occurred_at)
    db.add(telemetry); device.last_seen_at=occurred_at; device.status='online'
    events=[]
    if metric=='weight_kg' and animal_id:
        stable=bool(payload.get('stable',True)); plausible=20<=value<=1600
        if stable and plausible:
            db.add(WeightRecord(tenant_id=tenant_id,company_id=company_id,farm_id=farm_id,animal_id=animal_id,weight=value,source='iot_scale',equipment=device.name,measured_at=occurred_at,created_by=created_by))
            animal=db.scalar(select(LivestockAnimal).where(LivestockAnimal.id==animal_id,LivestockAnimal.company_id==company_id))
            if animal: animal.current_weight=value; animal.updated_at=occurred_at
        else: events.append(('invalid_weight','warning',{'stable':stable,'plausible':plausible,'value':value}))
    if metric in {'temperature_c','humidity_percent'}:
        temp=float(payload.get('temperature_c',value if metric=='temperature_c' else 0)); hum=float(payload.get('humidity_percent',value if metric=='humidity_percent' else 0))
        if temp and hum:
            index=thi(temp,hum)
            if index>=79: events.append(('thermal_stress','critical' if index>=84 else 'warning',{'thi':index,'temperature_c':temp,'humidity_percent':hum}))
    if metric=='water_level_percent' and value<20: events.append(('low_water_level','critical',{'value':value}))
    if metric=='water_flow_l_min' and value>float(payload.get('max_expected',999999)): events.append(('possible_water_leak','warning',{'value':value}))
    if metric=='gps' and payload.get('latitude') is not None and payload.get('longitude') is not None:
        fences=db.scalars(select(PrecisionGeoFence).where(PrecisionGeoFence.company_id==company_id,PrecisionGeoFence.farm_id==farm_id,PrecisionGeoFence.active.is_(True))).all()
        for fence in fences:
            coords=(fence.polygon_json or {}).get('coordinates',[])
            poly=coords[0] if coords and isinstance(coords[0],list) and coords and coords[0] and isinstance(coords[0][0],list) else coords
            if poly:
                is_inside=point_in_polygon(float(payload['latitude']),float(payload['longitude']),poly)
                violation=(fence.rule_type=='inside' and not is_inside) or (fence.rule_type=='outside' and is_inside)
                if violation: events.append(('geofence_violation','critical',{'geofence_id':fence.id,'name':fence.name,'inside':is_inside}))
    for event_type,severity,data in events:
        db.add(PrecisionEvent(tenant_id=tenant_id,company_id=company_id,farm_id=farm_id,device_id=device.id,animal_id=animal_id,event_type=event_type,severity=severity,payload_json=data,occurred_at=occurred_at))
    return telemetry,events,animal_id
