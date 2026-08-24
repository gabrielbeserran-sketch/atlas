from __future__ import annotations
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session
from ..authz import Principal, require_farm_scope, require_permission
from ..database import get_db
from ..models import ConsultancyContact, Farm, HerdLot, LivestockAnimal, OperationalTask
from ..saas_growth_models import SaaSPlan,CompanySubscription,BillingInvoice,FeatureFlag,CommunicationTemplate,CommunicationDelivery,OnboardingProgress,DataImportJob,DataExportJob,AdminAuditAction

router=APIRouter(prefix='/saas-growth',tags=['SaaS Growth'])
def read_dep(p=Depends(require_permission('platform.read'))): return p
def manage_dep(p=Depends(require_permission('platform.manage'))): return p
class Payload(BaseModel):
    code:str=''; name:str=''; status:str=''; amount:float=0; farm_id:str|None=None
    data:dict=Field(default_factory=dict); items:list[dict]=Field(default_factory=list)

def now(): return datetime.now(timezone.utc)

@router.post('/plans')
def create_plan(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if not payload.code: raise HTTPException(422,'code obrigatório.')
    if db.scalar(select(SaaSPlan).where(SaaSPlan.code==payload.code)): raise HTTPException(409,'Plano já existe.')
    row=SaaSPlan(code=payload.code,name=payload.name or payload.code,price_monthly=payload.amount,limits_json=payload.data.get('limits',{}),features_json=payload.data.get('features',[]))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'code':row.code}

@router.post('/subscriptions')
def subscribe(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    plan=db.scalar(select(SaaSPlan).where(SaaSPlan.code==payload.code,SaaSPlan.active.is_(True)))
    if not plan: raise HTTPException(404,'Plano não encontrado.')
    row=db.scalar(select(CompanySubscription).where(CompanySubscription.company_id==p.company.id))
    if row is None:
        row=CompanySubscription(tenant_id=p.company.tenant_id,company_id=p.company.id,plan_id=plan.id)
        db.add(row)
    row.plan_id=plan.id; row.status=payload.status or 'active'; row.cancel_at_period_end=bool(payload.data.get('cancel_at_period_end',False)); row.provider=payload.data.get('provider','manual')
    db.add(AdminAuditAction(actor_id=p.user.id,company_id=p.company.id,action='subscription.updated',details_json={'plan':plan.code,'status':row.status}))
    db.commit(); db.refresh(row); return {'id':row.id,'status':row.status,'plan_code':plan.code}

@router.post('/invoices')
def invoice(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    number=payload.data.get('number') or f"INV-{int(now().timestamp())}-{p.company.id[-6:]}"
    discount=max(0,float(payload.data.get('discount',0))); tax=max(0,float(payload.data.get('tax',0)))
    row=BillingInvoice(tenant_id=p.company.tenant_id,company_id=p.company.id,number=number,status=payload.status or 'open',amount=max(0,payload.amount),discount=discount,tax=tax,currency=payload.data.get('currency','BRL'),due_at=payload.data.get('due_at'),provider_payload_json=payload.data.get('provider_payload',{}))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'number':row.number,'total':max(0,row.amount-row.discount+row.tax)}

@router.post('/feature-flags')
def feature_flag(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if not payload.code: raise HTTPException(422,'code obrigatório.')
    row=FeatureFlag(key=payload.code,description=payload.data.get('description',''),enabled=bool(payload.data.get('enabled',False)),company_id=payload.data.get('global',False) and None or p.company.id,plan_code=payload.data.get('plan_code'),rollout_percent=max(0,min(100,int(payload.data.get('rollout_percent',100)))))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'key':row.key,'enabled':row.enabled}

@router.get('/feature-flags/effective')
def effective_flags(db:Session=Depends(get_db),p:Principal=Depends(read_dep)):
    rows=db.scalars(select(FeatureFlag).where((FeatureFlag.company_id.is_(None))|(FeatureFlag.company_id==p.company.id))).all()
    return {'flags':{r.key:r.enabled for r in rows}}

@router.post('/communications/templates')
def communication_template(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    row=CommunicationTemplate(tenant_id=p.company.tenant_id,company_id=p.company.id,channel=payload.data.get('channel','email'),code=payload.code or payload.name,subject=payload.data.get('subject',''),body=payload.data.get('body',''))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'code':row.code}

@router.post('/communications/deliveries')
def communication_delivery(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    recipient=payload.data.get('recipient','')
    if not recipient: raise HTTPException(422,'recipient obrigatório.')
    row=CommunicationDelivery(tenant_id=p.company.tenant_id,company_id=p.company.id,template_id=payload.data.get('template_id'),channel=payload.data.get('channel','email'),recipient=recipient,status='queued',payload_json=payload.data)
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status}

ONBOARDING_AUTOMATIC_STEPS = {
    'farm_context',
    'herd_baseline',
    'technical_contact',
    'agenda_routine',
}
ONBOARDING_MANUAL_STEPS = {'initial_training'}
ONBOARDING_CANONICAL_STEPS = ONBOARDING_AUTOMATIC_STEPS | ONBOARDING_MANUAL_STEPS


def _digits(value: str) -> str:
    return ''.join(ch for ch in value if ch.isdigit())


def _onboarding_farm(db: Session, principal: Principal, farm_id: str) -> Farm:
    require_farm_scope(principal, farm_id)
    farm = db.get(Farm, farm_id)
    if farm is None or farm.company_id != principal.company.id or not farm.active:
        raise HTTPException(404, 'Fazenda não encontrada.')
    return farm


def _onboarding_row(
    db: Session,
    principal: Principal,
    farm_id: str,
    *,
    claim_legacy: bool = False,
) -> OnboardingProgress | None:
    row = db.scalar(
        select(OnboardingProgress).where(
            OnboardingProgress.company_id == principal.company.id,
            OnboardingProgress.farm_id == farm_id,
        )
    )
    if row is not None:
        return row

    legacy = db.scalar(
        select(OnboardingProgress).where(
            OnboardingProgress.company_id == principal.company.id,
            OnboardingProgress.farm_id.is_(None),
        )
    )
    if legacy is not None and claim_legacy:
        legacy.farm_id = farm_id
        db.add(legacy)
    return legacy


def _onboarding_evidence(
    db: Session,
    principal: Principal,
    farm: Farm,
    row: OnboardingProgress | None,
) -> tuple[dict[str, bool], dict[str, dict]]:
    company_id = principal.company.id
    farm_id = farm.id

    farm_context = bool(
        farm.name.strip()
        and (farm.area or 0) > 0
        and (farm.city.strip() or farm.state.strip())
    )
    animal_count = db.scalar(
        select(func.count(LivestockAnimal.id)).where(
            LivestockAnimal.company_id == company_id,
            LivestockAnimal.farm_id == farm_id,
            LivestockAnimal.status == 'active',
        )
    ) or 0
    lot_count = db.scalar(
        select(func.count(HerdLot.id)).where(
            HerdLot.company_id == company_id,
            HerdLot.farm_id == farm_id,
            HerdLot.status == 'active',
        )
    ) or 0
    herd_baseline = animal_count > 0 and lot_count > 0

    contact = db.scalar(
        select(ConsultancyContact).where(
            ConsultancyContact.company_id == company_id,
            ConsultancyContact.farm_id == farm_id,
        )
    )
    contact_digits = _digits(contact.whatsapp_number) if contact else ''
    technical_contact = bool(
        contact
        and contact.active
        and contact.display_name.strip()
        and 10 <= len(contact_digits) <= 15
    )

    task_count = db.scalar(
        select(func.count(OperationalTask.id)).where(
            OperationalTask.company_id == company_id,
            OperationalTask.farm_id == farm_id,
        )
    ) or 0
    agenda_routine = task_count > 0

    persisted = dict(row.steps_json or {}) if row else {}
    initial_training = persisted.get('initial_training') is True

    steps = {
        'farm_context': farm_context,
        'herd_baseline': herd_baseline,
        'technical_contact': technical_contact,
        'agenda_routine': agenda_routine,
        'initial_training': initial_training,
    }
    evidence = {
        'farm_context': {
            'automatic': True,
            'verified': farm_context,
            'detail': 'Nome, localização e área da fazenda confirmados.' if farm_context
            else 'Complete nome, localização e área da fazenda.',
        },
        'herd_baseline': {
            'automatic': True,
            'verified': herd_baseline,
            'detail': f'{animal_count} animais ativos • {lot_count} lotes ativos',
        },
        'technical_contact': {
            'automatic': True,
            'verified': technical_contact,
            'detail': 'Contato veterinário oficial configurado.' if technical_contact
            else 'Configure o veterinário responsável desta fazenda.',
        },
        'agenda_routine': {
            'automatic': True,
            'verified': agenda_routine,
            'detail': f'{task_count} tarefas registradas na agenda da fazenda',
        },
        'initial_training': {
            'automatic': False,
            'verified': initial_training,
            'detail': 'Confirmação manual da equipe responsável.',
        },
    }
    return steps, evidence


def _onboarding_payload(
    row: OnboardingProgress | None,
    *,
    farm_id: str,
    steps: dict[str, bool],
    evidence: dict[str, dict],
) -> dict:
    percent = (sum(1 for value in steps.values() if value) / len(steps) * 100) if steps else 0.0
    completed_at = row.completed_at if row else None
    return {
        'id': row.id if row else None,
        'farm_id': farm_id,
        'steps': steps,
        'evidence': evidence,
        'completion_percent': percent,
        'completed_at': completed_at.isoformat() if completed_at and percent == 100 else None,
    }


@router.get('/onboarding')
def get_onboarding(
    farm_id: str = Query(min_length=1),
    db: Session = Depends(get_db),
    p: Principal = Depends(require_permission('farms.read')),
):
    farm = _onboarding_farm(db, p, farm_id)
    row = _onboarding_row(db, p, farm.id)
    steps, evidence = _onboarding_evidence(db, p, farm, row)
    return _onboarding_payload(row, farm_id=farm.id, steps=steps, evidence=evidence)


@router.post('/onboarding')
def onboarding(
    payload: Payload,
    farm_id: str = Query(min_length=1),
    db: Session = Depends(get_db),
    p: Principal = Depends(require_permission('farms.update')),
):
    farm = _onboarding_farm(db, p, farm_id)
    requested_steps = payload.data.get('steps', {})
    requested_ids = set(requested_steps)
    unknown = requested_ids - ONBOARDING_CANONICAL_STEPS
    if unknown:
        raise HTTPException(422, f'Passos de implantação inválidos: {sorted(unknown)}')
    forbidden = requested_ids & ONBOARDING_AUTOMATIC_STEPS
    if forbidden:
        raise HTTPException(422, 'Etapas automáticas são validadas pelos dados oficiais do Atlas.')

    row = _onboarding_row(db, p, farm.id, claim_legacy=True)
    if row is None:
        row = OnboardingProgress(
            tenant_id=p.company.tenant_id,
            company_id=p.company.id,
            farm_id=farm.id,
        )

    persisted = dict(row.steps_json or {})
    if 'initial_training' in requested_steps:
        persisted['initial_training'] = bool(requested_steps['initial_training'])
    row.steps_json = {
        'initial_training': persisted.get('initial_training') is True,
    }

    db.add(row)
    db.flush()
    steps, evidence = _onboarding_evidence(db, p, farm, row)
    # O registro é company-scoped e não deve armazenar percentual derivado de uma
    # fazenda específica. Persistimos apenas o passo realmente manual.
    row.completion_percent = 20.0 if row.steps_json.get('initial_training') is True else 0.0
    row.completed_at = None
    db.commit()
    db.refresh(row)
    return _onboarding_payload(row, farm_id=farm.id, steps=steps, evidence=evidence)


@router.get('/onboarding/deployment-readiness')
def onboarding_deployment_readiness(db: Session = Depends(get_db)):
    db.scalar(select(func.count()).select_from(OnboardingProgress))
    # Esta consulta falha antes da migration 0046 e prova que farm_id existe.
    db.scalar(
        select(func.count()).select_from(OnboardingProgress).where(
            OnboardingProgress.farm_id.is_not(None)
        )
    )
    return {
        'status': 'ready',
        'schema_ready': True,
        'read_api': True,
        'write_api': True,
        'persistent_progress': True,
        'farm_scoped_evidence': True,
        'farm_scoped_manual_progress': True,
        'legacy_progress_migration': True,
        'automatic_evidence': True,
        'manual_step_restricted': True,
        'migration': '0046',
    }


@router.post('/imports')
def create_import(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if payload.farm_id: require_farm_scope(p,payload.farm_id)
    uri=payload.data.get('source_uri','')
    if not uri: raise HTTPException(422,'source_uri obrigatório.')
    preview=payload.data.get('preview',[])[:100]
    row=DataImportJob(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=payload.farm_id,entity_type=payload.code or 'animals',source_uri=uri,mapping_json=payload.data.get('mapping',{}),preview_json=preview,status='validated' if preview else 'draft',total_rows=int(payload.data.get('total_rows',len(preview))))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status,'preview_rows':len(preview)}

@router.post('/exports')
def create_export(payload:Payload,db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    if payload.farm_id: require_farm_scope(p,payload.farm_id)
    fmt=payload.data.get('format','csv').lower()
    if fmt not in {'csv','xlsx','pdf','json'}: raise HTTPException(422,'Formato inválido.')
    row=DataExportJob(tenant_id=p.company.tenant_id,company_id=p.company.id,farm_id=payload.farm_id,entity_type=payload.code or 'animals',format=fmt,filters_json=payload.data.get('filters',{}))
    db.add(row); db.commit(); db.refresh(row); return {'id':row.id,'status':row.status,'format':row.format}

@router.get('/client-portal')
def client_portal(db:Session=Depends(get_db),p:Principal=Depends(read_dep)):
    sub=db.scalar(select(CompanySubscription).where(CompanySubscription.company_id==p.company.id))
    invoices=db.scalar(select(func.count()).select_from(BillingInvoice).where(BillingInvoice.company_id==p.company.id)) or 0
    onboarding_percent=db.scalar(
        select(func.avg(OnboardingProgress.completion_percent)).where(
            OnboardingProgress.company_id==p.company.id,
            OnboardingProgress.farm_id.is_not(None),
        )
    ) or 0
    return {'company_id':p.company.id,'subscription_status':sub.status if sub else 'none','invoice_count':invoices,'onboarding_percent':float(onboarding_percent)}

@router.get('/admin/dashboard')
def admin_dashboard(db:Session=Depends(get_db),p:Principal=Depends(manage_dep)):
    count=lambda m: db.scalar(select(func.count()).select_from(m)) or 0
    return {'plans':count(SaaSPlan),'subscriptions':count(CompanySubscription),'invoices':count(BillingInvoice),'feature_flags':count(FeatureFlag),'deliveries':count(CommunicationDelivery),'imports':count(DataImportJob),'exports':count(DataExportJob)}
