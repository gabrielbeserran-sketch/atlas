from types import SimpleNamespace

import pytest
from fastapi import FastAPI, HTTPException
from fastapi.testclient import TestClient

from app.authz import get_principal
from app.database import get_db
from app.models import OperationalTask
from app.routers import operations
from app.saas_growth_models import SaaSPlan
from app.schemas import OperationalTaskCreateRequest, OperationalTaskUpdateRequest


class FakeDb:
    def __init__(self, *, code='basic', task=None):
        self.subscription = SimpleNamespace(plan_id='plan-1', status='active')
        self.plan = SimpleNamespace(code=code, features_json=[], limits_json={})
        self.task = task
        self.subscription_reads = 0
        self.writes = []
        self.queries = []

    def scalar(self, _query):
        self.subscription_reads += 1
        return self.subscription

    def get(self, model, _identifier):
        return self.plan if model is SaaSPlan else self.task

    def scalars(self, query):
        self.queries.append(query)
        return SimpleNamespace(all=lambda: [])

    def add(self, value):
        self.writes.append(value)

    def commit(self):
        self.writes.append('commit')

    def refresh(self, _value):
        pass


def principal():
    return SimpleNamespace(
        company=SimpleNamespace(
            id='company-A', tenant_id='tenant-A', subscription_plan='basic',
        ),
        membership=SimpleNamespace(role='owner', farm_ids=[]),
        user=SimpleNamespace(id='user-A'),
        permissions={'herd.read', 'herd.write'},
    )


def gate(monkeypatch, enabled=True):
    monkeypatch.setattr(
        operations, 'get_settings',
        lambda: SimpleNamespace(atlas_consultancy_plan_gate_enabled=enabled),
    )


def test_consultancy_task_creation_is_denied_before_write(monkeypatch):
    gate(monkeypatch)
    db = FakeDb()
    payload = OperationalTaskCreateRequest(
        farm_id='farm-A', source_type='consultancy_action',
        source_id='action-A', title='Ação consultiva',
    )
    with pytest.raises(HTTPException) as error:
        operations.create_task(payload, principal=principal(), db=db)
    assert error.value.status_code == 403
    assert db.writes == []


@pytest.mark.parametrize('existing_source', ['consultancy_action', ''])
def test_consultancy_task_update_or_relabel_is_denied(monkeypatch, existing_source):
    gate(monkeypatch)
    task = SimpleNamespace(
        id='task-A', company_id='company-A', farm_id='farm-A',
        source_type=existing_source, source_id='action-A',
    )
    db = FakeDb(task=task)
    payload = (
        OperationalTaskUpdateRequest(status='completed', evidence='Resultado medido')
        if existing_source
        else OperationalTaskUpdateRequest(source_type=' consultancy_action ')
    )
    with pytest.raises(HTTPException) as error:
        operations.update_task('task-A', payload, principal=principal(), db=db)
    assert error.value.status_code == 403
    assert db.writes == []
    assert task.source_type == existing_source


def test_basic_plan_filters_consultancy_tasks_without_hiding_agenda(monkeypatch):
    gate(monkeypatch)
    db = FakeDb()
    result = operations.list_tasks(
        farm_id='farm-A', status_filter='open', principal=principal(), db=db,
    )
    assert result == []
    assert len(db.queries) == 1
    params = set(db.queries[0].compile().params.values())
    assert {'company-A', 'farm-A', 'open', 'consultancy_action'} <= params


def test_regular_task_creation_keeps_working_with_gate_on(monkeypatch):
    gate(monkeypatch)
    db = FakeDb()
    payload = OperationalTaskCreateRequest(
        farm_id='farm-A', source_type='manual', title='Conferir cerca',
    )
    task = operations.create_task(payload, principal=principal(), db=db)
    assert isinstance(task, OperationalTask)
    assert task.source_type == 'manual'
    assert db.subscription_reads == 0
    assert 'commit' in db.writes


def test_gate_off_does_not_filter_tasks_or_read_subscription(monkeypatch):
    gate(monkeypatch, enabled=False)
    db = FakeDb()
    operations.list_tasks(
        farm_id='farm-A', status_filter='open', principal=principal(), db=db,
    )
    assert db.subscription_reads == 0
    assert 'consultancy_action' not in db.queries[0].compile().params.values()


def test_legacy_account_keeps_consultancy_task_access_until_migration(monkeypatch):
    gate(monkeypatch)
    db = FakeDb()
    db.subscription = None
    task = operations.create_task(
        OperationalTaskCreateRequest(
            farm_id='farm-A', source_type='consultancy_action',
            source_id='action-A', title='Acompanhar plano',
        ),
        principal=principal(), db=db,
    )
    assert task.source_type == 'consultancy_action'
    operations.list_tasks(
        farm_id='farm-A', status_filter='open', principal=principal(), db=db,
    )
    assert 'consultancy_action' not in db.queries[0].compile().params.values()


def test_http_agenda_keeps_list_but_denies_consultancy_creation(monkeypatch):
    gate(monkeypatch)
    db = FakeDb()
    app = FastAPI()
    app.include_router(operations.router)
    app.dependency_overrides[get_principal] = principal
    app.dependency_overrides[get_db] = lambda: db

    with TestClient(app) as client:
        listed = client.get('/operations/tasks?farm_id=farm-A&status=open')
        created = client.post('/operations/tasks', json={
            'farm_id': 'farm-A', 'source_type': 'consultancy_action',
            'source_id': 'action-A', 'title': 'Ação consultiva',
        })

    assert listed.status_code == 200
    assert listed.json() == []
    assert 'consultancy_action' in db.queries[0].compile().params.values()
    assert created.status_code == 403
    assert db.writes == []
