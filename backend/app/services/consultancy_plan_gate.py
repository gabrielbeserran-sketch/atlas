"""Gate opt-in da Consultoria, preservando contas não migradas."""

from fastapi import Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..authz import Principal, get_principal
from ..config import get_settings
from ..database import get_db
from ..saas_growth_models import CompanySubscription, SaaSPlan
from .plan_entitlements import consultancy_gate_decision, evaluate_plan_entitlements


def is_consultancy_action_source(source_type: str | None) -> bool:
    return (source_type or '').strip().lower() == 'consultancy_action'


def consultancy_action_source_clause(column):
    """Reconhece também grafias legadas sem reescrever tarefas existentes."""
    return func.lower(func.trim(column)) == 'consultancy_action'


def enforce_consultancy_plan_access(
    *, principal: Principal, db: Session, enabled: bool,
) -> None:
    if consultancy_plan_blocks_access(principal=principal, db=db, enabled=enabled):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail='O plano ativo não inclui Consultoria.',
        )


def consultancy_plan_blocks_access(
    *, principal: Principal, db: Session, enabled: bool,
) -> bool:
    """Decisão compartilhada pelas rotas dedicadas e pela Agenda genérica."""
    if not enabled:
        return False

    subscription = db.scalar(
        select(CompanySubscription).where(
            CompanySubscription.company_id == principal.company.id,
            CompanySubscription.tenant_id == principal.company.tenant_id,
        )
    )
    plan = db.get(SaaSPlan, subscription.plan_id) if subscription else None
    code = plan.code if plan else principal.company.subscription_plan or 'basic'
    authorization = evaluate_plan_entitlements(
        code=code,
        status=subscription.status if subscription else 'not_configured',
        subscription_present=subscription is not None,
        plan_resolved=plan is not None,
        features=(plan.features_json or []) if plan else [],
        limits=(plan.limits_json or {}) if plan else {},
        enforcement_enabled=True,
    )
    return consultancy_gate_decision(authorization) == 'deny'


def require_consultancy_plan_access(
    principal: Principal = Depends(get_principal),
    db: Session = Depends(get_db),
) -> None:
    """Dependência compartilhada para fluxos exclusivos do módulo Consultoria.

    As permissões específicas de cada rota continuam obrigatórias; esta guarda
    acrescenta a regra comercial somente após ativação controlada da chave.
    """
    enforce_consultancy_plan_access(
        principal=principal,
        db=db,
        enabled=get_settings().atlas_consultancy_plan_gate_enabled,
    )
