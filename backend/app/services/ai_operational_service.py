from __future__ import annotations
import hashlib, json
from datetime import datetime, timedelta, timezone
from sqlalchemy import func, select
from sqlalchemy.orm import Session
from ..models import Farm, FinancialEntry, HealthEvent, InventoryProduct, LivestockAnimal, NutritionEvent, ReproductionEvent, WeightRecord

def _count(db, model, company_id, farm_id):
    return int(db.scalar(select(func.count()).select_from(model).where(model.company_id==company_id, model.farm_id==farm_id)) or 0)

def build_official_context(db: Session, *, company_id: str, farm_id: str, period_days: int = 90) -> dict:
    farm = db.scalar(select(Farm).where(Farm.id==farm_id, Farm.company_id==company_id))
    if farm is None: raise ValueError('Fazenda não encontrada.')
    start = datetime.now(timezone.utc)-timedelta(days=period_days)
    animals = db.scalars(select(LivestockAnimal).where(LivestockAnimal.company_id==company_id, LivestockAnimal.farm_id==farm_id)).all()
    females=[a for a in animals if (a.sex or '').lower() in {'f','female','fêmea','femea'}]
    weighed=sum(1 for a in animals if (a.current_weight or 0)>0)
    payload={
      'schema_version':'1.0','source':'official_database','period':{'start':start.isoformat(),'end':datetime.now(timezone.utc).isoformat()},
      'farm':{'id':farm.id,'name':farm.name,'area':farm.area},
      'herd':{'active_animals':len([a for a in animals if a.status=='active']),'females':len(females),'with_current_weight':weighed},
      'reproduction':{'events':_count(db,ReproductionEvent,company_id,farm_id),'pregnant':len([a for a in females if a.reproductive_status=='pregnant'])},
      'health':{'events':_count(db,HealthEvent,company_id,farm_id)},
      'nutrition':{'events':_count(db,NutritionEvent,company_id,farm_id)},
      'inventory':{'products':_count(db,InventoryProduct,company_id,farm_id)},
      'finance':{'entries':_count(db,FinancialEntry,company_id,farm_id)},
    }
    quality={'weight_coverage_percent':round(100*weighed/max(len(animals),1),2),'animal_count':len(animals),'limitations':[] if animals else ['Sem animais cadastrados.']}
    digest=hashlib.sha256(json.dumps(payload,sort_keys=True,ensure_ascii=False).encode()).hexdigest()
    return {'payload':payload,'quality':quality,'context_hash':digest}

def generate_recommendations(context: dict) -> list[dict]:
    p=context['payload']; q=context['quality']; items=[]
    herd=p['herd']; rep=p['reproduction']; health=p['health']; nutrition=p['nutrition']; finance=p['finance']
    if q['weight_coverage_percent']<80: items.append({'area':'nutrition','title':'Completar pesagens','description':'A cobertura de peso está abaixo de 80%.','evidence':[q],'confidence':0.95,'priority':'high','recommended_action':'Pesar os animais sem peso atual antes de ajustar dietas.','limitations':['A recomendação depende da atualização das pesagens.']})
    if rep['pregnant'] < max(1, int(herd['females']*.5)) and herd['females']>0: items.append({'area':'reproduction','title':'Revisar eficiência reprodutiva','description':'A proporção registrada de fêmeas prenhes está baixa.','evidence':[rep,herd],'confidence':0.82,'priority':'high','recommended_action':'Revisar elegibilidade, diagnóstico e protocolos.','limitations':['Status reprodutivo incompleto reduz a confiança.']})
    if health['events']==0 and herd['active_animals']>0: items.append({'area':'health','title':'Revisar calendário sanitário','description':'Não há eventos sanitários registrados para um rebanho ativo.','evidence':[health,herd],'confidence':0.75,'priority':'medium','recommended_action':'Confirmar protocolos e registrar procedimentos recentes.','limitations':['Ausência de registro não confirma ausência de manejo.']})
    if nutrition['events']==0 and herd['active_animals']>0: items.append({'area':'nutrition','title':'Registrar fornecimento nutricional','description':'Não existem consumos nutricionais oficiais no período.','evidence':[nutrition],'confidence':0.8,'priority':'medium','recommended_action':'Registrar consumo por lote para calcular eficiência alimentar.','limitations':[]})
    if finance['entries']==0: items.append({'area':'financial','title':'Completar dados financeiros','description':'Não existem lançamentos suficientes para análise econômica.','evidence':[finance],'confidence':0.98,'priority':'medium','recommended_action':'Registrar receitas e despesas antes de simulações financeiras.','limitations':['Sem dados financeiros não há projeção confiável.']})
    return items
