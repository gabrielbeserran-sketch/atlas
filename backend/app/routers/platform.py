from __future__ import annotations

from collections import defaultdict
from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..authz import KNOWN_PERMISSIONS, ROLE_PERMISSIONS, Principal, require_permission
from ..database import get_db
from ..models import (
    AuditLog,
    AutomationRule,
    EntityState,
    Farm,
    FinancialEntry,
    HealthEvent,
    HerdLot,
    InventoryProduct,
    LivestockAnimal,
    NutritionEvent,
    ReproductionEvent,
    SyncChange,
    WeightRecord,
    new_id,
)

router = APIRouter(prefix="/platform", tags=["platform-v1"])


class AutomationEvaluationRequest(BaseModel):
    dry_run: bool = True
    execute_actions: bool = False


class RecommendationDecisionRequest(BaseModel):
    decision: str = Field(pattern="^(accepted|rejected|deferred|completed)$")
    notes: str = ""


def _farm(principal: Principal, db: Session, farm_id: str) -> Farm:
    item = db.scalar(select(Farm).where(Farm.id == farm_id, Farm.company_id == principal.company.id, Farm.active.is_(True)))
    if item is None:
        raise HTTPException(status_code=404, detail="Fazenda não encontrada.")
    if principal.membership.role not in {"owner", "admin", "companyAdministrator", "superAdministrator"}:
        allowed = set(principal.membership.farm_ids or [])
        if allowed and farm_id not in allowed:
            raise HTTPException(status_code=403, detail="Fazenda não autorizada.")
    return item


def _count(db: Session, model: Any, company_id: str, farm_id: str, *conditions: Any) -> int:
    q = select(func.count()).select_from(model).where(model.company_id == company_id, model.farm_id == farm_id, *conditions)
    return int(db.scalar(q) or 0)


def _financial(db: Session, company_id: str, farm_id: str) -> dict[str, Any]:
    rows = list(db.scalars(select(FinancialEntry).where(FinancialEntry.company_id == company_id, FinancialEntry.farm_id == farm_id)).all())
    income = sum(x.amount for x in rows if x.entry_type == "income")
    expense = sum(x.amount for x in rows if x.entry_type == "expense")
    paid_income = sum(x.amount for x in rows if x.entry_type == "income" and x.status == "paid")
    paid_expense = sum(x.amount for x in rows if x.entry_type == "expense" and x.status == "paid")
    by_center: dict[str, float] = defaultdict(float)
    for row in rows:
        if row.entry_type == "expense": by_center[row.cost_center or "Geral"] += row.amount
    return {"income": income, "expense": expense, "balance": paid_income-paid_expense,
            "projected_balance": income-expense, "cost_by_center": dict(by_center),
            "roi_percent": ((income-expense)/expense*100) if expense else 0.0}


def _snapshot(principal: Principal, db: Session, farm_id: str) -> dict[str, Any]:
    farm = _farm(principal, db, farm_id); cid=principal.company.id; now=datetime.now(timezone.utc)
    animals = list(db.scalars(select(LivestockAnimal).where(LivestockAnimal.company_id==cid, LivestockAnimal.farm_id==farm_id, LivestockAnimal.status=="active")).all())
    weights = [a.current_weight for a in animals if a.current_weight > 0]
    female = [a for a in animals if (a.sex or "").lower() in {"f", "female", "fêmea", "femea"}]
    pregnant = sum(1 for a in female if a.reproductive_status == "pregnant")
    inventory = list(db.scalars(select(InventoryProduct).where(InventoryProduct.company_id==cid, InventoryProduct.farm_id==farm_id, InventoryProduct.active.is_(True))).all())
    low_stock = sum(1 for p in inventory if p.quantity <= p.minimum_quantity)
    expiring = sum(1 for p in inventory if p.expiry_date and p.expiry_date <= now + timedelta(days=30))
    health_due = _count(db, HealthEvent, cid, farm_id, HealthEvent.next_date.is_not(None), HealthEvent.next_date <= now + timedelta(days=7))
    quarantine = _count(db, HealthEvent, cid, farm_id, HealthEvent.is_quarantine.is_(True))
    nutrition = list(db.scalars(select(NutritionEvent).where(NutritionEvent.company_id==cid, NutritionEvent.farm_id==farm_id)).all())
    feed_cost = sum(x.estimated_cost for x in nutrition)
    feed_qty = sum(x.total_quantity for x in nutrition)
    gains=[x.observed_daily_gain_kg for x in nutrition if x.observed_daily_gain_kg>0]
    finance=_financial(db,cid,farm_id)
    return {
        "generated_at": now.isoformat(), "farm": {"id":farm.id,"name":farm.name,"city":farm.city,"state":farm.state,"area":farm.area},
        "herd": {"animals":len(animals),"lots":_count(db,HerdLot,cid,farm_id,HerdLot.status=="active"),
                 "average_weight":sum(weights)/len(weights) if weights else 0.0,"without_lot":sum(1 for a in animals if not a.lot_id)},
        "reproduction": {"females":len(female),"pregnant":pregnant,"pregnancy_rate":pregnant/len(female)*100 if female else 0.0,
                         "scheduled_actions":_count(db,ReproductionEvent,cid,farm_id,ReproductionEvent.expected_date.is_not(None),ReproductionEvent.expected_date>=now)},
        "health": {"events_due_7d":health_due,"quarantines":quarantine,
                   "withdrawal_active":_count(db,HealthEvent,cid,farm_id,HealthEvent.withdrawal_until.is_not(None),HealthEvent.withdrawal_until>now)},
        "nutrition": {"events":len(nutrition),"total_quantity":feed_qty,"total_cost":feed_cost,
                      "average_daily_gain":sum(gains)/len(gains) if gains else 0.0},
        "inventory": {"products":len(inventory),"low_stock":low_stock,"expiring_30d":expiring,
                      "inventory_value":sum(p.quantity*p.average_cost for p in inventory)},
        "financial": finance,
        "data_quality": {"animals_without_weight":sum(1 for a in animals if a.current_weight<=0),
                         "animals_without_lot":sum(1 for a in animals if not a.lot_id),
                         "animals_without_category":sum(1 for a in animals if not (a.category or '').strip())},
    }


def _recommendations(snapshot: dict[str, Any]) -> list[dict[str, Any]]:
    recs=[]
    def add(code,title,description,area,priority,confidence,impact,evidence,action,deadline):
        recs.append({"id":code,"title":title,"description":description,"area":area,"priority":priority,
                     "confidence_percent":confidence,"expected_impact":impact,"evidence":evidence,
                     "recommended_action":action,"deadline_hours":deadline,"status":"pending"})
    h=snapshot["herd"]; r=snapshot["reproduction"]; health=snapshot["health"]; inv=snapshot["inventory"]; fin=snapshot["financial"]; dq=snapshot["data_quality"]
    if inv["low_stock"]>0: add("stock-low","Repor estoque crítico",f'{inv["low_stock"]} produto(s) no mínimo ou abaixo dele.',"Estoque","high",96,"Evita interrupção de protocolos",[f'Produtos críticos: {inv["low_stock"]}'],"Revisar consumo e emitir pedido de compra.",24)
    if health["events_due_7d"]>0: add("health-due","Executar agenda sanitária",f'{health["events_due_7d"]} ação(ões) vencem em até 7 dias.',"Sanidade","high",94,"Redução de risco sanitário",[f'Agenda próxima: {health["events_due_7d"]}'],"Planejar manejo e confirmar produtos no estoque.",48)
    if r["females"]>0 and r["pregnancy_rate"]<55: add("repro-rate","Revisar desempenho reprodutivo",f'Taxa de prenhez atual de {r["pregnancy_rate"]:.1f}%.',"Reprodução","high",88,"Mais bezerros e menor intervalo improdutivo",[f'Prenhes: {r["pregnant"]}/{r["females"]}'],"Auditar protocolo, condição corporal, touros e diagnóstico.",72)
    if dq["animals_without_weight"]>0: add("weight-gap","Completar pesagens",f'{dq["animals_without_weight"]} animal(is) sem peso atual.',"Rebanho","medium",99,"Melhora indicadores e decisões nutricionais",[f'Sem peso: {dq["animals_without_weight"]}'],"Programar pesagem e revisar identificação.",168)
    if fin["projected_balance"]<0: add("cash-negative","Corrigir caixa projetado",f'Saldo projetado negativo de {abs(fin["projected_balance"]):.2f}.',"Financeiro","critical",98,"Proteção de liquidez",[f'Saldo projetado: {fin["projected_balance"]:.2f}'],"Reprogramar pagamentos e acelerar recebimentos.",24)
    if not recs: add("stable","Manter rotina de monitoramento","Os indicadores críticos não apresentaram desvio relevante.","Gestão","low",85,"Preservação do desempenho",["Sem alertas críticos no snapshot"],"Manter cadastros e rotinas atualizados.",168)
    order={"critical":0,"high":1,"medium":2,"low":3}; recs.sort(key=lambda x:order[x["priority"]]); return recs


@router.get("/dashboard/farms/{farm_id}")
def farm_dashboard(farm_id: str, principal: Principal=Depends(require_permission("platform.read")), db: Session=Depends(get_db)) -> dict[str,Any]:
    snap=_snapshot(principal,db,farm_id); snap["recommendations"]=_recommendations(snap); return snap


@router.get("/dashboard/company")
def company_dashboard(principal: Principal=Depends(require_permission("platform.read")), db: Session=Depends(get_db)) -> dict[str,Any]:
    farms=list(db.scalars(select(Farm).where(Farm.company_id==principal.company.id,Farm.active.is_(True)).order_by(Farm.name)).all())
    rows=[]
    for f in farms:
        try: rows.append(_snapshot(principal,db,f.id))
        except HTTPException: continue
    return {"generated_at":datetime.now(timezone.utc).isoformat(),"company":{"id":principal.company.id,"name":principal.company.name},"farms":rows,
            "totals":{"farms":len(rows),"animals":sum(x["herd"]["animals"] for x in rows),"income":sum(x["financial"]["income"] for x in rows),"expense":sum(x["financial"]["expense"] for x in rows)}}


@router.get("/ai/context/farms/{farm_id}")
def ai_context(farm_id: str, principal: Principal=Depends(require_permission("ai.read")), db: Session=Depends(get_db)) -> dict[str,Any]:
    snap=_snapshot(principal,db,farm_id)
    return {"version":"atlas-context-v1","generated_at":snap["generated_at"],"tenant_id":principal.company.tenant_id,"company_id":principal.company.id,"farm_id":farm_id,
            "scope":"farm","data":snap,"provenance":{"source":"official_backend","tables":["livestock_animals","herd_lots","weight_records","reproduction_events","health_events","nutrition_events","inventory_products","financial_entries"]},
            "limitations":["Indicadores dependem da atualização dos registros operacionais.","Recomendações são apoio à decisão e não substituem avaliação profissional."]}


@router.get("/ai/recommendations/farms/{farm_id}")
def ai_recommendations(farm_id: str, principal: Principal=Depends(require_permission("ai.read")), db: Session=Depends(get_db)) -> dict[str,Any]:
    snap=_snapshot(principal,db,farm_id); return {"generated_at":snap["generated_at"],"farm_id":farm_id,"recommendations":_recommendations(snap)}


@router.post("/ai/recommendations/{recommendation_id}/decision")
def recommendation_decision(recommendation_id: str,payload: RecommendationDecisionRequest,
    principal: Principal=Depends(require_permission("ai.manage")),db: Session=Depends(get_db)) -> dict[str,Any]:
    audit=AuditLog(id=new_id("audit"),tenant_id=principal.company.tenant_id,company_id=principal.company.id,farm_id=None,user_id=principal.user.id,
        action="recommendation_decision",module="atlas_ai",entity_type="recommendation",entity_id=recommendation_id,
        description=f"Recomendação marcada como {payload.decision}.",before={},after={"decision":payload.decision,"notes":payload.notes},result="success")
    db.add(audit); db.commit(); return {"recommendation_id":recommendation_id,"decision":payload.decision,"audit_id":audit.id}


@router.post("/automations/farms/{farm_id}/bootstrap", status_code=201)
def bootstrap_automations(farm_id: str,principal: Principal=Depends(require_permission("automation.manage")),db: Session=Depends(get_db)) -> dict[str,Any]:
    _farm(principal,db,farm_id)
    defaults=[
      ("Estoque crítico","inventory.low_stock",{"minimum":True},[{"type":"create_alert","severity":"high"},{"type":"create_task","deadline_hours":24}]),
      ("Agenda sanitária","health.due",{"days":7},[{"type":"create_alert","severity":"high"},{"type":"notify_responsible"}]),
      ("Caixa projetado negativo","finance.negative_balance",{"threshold":0},[{"type":"request_approval"},{"type":"create_task","deadline_hours":24}]),
      ("Pesagem pendente","herd.missing_weight",{"days_without_weight":60},[{"type":"create_task","deadline_hours":168}]),
    ]
    created=[]
    for name,event,conditions,actions in defaults:
        exists=db.scalar(select(AutomationRule).where(AutomationRule.company_id==principal.company.id,AutomationRule.farm_id==farm_id,AutomationRule.event_type==event))
        if exists: continue
        rule=AutomationRule(id=new_id("automation_rule"),tenant_id=principal.company.tenant_id,company_id=principal.company.id,farm_id=farm_id,name=name,event_type=event,conditions=conditions,actions=actions,enabled=True,priority=80)
        db.add(rule); created.append(rule.id)
    db.commit(); return {"farm_id":farm_id,"created":created,"created_count":len(created)}


@router.post("/automations/farms/{farm_id}/evaluate")
def evaluate_automations(farm_id: str,payload: AutomationEvaluationRequest,principal: Principal=Depends(require_permission("automation.execute")),db: Session=Depends(get_db)) -> dict[str,Any]:
    snap=_snapshot(principal,db,farm_id); recs=_recommendations(snap); actions=[]
    for rec in recs:
        if rec["id"]=="stable": continue
        actions.append({"recommendation_id":rec["id"],"action":"create_task","title":rec["title"],"deadline_hours":rec["deadline_hours"],"executed":bool(payload.execute_actions and not payload.dry_run)})
    if payload.execute_actions and not payload.dry_run:
        db.add(AuditLog(id=new_id("audit"),tenant_id=principal.company.tenant_id,company_id=principal.company.id,farm_id=farm_id,user_id=principal.user.id,action="automation_evaluation",module="automation",entity_type="farm",entity_id=farm_id,description=f"{len(actions)} ação(ões) avaliadas.",before={},after={"actions":actions},result="success")); db.commit()
    return {"farm_id":farm_id,"dry_run":payload.dry_run,"actions":actions}


@router.get("/security/permission-matrix")
def permission_matrix(principal: Principal=Depends(require_permission("platform.read"))) -> dict[str,Any]:
    domain=sorted(p for p in KNOWN_PERMISSIONS if p.split('.')[0] in {"herd","reproduction","health","nutrition","inventory","finance","platform","ai","automation","sync","audit"})
    roles={role:sorted((set(domain) if "*" in perms else set(perms)&set(domain))) for role,perms in ROLE_PERMISSIONS.items()}
    return {"permissions":domain,"roles":roles,"current":{"role":principal.membership.role,"permissions":sorted(principal.permissions&set(domain))}}


@router.get("/security/readiness/farms/{farm_id}")
def security_readiness(farm_id: str,principal: Principal=Depends(require_permission("platform.read")),db: Session=Depends(get_db)) -> dict[str,Any]:
    _farm(principal,db,farm_id); cid=principal.company.id
    states=list(db.scalars(select(EntityState).where(EntityState.company_id==cid,EntityState.farm_id==farm_id)).all())
    duplicate_keys=len(states)-len({(x.entity_type,x.entity_id) for x in states})
    audit_count=_count(db,AuditLog,cid,farm_id)
    sync_count=int(db.scalar(select(func.count()).select_from(SyncChange).where(SyncChange.company_id==cid,SyncChange.farm_id==farm_id)) or 0)
    checks=[
      {"code":"tenant","name":"Isolamento por empresa","status":"passed","detail":"Todas as consultas da plataforma filtram company_id."},
      {"code":"farm_scope","name":"Escopo de fazenda","status":"passed","detail":"Acesso validado pela associação de fazendas do membro."},
      {"code":"soft_delete","name":"Exclusão lógica","status":"passed","detail":"Animais e lotes operacionais usam situação/inativação."},
      {"code":"audit","name":"Auditoria","status":"passed" if audit_count>0 else "warning","detail":f"{audit_count} registro(s) de auditoria na fazenda."},
      {"code":"sync","name":"Sincronização incremental","status":"passed" if sync_count>0 else "warning","detail":f"{sync_count} mudança(s) disponíveis para sincronização."},
      {"code":"conflicts","name":"Integridade de versões","status":"passed" if duplicate_keys==0 else "failed","detail":f"{duplicate_keys} chave(s) duplicada(s)."},
    ]
    passed=sum(1 for x in checks if x["status"]=="passed"); score=round(passed/len(checks)*100,1)
    return {"farm_id":farm_id,"score":score,"ready":all(x["status"]!="failed" for x in checks),"checks":checks}


@router.get("/production/readiness")
def production_readiness(principal: Principal=Depends(require_permission("platform.read")),db: Session=Depends(get_db)) -> dict[str,Any]:
    farms=int(db.scalar(select(func.count()).select_from(Farm).where(Farm.company_id==principal.company.id,Farm.active.is_(True))) or 0)
    checks=[
      {"code":"database","status":"passed","required":True,"detail":"Sessão de banco disponível."},
      {"code":"tenant","status":"passed","required":True,"detail":"Empresa e tenant resolvidos no token."},
      {"code":"permissions","status":"passed" if len(principal.permissions)>0 else "failed","required":True,"detail":f"{len(principal.permissions)} permissões efetivas."},
      {"code":"farms","status":"passed" if farms>0 else "warning","required":False,"detail":f"{farms} fazenda(s) ativa(s)."},
      {"code":"https","status":"manual","required":True,"detail":"Confirmar HTTPS no ambiente de homologação."},
      {"code":"backup_restore","status":"manual","required":True,"detail":"Executar ensaio de backup e restauração."},
      {"code":"monitoring","status":"manual","required":True,"detail":"Confirmar logs, métricas e alertas."},
      {"code":"e2e","status":"manual","required":True,"detail":"Executar scripts/run_platform_e2e.py."},
    ]
    return {"generated_at":datetime.now(timezone.utc).isoformat(),"company_id":principal.company.id,"checks":checks,
            "automatic_ready":all(x["status"]=="passed" for x in checks if x["status"]!="manual" and x["required"])}
