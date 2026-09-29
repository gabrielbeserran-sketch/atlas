"""Descreve direitos comprovados, sem aplicar bloqueios às rotas existentes.

Contas legadas continuam com o acesso atual até migração individual. Um plano
exibido no catálogo, por si só, não comprova uma assinatura ativa.
"""

from collections.abc import Iterable, Mapping
from typing import Any


KNOWN_PLANS = frozenset({'basic', 'professional', 'consultancy'})


def evaluate_plan_entitlements(
    *,
    code: str,
    status: str,
    subscription_present: bool,
    features: Iterable[str],
    limits: Mapping[str, Any],
    plan_resolved: bool = True,
    enforcement_enabled: bool = False,
) -> dict[str, Any]:
    """Retorna apenas direitos confirmados; não altera permissões legadas."""
    normalized_code = code.strip().lower()
    normalized_status = status.strip().lower()
    if not subscription_present:
        state = 'legacy_pending'
    elif not plan_resolved or normalized_code not in KNOWN_PLANS:
        state = 'unknown_plan'
    elif normalized_status != 'active':
        state = 'inactive'
    else:
        state = 'active'

    confirmed = state == 'active'
    feature_set = set(features)
    monthly_credits = limits.get('monthly_credits')
    basic_credits = (
        monthly_credits
        if confirmed
        and normalized_code == 'basic'
        and type(monthly_credits) is int
        and monthly_credits >= 0
        else None
    )
    return {
        'code': normalized_code,
        'state': state,
        'legacy_access_preserved': not subscription_present,
        'enforcement_enabled': enforcement_enabled,
        'enforcement_scope': 'consultancy_contact' if enforcement_enabled else 'none',
        'consultancy_confirmed': (
            confirmed and normalized_code == 'consultancy' and 'consultoria' in feature_set
        ),
        'team_management_confirmed': (
            confirmed and normalized_code == 'consultancy' and 'gestao_de_equipes' in feature_set
        ),
        'unlimited_data_confirmed': (
            confirmed
            and normalized_code in {'professional', 'consultancy'}
            and 'data_entries' in limits
            and limits['data_entries'] is None
        ),
        'monthly_credits_confirmed': basic_credits,
    }


def consultancy_gate_decision(authorization: Mapping[str, Any]) -> str:
    """Nega apenas plano não Consultoria ativo; os demais exigem revisão humana.

    ``defer`` preserva o acesso atual enquanto contas antigas/inconclusivas são
    migradas. O papel e o escopo da fazenda continuam verificados pela rota.
    """
    if authorization['state'] == 'legacy_pending':
        return 'defer'
    if authorization['state'] != 'active':
        return 'defer'
    if authorization['consultancy_confirmed']:
        return 'allow'
    if authorization['code'] in {'basic', 'professional'}:
        return 'deny'
    return 'defer'
