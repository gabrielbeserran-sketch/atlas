from types import SimpleNamespace

import pytest
from fastapi import FastAPI, HTTPException
from fastapi.routing import APIRoute
from fastapi.testclient import TestClient

from app.authz import get_principal
from app.database import get_db
from app.routers import business, enterprise_operations, saas_growth
from app.routers.consultancy import (
    ConsultancyContactUpdateRequest,
    get_contact,
    update_contact,
)
from app.services.consultancy_plan_gate import (
    enforce_consultancy_plan_access,
    require_consultancy_plan_access,
)
from app.services.plan_entitlements import consultancy_gate_decision, evaluate_plan_entitlements


class FakeDb:
    def __init__(self, subscription=None, plan=None):
        self.subscription = subscription
        self.plan = plan
        self.queries = []
        self.get_calls = []
        self.writes = []

    def scalar(self, query):
        self.queries.append(query)
        return self.subscription

    def get(self, model, identifier):
        self.get_calls.append((model, identifier))
        return self.plan

    def add(self, value):
        self.writes.append(value)


def principal(company_id='company-A', plan='basic'):
    return SimpleNamespace(
        company=SimpleNamespace(
            id=company_id, tenant_id='tenant-A', subscription_plan=plan,
        ),
        membership=SimpleNamespace(farm_ids=[]),
        user=SimpleNamespace(id='user-A'),
        permissions={'operations.read', 'farms.read'},
    )


def active_db(code, features=None):
    return FakeDb(
        subscription=SimpleNamespace(plan_id='plan-1', status='active'),
        plan=SimpleNamespace(code=code, features_json=features or [], limits_json={}),
    )


def test_gate_disabled_does_not_even_read_subscription():
    db = FakeDb()
    enforce_consultancy_plan_access(principal=principal(), db=db, enabled=False)
    assert db.queries == []
    assert db.get_calls == []


@pytest.mark.parametrize('code', ['basic', 'professional'])
def test_active_non_consultancy_plan_is_denied_when_enabled(code):
    db = active_db(code)
    with pytest.raises(HTTPException) as error:
        enforce_consultancy_plan_access(principal=principal(), db=db, enabled=True)
    assert error.value.status_code == 403
    assert len(db.queries) == 1
    params = db.queries[0].compile().params.values()
    assert 'company-A' in params and 'tenant-A' in params
    assert db.writes == []


def test_active_consultancy_plan_is_allowed_when_enabled():
    db = active_db('consultancy', ['consultoria'])
    enforce_consultancy_plan_access(principal=principal(), db=db, enabled=True)
    assert len(db.queries) == 1


@pytest.mark.parametrize(
    ('subscription', 'plan'),
    [
        (None, None),
        (SimpleNamespace(plan_id='plan-1', status='trial'),
         SimpleNamespace(code='basic', features_json=[], limits_json={})),
        (SimpleNamespace(plan_id='missing', status='active'), None),
        (SimpleNamespace(plan_id='plan-1', status='active'),
         SimpleNamespace(code='custom', features_json=[], limits_json={})),
    ],
)
def test_unmigrated_or_inconclusive_account_keeps_current_access(subscription, plan):
    db = FakeDb(subscription, plan)
    enforce_consultancy_plan_access(principal=principal(plan='consultancy'), db=db, enabled=True)
    assert db.writes == []


def test_active_consultancy_without_feature_is_deferred_not_misreported():
    authorization = evaluate_plan_entitlements(
        code='consultancy', status='active', subscription_present=True,
        features=[], limits={}, enforcement_enabled=True,
    )
    assert authorization['consultancy_confirmed'] is False
    assert authorization['enforcement_scope'] == 'consultancy_routes_and_agenda_tasks'
    assert consultancy_gate_decision(authorization) == 'defer'


def test_get_and_patch_are_guarded_before_farm_read_or_write(monkeypatch):
    from app.routers import consultancy

    monkeypatch.setattr(
        consultancy, 'get_settings',
        lambda: SimpleNamespace(atlas_consultancy_plan_gate_enabled=True),
    )
    db = active_db('basic')
    with pytest.raises(HTTPException) as read_error:
        get_contact(farm_id='farm-A', principal=principal(), db=db)
    assert read_error.value.status_code == 403
    assert len(db.get_calls) == 1  # Somente o plano; fazenda nem foi lida.

    request = ConsultancyContactUpdateRequest(
        display_name='Responsável técnico', whatsapp_number='62999999999',
        company_label='Fazenda A',
    )
    with pytest.raises(HTTPException) as write_error:
        update_contact(request, farm_id='farm-A', principal=principal(), db=db)
    assert write_error.value.status_code == 403
    assert db.writes == []


def test_shared_dependency_obeys_disabled_and_enabled_configuration(monkeypatch):
    from app.services import consultancy_plan_gate

    db = active_db('professional')
    monkeypatch.setattr(
        consultancy_plan_gate, 'get_settings',
        lambda: SimpleNamespace(atlas_consultancy_plan_gate_enabled=False),
    )
    require_consultancy_plan_access(principal=principal(), db=db)
    assert db.queries == []

    monkeypatch.setattr(
        consultancy_plan_gate, 'get_settings',
        lambda: SimpleNamespace(atlas_consultancy_plan_gate_enabled=True),
    )
    with pytest.raises(HTTPException) as error:
        require_consultancy_plan_access(principal=principal(), db=db)
    assert error.value.status_code == 403


def test_every_user_facing_consultancy_route_has_shared_gate():
    expected = {
        ('GET', '/saas-growth/onboarding'),
        ('POST', '/saas-growth/onboarding'),
        ('GET', '/business/consulting/visits'),
        ('POST', '/business/consulting/visits'),
        ('GET', '/business/consulting/actions'),
        ('POST', '/business/consulting/actions'),
        ('PATCH', '/business/consulting/actions/{action_id}/complete'),
        ('POST', '/business/consulting/actions/reconcile-outcomes'),
        ('GET', '/business/consulting/actions/outcomes'),
        ('GET', '/business/consulting/dashboard'),
        ('POST', '/enterprise-operations/consulting/visits'),
    }
    routes = [
        route for router in (
            business.router, enterprise_operations.router, saas_growth.router,
        )
        for route in router.routes if isinstance(route, APIRoute)
    ]
    user_facing = {
        (method, route.path)
        for route in routes
        for method in route.methods or []
        if (route.path.startswith('/business/consulting/')
            or route.path.startswith('/enterprise-operations/consulting/')
            or route.path == '/saas-growth/onboarding')
        and not route.path.endswith('/deployment-readiness')
    }
    assert user_facing == expected
    matched = {
        (method, route.path)
        for route in routes
        for method in route.methods or []
        if (method, route.path) in expected
        and any(
            dependency.dependency is require_consultancy_plan_access
            for dependency in route.dependencies
        )
    }
    assert matched == expected
    for route in routes:
        if route.path.endswith('/deployment-readiness'):
            assert not any(
                dependency.dependency is require_consultancy_plan_access
                for dependency in route.dependencies
            )


@pytest.mark.parametrize(
    ('router', 'path'),
    [
        (business.router, '/business/consulting/actions?farm_id=farm-A'),
        (saas_growth.router, '/saas-growth/onboarding?farm_id=farm-A'),
    ],
)
def test_http_route_rejects_active_basic_before_handler(monkeypatch, router, path):
    from app.services import consultancy_plan_gate

    monkeypatch.setattr(
        consultancy_plan_gate, 'get_settings',
        lambda: SimpleNamespace(atlas_consultancy_plan_gate_enabled=True),
    )
    db = active_db('basic')
    app = FastAPI()
    app.include_router(router)
    app.dependency_overrides[get_principal] = lambda: principal()
    app.dependency_overrides[get_db] = lambda: db

    with TestClient(app) as client:
        response = client.get(path)
    assert response.status_code == 403
    assert response.json()['detail'] == 'O plano ativo não inclui Consultoria.'
    assert db.writes == []
