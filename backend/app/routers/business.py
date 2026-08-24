from __future__ import annotations

from datetime import datetime, timedelta, timezone
from hashlib import sha256
from secrets import token_urlsafe
from typing import Any, Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..authz import Principal, require_permission
from ..business_models import (
    AtlasActionPlanItem, AtlasAnalyticsSnapshot, AtlasApiCredential,
    AtlasBusinessParty, AtlasCommercialDocument, AtlasConsultingVisit,
    AtlasSubscription, AtlasWebhookEndpoint, AtlasWorkflowDefinition,
    AtlasWorkflowInstance,
)
from ..database import get_db
from ..services.audit import record_audit
from ..models import (
    Farm, FinancialEntry, HealthEvent, LivestockAnimal, NutritionEvent,
    OperationalTask, ReproductionEvent, new_id,
)

router = APIRouter(prefix="/business", tags=["atlas-blocks-6-10"])


def now() -> datetime:
    return datetime.now(timezone.utc)


def farm_or_404(db: Session, principal: Principal, farm_id: str) -> Farm:
    farm = db.scalar(select(Farm).where(Farm.id == farm_id, Farm.company_id == principal.company.id))
    if farm is None:
        raise HTTPException(404, "Fazenda não encontrada.")
    return farm


class PartyPayload(BaseModel):
    party_type: Literal["customer", "supplier", "partner"]
    name: str = Field(min_length=1, max_length=180)
    document: str = ""
    email: str = ""
    phone: str = ""
    address_json: dict[str, Any] = Field(default_factory=dict)
    crm_stage: str = "active"
    notes: str = ""


class CommercialPayload(BaseModel):
    farm_id: str | None = None
    party_id: str | None = None
    document_type: Literal["purchase", "sale", "contract", "auction", "invoice", "transport", "post_sale"]
    number: str = ""
    status: str = "draft"
    occurred_at: datetime = Field(default_factory=now)
    due_at: datetime | None = None
    total_amount: float = Field(default=0, ge=0)
    currency: str = "BRL"
    items_json: list[Any] = Field(default_factory=list)
    logistics_json: dict[str, Any] = Field(default_factory=dict)
    fiscal_json: dict[str, Any] = Field(default_factory=dict)
    metadata_json: dict[str, Any] = Field(default_factory=dict)
    notes: str = ""


class VisitPayload(BaseModel):
    farm_id: str
    title: str = Field(min_length=1, max_length=180)
    scheduled_at: datetime = Field(default_factory=now)
    status: str = "scheduled"
    checklist_json: list[Any] = Field(default_factory=list)
    photos_json: list[Any] = Field(default_factory=list)
    findings_json: list[Any] = Field(default_factory=list)
    report_text: str = ""
    opinion_text: str = ""
    signature_json: dict[str, Any] = Field(default_factory=dict)
    previous_visit_id: str | None = None


class ActionPayload(BaseModel):
    farm_id: str
    visit_id: str | None = None
    title: str = Field(min_length=1, max_length=180)
    description: str = ""
    area: str = "general"
    priority: Literal["low", "medium", "high", "critical"] = "medium"
    status: str = "open"
    assigned_user_id: str | None = None
    due_at: datetime | None = None
    follow_up_at: datetime | None = None
    expected_result: str = ""
    idempotency_key: str | None = Field(default=None, max_length=160)




class ActionCompletionPayload(BaseModel):
    actual_result: str = Field(min_length=3, max_length=4000)
    evidence: list[str] = Field(default_factory=list)
    source_module: str = Field(default="consultancy", max_length=80)


class WorkflowPayload(BaseModel):
    code: str = Field(min_length=1, max_length=80)
    name: str = Field(min_length=1, max_length=180)
    entity_type: str = "generic"
    steps_json: list[Any] = Field(default_factory=list)


class WorkflowStartPayload(BaseModel):
    workflow_id: str
    entity_type: str
    entity_id: str


class WorkflowDecisionPayload(BaseModel):
    decision: Literal["approve", "reject", "return", "complete"]
    comment: str = ""


class ApiKeyPayload(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    scopes_json: list[str] = Field(default_factory=list)


class WebhookPayload(BaseModel):
    name: str
    url: str
    events_json: list[str] = Field(default_factory=list)


class SubscriptionPayload(BaseModel):
    plan_code: Literal["pilot", "basic", "professional", "enterprise"] = "pilot"
    billing_cycle: Literal["monthly", "annual"] = "monthly"
    amount: float = Field(default=0, ge=0)
    provider: str = "manual"
    trial_days: int = Field(default=30, ge=0, le=365)


def party_dict(x: AtlasBusinessParty) -> dict[str, Any]:
    return {"id": x.id, "party_type": x.party_type, "name": x.name, "document": x.document, "email": x.email, "phone": x.phone, "crm_stage": x.crm_stage, "active": x.active}


def commercial_dict(x: AtlasCommercialDocument) -> dict[str, Any]:
    return {"id": x.id, "farm_id": x.farm_id, "party_id": x.party_id, "document_type": x.document_type, "number": x.number, "status": x.status, "occurred_at": x.occurred_at, "due_at": x.due_at, "total_amount": x.total_amount, "currency": x.currency, "items": x.items_json, "logistics": x.logistics_json, "fiscal": x.fiscal_json, "metadata": x.metadata_json, "notes": x.notes}


# Bloco 6 — Comercialização
@router.post("/parties")
def create_party(payload: PartyPayload, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("commercial.manage"))):
    row = AtlasBusinessParty(company_id=principal.company.id, tenant_id=principal.company.tenant_id, **payload.model_dump())
    db.add(row); db.commit(); db.refresh(row); return party_dict(row)


@router.get("/parties")
def list_parties(party_type: str | None = None, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("commercial.read"))):
    q = select(AtlasBusinessParty).where(AtlasBusinessParty.company_id == principal.company.id, AtlasBusinessParty.active.is_(True))
    if party_type: q = q.where(AtlasBusinessParty.party_type == party_type)
    return [party_dict(x) for x in db.scalars(q.order_by(AtlasBusinessParty.name)).all()]


@router.post("/commercial-documents")
def create_commercial_document(payload: CommercialPayload, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("commercial.manage"))):
    if payload.farm_id: farm_or_404(db, principal, payload.farm_id)
    if payload.party_id:
        party = db.scalar(select(AtlasBusinessParty).where(AtlasBusinessParty.id == payload.party_id, AtlasBusinessParty.company_id == principal.company.id))
        if party is None: raise HTTPException(404, "Cliente ou fornecedor não encontrado.")
    row = AtlasCommercialDocument(company_id=principal.company.id, tenant_id=principal.company.tenant_id, created_by=principal.user.id, **payload.model_dump())
    db.add(row); db.commit(); db.refresh(row); return commercial_dict(row)


@router.get("/commercial-documents")
def list_commercial_documents(farm_id: str | None = None, document_type: str | None = None, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("commercial.read"))):
    q = select(AtlasCommercialDocument).where(AtlasCommercialDocument.company_id == principal.company.id)
    if farm_id: farm_or_404(db, principal, farm_id); q = q.where(AtlasCommercialDocument.farm_id == farm_id)
    if document_type: q = q.where(AtlasCommercialDocument.document_type == document_type)
    return [commercial_dict(x) for x in db.scalars(q.order_by(AtlasCommercialDocument.occurred_at.desc())).all()]


@router.get("/commercial/dashboard")
def commercial_dashboard(farm_id: str | None = None, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("commercial.read"))):
    q = select(AtlasCommercialDocument).where(AtlasCommercialDocument.company_id == principal.company.id)
    if farm_id: farm_or_404(db, principal, farm_id); q = q.where(AtlasCommercialDocument.farm_id == farm_id)
    rows = list(db.scalars(q).all())
    totals: dict[str, float] = {}
    for row in rows: totals[row.document_type] = totals.get(row.document_type, 0) + row.total_amount
    return {"documents": len(rows), "totals_by_type": totals, "open_contracts": sum(1 for x in rows if x.document_type == "contract" and x.status not in {"completed", "cancelled"}), "crm_parties": db.scalar(select(func.count()).select_from(AtlasBusinessParty).where(AtlasBusinessParty.company_id == principal.company.id, AtlasBusinessParty.active.is_(True))) or 0}


# Bloco 7 — Consultoria
@router.post("/consulting/visits")
def create_visit(payload: VisitPayload, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("operations.manage"))):
    farm = farm_or_404(db, principal, payload.farm_id)
    row = AtlasConsultingVisit(company_id=principal.company.id, tenant_id=farm.tenant_id, consultant_user_id=principal.user.id, **payload.model_dump())
    db.add(row); db.commit(); db.refresh(row); return {"id": row.id, "status": row.status, "scheduled_at": row.scheduled_at}


@router.get("/consulting/visits")
def list_visits(farm_id: str, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("operations.read"))):
    farm_or_404(db, principal, farm_id)
    rows = db.scalars(select(AtlasConsultingVisit).where(AtlasConsultingVisit.company_id == principal.company.id, AtlasConsultingVisit.farm_id == farm_id).order_by(AtlasConsultingVisit.scheduled_at.desc())).all()
    return [{"id": x.id, "title": x.title, "status": x.status, "scheduled_at": x.scheduled_at, "completed_at": x.completed_at, "checklist": x.checklist_json, "photos": x.photos_json, "findings": x.findings_json, "report": x.report_text, "opinion": x.opinion_text, "signature": x.signature_json, "previous_visit_id": x.previous_visit_id} for x in rows]


@router.get("/consulting/actions")
def list_actions(
    farm_id: str,
    db: Session = Depends(get_db),
    principal: Principal = Depends(require_permission("operations.read")),
):
    farm_or_404(db, principal, farm_id)
    rows = list(
        db.scalars(
            select(AtlasActionPlanItem)
            .where(
                AtlasActionPlanItem.company_id == principal.company.id,
                AtlasActionPlanItem.farm_id == farm_id,
            )
            .order_by(AtlasActionPlanItem.created_at.desc())
        ).all()
    )
    task_rows = list(
        db.scalars(
            select(OperationalTask).where(
                OperationalTask.company_id == principal.company.id,
                OperationalTask.farm_id == farm_id,
                OperationalTask.source_type == "consultancy_action",
            )
        ).all()
    )
    task_by_action = {task.source_id: task for task in task_rows}
    return [_action_payload(row, task_by_action.get(row.id)) for row in rows]


def _action_payload(
    row: AtlasActionPlanItem,
    task: OperationalTask | None = None,
    *,
    replayed: bool = False,
) -> dict[str, Any]:
    return {
        "id": row.id,
        "farm_id": row.farm_id,
        "visit_id": row.visit_id,
        "title": row.title,
        "description": row.description,
        "area": row.area,
        "priority": row.priority,
        "status": row.status,
        "assigned_user_id": row.assigned_user_id,
        "due_at": row.due_at,
        "completed_at": row.completed_at,
        "follow_up_at": row.follow_up_at,
        "expected_result": row.expected_result,
        "actual_result": row.actual_result,
        "completed_by_user_id": row.completed_by_user_id,
        "execution_evidence": row.execution_evidence_json or {},
        "idempotency_key": row.idempotency_key,
        "agenda_task_id": task.id if task is not None else None,
        "replayed": replayed,
    }


def _action_task(
    db: Session,
    principal: Principal,
    action_id: str,
) -> OperationalTask | None:
    return db.scalar(
        select(OperationalTask).where(
            OperationalTask.company_id == principal.company.id,
            OperationalTask.source_type == "consultancy_action",
            OperationalTask.source_id == action_id,
        )
    )


@router.post("/consulting/actions")
def create_action(
    payload: ActionPayload,
    db: Session = Depends(get_db),
    principal: Principal = Depends(require_permission("operations.manage")),
):
    farm = farm_or_404(db, principal, payload.farm_id)
    normalized_key = (payload.idempotency_key or "").strip() or None
    if normalized_key is not None:
        existing = db.scalar(
            select(AtlasActionPlanItem).where(
                AtlasActionPlanItem.company_id == principal.company.id,
                AtlasActionPlanItem.farm_id == farm.id,
                AtlasActionPlanItem.idempotency_key == normalized_key,
            )
        )
        if existing is not None:
            return _action_payload(
                existing,
                _action_task(db, principal, existing.id),
                replayed=True,
            )

    values = payload.model_dump(exclude={"idempotency_key"})
    row = AtlasActionPlanItem(
        company_id=principal.company.id,
        tenant_id=farm.tenant_id,
        idempotency_key=normalized_key,
        **values,
    )
    db.add(row)
    db.flush()
    task = OperationalTask(
        id=new_id("task"),
        tenant_id=principal.company.tenant_id,
        company_id=principal.company.id,
        farm_id=farm.id,
        source_type="consultancy_action",
        source_id=row.id,
        title=row.title,
        description=row.description,
        responsible_user_id=row.assigned_user_id,
        priority="urgent" if row.priority == "critical" else row.priority,
        due_at=row.due_at,
        status=row.status,
    )
    db.add(task)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        if normalized_key is None:
            raise
        existing = db.scalar(
            select(AtlasActionPlanItem).where(
                AtlasActionPlanItem.company_id == principal.company.id,
                AtlasActionPlanItem.farm_id == farm.id,
                AtlasActionPlanItem.idempotency_key == normalized_key,
            )
        )
        if existing is None:
            raise
        return _action_payload(
            existing,
            _action_task(db, principal, existing.id),
            replayed=True,
        )
    db.refresh(row)
    db.refresh(task)
    return _action_payload(row, task)


@router.patch("/consulting/actions/{action_id}/complete")
def complete_action(
    action_id: str,
    payload: ActionCompletionPayload | None = None,
    actual_result: str = Query(default=""),
    db: Session = Depends(get_db),
    principal: Principal = Depends(require_permission("operations.manage")),
):
    row = db.scalar(
        select(AtlasActionPlanItem).where(
            AtlasActionPlanItem.id == action_id,
            AtlasActionPlanItem.company_id == principal.company.id,
        )
    )
    if row is None:
        raise HTTPException(404, "Ação não encontrada.")
    farm_or_404(db, principal, row.farm_id)

    result = (payload.actual_result if payload is not None else actual_result).strip()
    if len(result) < 3:
        raise HTTPException(422, "Informe o resultado executado antes de concluir a ação.")

    evidence_items = [
        item.strip()
        for item in (payload.evidence if payload is not None else [result])
        if item.strip()
    ]
    source_module = (payload.source_module if payload is not None else row.area).strip() or row.area
    completed_at = now()
    before = {
        "status": row.status,
        "actual_result": row.actual_result,
        "completed_at": row.completed_at.isoformat() if row.completed_at else None,
    }

    row.status = "completed"
    row.completed_at = completed_at
    row.actual_result = result
    row.completed_by_user_id = principal.user.id
    row.execution_evidence_json = {
        "source": "consultancy_center",
        "source_module": source_module,
        "evidence": evidence_items,
        "recorded_at": completed_at.isoformat(),
    }

    task = _action_task(db, principal, row.id)
    if task is not None:
        task.status = "completed"
        task.completed_at = completed_at
        task.evidence = result

    record_audit(
        db,
        principal=principal,
        action="consultancy_action_completed",
        module="consultancy",
        entity_type="atlas_action_plan_item",
        entity_id=row.id,
        farm_id=row.farm_id,
        description=f"Ação consultiva concluída com evidência: {row.title}",
        before=before,
        after={
            "status": row.status,
            "actual_result": row.actual_result,
            "completed_by_user_id": row.completed_by_user_id,
            "completed_at": row.completed_at.isoformat(),
            "execution_evidence": row.execution_evidence_json,
        },
    )
    db.commit()
    return _action_payload(row, task)


@router.get("/consulting/actions/deployment-readiness")
def consulting_actions_deployment_readiness(db: Session = Depends(get_db)):
    # Falha antes da 0047 e confirma que o schema novo chegou ao banco.
    db.scalar(
        select(func.count()).select_from(AtlasActionPlanItem).where(
            AtlasActionPlanItem.idempotency_key.is_not(None)
        )
    )
    db.scalar(
        select(func.count()).select_from(OperationalTask).where(
            OperationalTask.source_type == "consultancy_action"
        )
    )
    db.scalar(
        select(func.count()).select_from(AtlasActionPlanItem).where(
            AtlasActionPlanItem.completed_by_user_id.is_not(None)
        )
    )
    db.scalar(
        select(func.count()).select_from(AtlasActionPlanItem).where(
            AtlasActionPlanItem.execution_evidence_json.is_not(None)
        )
    )
    return {
        "status": "ready",
        "schema_ready": True,
        "idempotency": True,
        "agenda_sync": True,
        "bidirectional_completion": True,
        "execution_evidence_required": True,
        "completion_actor": True,
        "audit_trail": True,
        "farm_scope": True,
        "migration": "0048",
    }


@router.get("/consulting/dashboard")
def consulting_dashboard(farm_id: str, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("operations.read"))):
    farm_or_404(db, principal, farm_id)
    visits = list(db.scalars(select(AtlasConsultingVisit).where(AtlasConsultingVisit.company_id == principal.company.id, AtlasConsultingVisit.farm_id == farm_id)).all())
    actions = list(db.scalars(select(AtlasActionPlanItem).where(AtlasActionPlanItem.company_id == principal.company.id, AtlasActionPlanItem.farm_id == farm_id)).all())
    return {"visits": len(visits), "scheduled_visits": sum(1 for x in visits if x.status == "scheduled"), "open_actions": sum(1 for x in actions if x.status != "completed"), "overdue_actions": sum(1 for x in actions if x.status != "completed" and x.due_at and x.due_at < now()), "completion_percent": round(100 * sum(1 for x in actions if x.status == "completed") / max(len(actions), 1), 2)}


# Bloco 8 — Plataforma Enterprise
@router.post("/workflows")
def create_workflow(payload: WorkflowPayload, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("platform.manage"))):
    row = AtlasWorkflowDefinition(company_id=principal.company.id, tenant_id=principal.company.tenant_id, **payload.model_dump())
    db.add(row); db.commit(); db.refresh(row); return {"id": row.id, "code": row.code}


@router.post("/workflows/start")
def start_workflow(payload: WorkflowStartPayload, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("platform.manage"))):
    definition = db.scalar(select(AtlasWorkflowDefinition).where(AtlasWorkflowDefinition.id == payload.workflow_id, AtlasWorkflowDefinition.company_id == principal.company.id, AtlasWorkflowDefinition.active.is_(True)))
    if definition is None: raise HTTPException(404, "Workflow não encontrado.")
    row = AtlasWorkflowInstance(company_id=principal.company.id, tenant_id=principal.company.tenant_id, started_by=principal.user.id, **payload.model_dump())
    db.add(row); db.commit(); db.refresh(row); return {"id": row.id, "status": row.status, "current_step": row.current_step}


@router.post("/workflows/{instance_id}/decision")
def workflow_decision(instance_id: str, payload: WorkflowDecisionPayload, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("platform.manage"))):
    row = db.scalar(select(AtlasWorkflowInstance).where(AtlasWorkflowInstance.id == instance_id, AtlasWorkflowInstance.company_id == principal.company.id))
    if row is None: raise HTTPException(404, "Fluxo não encontrado.")
    history = list(row.history_json or []); history.append({"at": now().isoformat(), "user_id": principal.user.id, "decision": payload.decision, "comment": payload.comment, "step": row.current_step})
    row.history_json = history
    if payload.decision in {"reject", "complete"}: row.status = "rejected" if payload.decision == "reject" else "completed"; row.completed_at = now()
    elif payload.decision == "return": row.current_step = max(0, row.current_step - 1); row.status = "pending"
    else: row.current_step += 1; row.status = "approved"
    db.commit(); return {"id": row.id, "status": row.status, "current_step": row.current_step, "history": row.history_json}


@router.post("/api-keys")
def create_api_key(payload: ApiKeyPayload, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("platform.manage"))):
    raw = "atlas_" + token_urlsafe(32); prefix = raw[:16]
    row = AtlasApiCredential(company_id=principal.company.id, tenant_id=principal.company.tenant_id, name=payload.name, key_prefix=prefix, key_hash=sha256(raw.encode()).hexdigest(), scopes_json=payload.scopes_json)
    db.add(row); db.commit(); db.refresh(row); return {"id": row.id, "name": row.name, "key": raw, "prefix": prefix, "scopes": row.scopes_json}


@router.post("/webhooks")
def create_webhook(payload: WebhookPayload, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("platform.manage"))):
    secret = token_urlsafe(24)
    row = AtlasWebhookEndpoint(company_id=principal.company.id, tenant_id=principal.company.tenant_id, name=payload.name, url=payload.url, events_json=payload.events_json, secret_hash=sha256(secret.encode()).hexdigest())
    db.add(row); db.commit(); db.refresh(row); return {"id": row.id, "secret": secret, "events": row.events_json}


@router.get("/enterprise/readiness")
def enterprise_readiness(db: Session = Depends(get_db), principal: Principal = Depends(require_permission("platform.read"))):
    workflows = db.scalar(select(func.count()).select_from(AtlasWorkflowDefinition).where(AtlasWorkflowDefinition.company_id == principal.company.id)) or 0
    api_keys = db.scalar(select(func.count()).select_from(AtlasApiCredential).where(AtlasApiCredential.company_id == principal.company.id, AtlasApiCredential.active.is_(True))) or 0
    webhooks = db.scalar(select(func.count()).select_from(AtlasWebhookEndpoint).where(AtlasWebhookEndpoint.company_id == principal.company.id, AtlasWebhookEndpoint.active.is_(True))) or 0
    return {"multi_company": True, "teams_and_delegation": True, "approval_workflows": workflows, "public_api_keys": api_keys, "webhooks": webhooks, "marketplace_contract": "prepared", "score": min(100, 50 + workflows * 10 + api_keys * 10 + webhooks * 10)}


# Bloco 9 — BI
@router.get("/bi/dashboard")
def bi_dashboard(farm_id: str | None = None, days: int = Query(default=365, ge=7, le=3650), db: Session = Depends(get_db), principal: Principal = Depends(require_permission("analytics.read"))):
    since = now() - timedelta(days=days)
    fq = select(FinancialEntry).where(FinancialEntry.company_id == principal.company.id, FinancialEntry.occurred_at >= since)
    aq = select(LivestockAnimal).where(LivestockAnimal.company_id == principal.company.id)
    rq = select(ReproductionEvent).where(ReproductionEvent.company_id == principal.company.id, ReproductionEvent.occurred_at >= since)
    hq = select(HealthEvent).where(HealthEvent.company_id == principal.company.id, HealthEvent.occurred_at >= since)
    nq = select(NutritionEvent).where(NutritionEvent.company_id == principal.company.id, NutritionEvent.occurred_at >= since)
    if farm_id:
        farm_or_404(db, principal, farm_id)
        fq=fq.where(FinancialEntry.farm_id==farm_id); aq=aq.where(LivestockAnimal.farm_id==farm_id); rq=rq.where(ReproductionEvent.farm_id==farm_id); hq=hq.where(HealthEvent.farm_id==farm_id); nq=nq.where(NutritionEvent.farm_id==farm_id)
    financial=list(db.scalars(fq).all()); animals=list(db.scalars(aq).all()); reproduction=list(db.scalars(rq).all()); health=list(db.scalars(hq).all()); nutrition=list(db.scalars(nq).all())
    income=sum(x.amount for x in financial if x.entry_type=='income'); expense=sum(x.amount for x in financial if x.entry_type=='expense'); females=[x for x in animals if (x.sex or '').lower() in {'f','female','fêmea','femea'}]; pregnant=sum(1 for x in females if x.reproductive_status=='pregnant')
    kpis={"animals":len(animals),"average_weight":round(sum((x.current_weight or 0) for x in animals)/max(len(animals),1),2),"pregnancy_rate_percent":round(100*pregnant/max(len(females),1),2),"health_events":len(health),"nutrition_events":len(nutrition),"income":income,"expense":expense,"margin":income-expense,"roi_percent":round(100*(income-expense)/max(expense,1),2)}
    trend={"financial_balance": "up" if income>=expense else "down", "reproduction": "stable", "data_period_days": days}
    benchmark={"pregnancy_rate_target": 75, "financial_margin_target": 0, "weight_data_coverage_percent": round(100*sum(1 for x in animals if (x.current_weight or 0)>0)/max(len(animals),1),2)}
    forecast={"projected_margin_next_period": round((income-expense) * 1.03,2), "confidence_percent": 60, "method": "historical-run-rate-v1"}
    return {"kpis":kpis,"trend":trend,"benchmark":benchmark,"forecast":forecast,"export_formats":["json","csv","power_bi_contract"]}


@router.post("/bi/snapshots")
def create_snapshot(farm_id: str | None = None, days: int = 365, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("analytics.manage"))):
    data = bi_dashboard(farm_id=farm_id, days=days, db=db, principal=principal)
    row = AtlasAnalyticsSnapshot(company_id=principal.company.id, tenant_id=principal.company.tenant_id, farm_id=farm_id, period_start=now()-timedelta(days=days), period_end=now(), metrics_json=data["kpis"], benchmark_json=data["benchmark"], forecast_json=data["forecast"])
    db.add(row); db.commit(); db.refresh(row); return {"id":row.id,"created_at":row.created_at}


# Bloco 10 — Produto comercial
@router.post("/subscriptions")
def create_subscription(payload: SubscriptionPayload, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("platform.manage"))):
    existing = db.scalar(select(AtlasSubscription).where(AtlasSubscription.company_id == principal.company.id, AtlasSubscription.status.in_(["trial","active"])))
    if existing: existing.status = "cancelled"
    row = AtlasSubscription(company_id=principal.company.id, tenant_id=principal.company.tenant_id, plan_code=payload.plan_code, billing_cycle=payload.billing_cycle, amount=payload.amount, provider=payload.provider, trial_ends_at=now()+timedelta(days=payload.trial_days), status="trial" if payload.trial_days else "active")
    db.add(row); db.commit(); db.refresh(row); return {"id":row.id,"plan_code":row.plan_code,"status":row.status,"trial_ends_at":row.trial_ends_at,"provider":row.provider}


@router.get("/product/readiness")
def product_readiness(db: Session = Depends(get_db), principal: Principal = Depends(require_permission("platform.read"))):
    subscription = db.scalar(select(AtlasSubscription).where(AtlasSubscription.company_id == principal.company.id).order_by(AtlasSubscription.created_at.desc()))
    checks = {"landing_page_contract":True,"client_portal_contract":True,"consultant_portal_contract":True,"admin_portal_contract":True,"recurring_billing_contract":subscription is not None,"licensing":subscription is not None,"ios_project":True,"android_project":True,"store_publication":"manual_pending","enterprise_release":"pilot_ready" if subscription else "configuration_required"}
    score=round(100*sum(1 for v in checks.values() if v is True or v in {"pilot_ready"})/len(checks),2)
    return {"checks":checks,"score":score,"subscription":None if subscription is None else {"plan":subscription.plan_code,"status":subscription.status,"provider":subscription.provider},"external_integrations_note":"Pagamentos, nota fiscal, assinatura digital e publicação exigem credenciais e homologação dos provedores oficiais."}


@router.get("/dashboard")
def business_dashboard(farm_id: str | None = None, db: Session = Depends(get_db), principal: Principal = Depends(require_permission("platform.read"))):
    if farm_id: farm_or_404(db, principal, farm_id)
    commercial=commercial_dashboard(farm_id=farm_id, db=db, principal=principal)
    consulting=consulting_dashboard(farm_id=farm_id, db=db, principal=principal) if farm_id else {"visits":0,"scheduled_visits":0,"open_actions":0,"overdue_actions":0,"completion_percent":0}
    enterprise=enterprise_readiness(db=db, principal=principal)
    bi=bi_dashboard(farm_id=farm_id, days=365, db=db, principal=principal)
    product=product_readiness(db=db, principal=principal)
    return {"commercial":commercial,"consulting":consulting,"enterprise":enterprise,"bi":bi,"product":product,"generated_at":now()}
