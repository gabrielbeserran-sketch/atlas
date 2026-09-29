from types import SimpleNamespace

import pytest

from app.routers.saas_growth import current_subscription
from app.services.plan_entitlements import evaluate_plan_entitlements


@pytest.mark.parametrize(
    ('code', 'features', 'limits', 'expected'),
    [
        ('basic', ['operacao_basica'], {'monthly_credits': 100, 'data_entries': 100},
         {'monthly_credits_confirmed': 100, 'unlimited_data_confirmed': False,
          'consultancy_confirmed': False, 'team_management_confirmed': False}),
        ('professional', ['indicadores_tecnicos'], {'data_entries': None},
         {'monthly_credits_confirmed': None, 'unlimited_data_confirmed': True,
          'consultancy_confirmed': False, 'team_management_confirmed': False}),
        ('consultancy', ['consultoria', 'gestao_de_equipes'], {'data_entries': None},
         {'monthly_credits_confirmed': None, 'unlimited_data_confirmed': True,
          'consultancy_confirmed': True, 'team_management_confirmed': True}),
    ],
)
def test_active_catalog_entitlements(code, features, limits, expected):
    result = evaluate_plan_entitlements(
        code=code, status='active', subscription_present=True,
        features=features, limits=limits,
    )
    assert result['state'] == 'active'
    assert result['legacy_access_preserved'] is False
    assert result['enforcement_enabled'] is False
    assert result['enforcement_scope'] == 'none'
    assert {key: result[key] for key in expected} == expected


@pytest.mark.parametrize(
    ('code', 'status', 'subscription_present', 'state'),
    [
        ('consultancy', 'not_configured', False, 'legacy_pending'),
        ('consultancy', 'trial', True, 'inactive'),
        ('consultancy', 'cancelled', True, 'inactive'),
        ('custom', 'active', True, 'unknown_plan'),
    ],
)
def test_unconfirmed_entitlements_do_not_create_rights(
    code, status, subscription_present, state,
):
    result = evaluate_plan_entitlements(
        code=code, status=status, subscription_present=subscription_present,
        features=['consultoria', 'gestao_de_equipes'], limits={'data_entries': None},
    )
    assert result['state'] == state
    assert result['legacy_access_preserved'] is not subscription_present
    assert result['enforcement_enabled'] is False
    assert result['consultancy_confirmed'] is False
    assert result['team_management_confirmed'] is False
    assert result['unlimited_data_confirmed'] is False


def test_malformed_basic_credit_does_not_become_confirmed():
    for value in (True, -1, '100', None):
        result = evaluate_plan_entitlements(
            code='basic', status='active', subscription_present=True,
            features=[], limits={'monthly_credits': value},
        )
        assert result['monthly_credits_confirmed'] is None


def test_current_subscription_keeps_old_fields_and_adds_legacy_contract():
    principal = SimpleNamespace(company=SimpleNamespace(id='company-1', subscription_plan='consultancy'))
    db = SimpleNamespace(scalar=lambda _query: None)
    result = current_subscription(db=db, p=principal)
    assert result['code'] == 'consultancy'
    assert result['status'] == 'not_configured'
    assert result['consultancy_included'] is True  # Contrato legado ainda não mudou.
    assert result['authorization']['state'] == 'legacy_pending'
    assert result['authorization']['legacy_access_preserved'] is True
    assert result['authorization']['consultancy_confirmed'] is False


def test_current_subscription_active_row_confirms_matching_plan_only():
    subscription = SimpleNamespace(plan_id='plan-1', status='active')
    plan = SimpleNamespace(
        code='consultancy', name='Atlas Consultoria',
        features_json=['consultoria', 'gestao_de_equipes'],
        limits_json={'data_entries': None},
    )
    db = SimpleNamespace(scalar=lambda _query: subscription, get=lambda _model, _id: plan)
    principal = SimpleNamespace(company=SimpleNamespace(id='company-1', subscription_plan='basic'))
    result = current_subscription(db=db, p=principal)
    assert result['code'] == 'consultancy'
    assert result['authorization']['state'] == 'active'
    assert result['authorization']['consultancy_confirmed'] is True
    assert result['authorization']['team_management_confirmed'] is True


def test_subscription_with_missing_plan_never_confirms_fallback_code():
    subscription = SimpleNamespace(plan_id='missing-plan', status='active')
    db = SimpleNamespace(scalar=lambda _query: subscription, get=lambda _model, _id: None)
    principal = SimpleNamespace(company=SimpleNamespace(id='company-1', subscription_plan='consultancy'))
    result = current_subscription(db=db, p=principal)
    assert result['code'] == 'consultancy'  # Campo de exibição legado, preservado.
    assert result['authorization']['state'] == 'unknown_plan'
    assert result['authorization']['legacy_access_preserved'] is False
    assert result['authorization']['consultancy_confirmed'] is False


def test_display_catalog_does_not_confirm_missing_subscription_features():
    subscription = SimpleNamespace(plan_id='plan-1', status='active')
    plan = SimpleNamespace(
        code='consultancy', name='Atlas Consultoria',
        features_json=[], limits_json={},
    )
    db = SimpleNamespace(scalar=lambda _query: subscription, get=lambda _model, _id: plan)
    principal = SimpleNamespace(company=SimpleNamespace(id='company-1', subscription_plan='basic'))
    result = current_subscription(db=db, p=principal)
    assert 'consultoria' in result['features']  # Exibição legada permanece intacta.
    assert result['authorization']['consultancy_confirmed'] is False
    assert result['authorization']['unlimited_data_confirmed'] is False
