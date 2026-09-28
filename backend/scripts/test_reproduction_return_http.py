"""HTTP local isolado: executar diretamente, nunca pelo conftest que usa atlas_test.db."""
import os
os.environ["ATLAS_DATABASE_URL"] = "sqlite:///:memory:"

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import unittest
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

from app.authz import get_principal
from app.database import get_db
from app.models import Company, Farm, LivestockAnimal, ReproductionEvent, OperationalTask, User, Membership, RefreshSession
from app.routers import livestock, operations
from app.security import create_access_token


ORIGIN = datetime(2026, 9, 1, tzinfo=timezone.utc)
EXPECTED = datetime(2026, 9, 2, tzinfo=timezone.utc)


class ReturnHttpTests(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:",
            connect_args={"check_same_thread": False}, poolclass=StaticPool)
        for model in (Company, User, Membership, RefreshSession, Farm,
                LivestockAnimal, ReproductionEvent, OperationalTask):
            model.__table__.create(self.engine)
        self.principal = SimpleNamespace(
            user=SimpleNamespace(id="authenticated"),
            company=SimpleNamespace(id="company", tenant_id="tenant"),
            membership=SimpleNamespace(role="owner", farm_ids=["farm"]),
            permissions={"reproduction.read", "reproduction.write", "herd.write"},
        )
        with Session(self.engine) as db:
            db.add_all([
                Company(id="company", tenant_id="tenant", name="Teste local"),
                User(id="authenticated", name="Operador", email="operator@local.invalid",
                    password_hash="unused-in-test"),
                Membership(id="membership", user_id="authenticated", company_id="company",
                    role="owner", farm_ids=["farm"]),
                RefreshSession(id="session", user_id="authenticated", company_id="company",
                    token_hash="local-unique-hash", expires_at=datetime.now(timezone.utc) + timedelta(days=1)),
                Farm(id="farm", tenant_id="tenant", company_id="company", name="Fazenda teste"),
                LivestockAnimal(id="cow", tenant_id="tenant", company_id="company",
                    farm_id="farm", tag="1", name="Matriz"),
                ReproductionEvent(id="event", tenant_id="tenant", company_id="company",
                    farm_id="farm", animal_id="cow", event_type="IATF", event_code="iatf",
                    occurred_at=ORIGIN, expected_date=EXPECTED, created_by="original",
                    metadata_json={"other": 1}, reproductive_status="awaiting_diagnosis"),
                OperationalTask(id="task", tenant_id="tenant", company_id="company",
                    farm_id="farm", source_type="reproduction_event", source_id="event",
                    title="Retorno", due_at=EXPECTED, status="open", evidence=""),
            ])
            db.commit()
        app = FastAPI()
        app.include_router(livestock.router, prefix="/api/v1")
        app.include_router(operations.router, prefix="/api/v1")
        def local_db():
            with Session(self.engine) as db:
                yield db
        app.dependency_overrides[get_db] = local_db
        app.dependency_overrides[get_principal] = lambda: self.principal
        self.client = TestClient(app)
        self.history = "/api/v1/livestock/animals/cow/reproduction"
        self.event = self.history + "/event"
        self.task = "/api/v1/operations/tasks/task"

    def tearDown(self):
        self.client.close()
        self.engine.dispose()

    def audit(self, status="completed", reason=""):
        return {"event_id": "event", "occurred_date": "01/09/2026",
            "expected_date": "02/09/2026", "status": status,
            "responsible": "Operador", "resolved_at": "2026-09-03T00:00:00.000Z",
            "reason": reason}

    def test_history_contract_and_source_patch_persist_to_fresh_session(self):
        history = self.client.get(self.history)
        self.assertEqual(history.status_code, 200)
        self.assertEqual(history.headers.get("x-atlas-reproduction-returns"), "v1")
        self.assertEqual(len(history.json()), 1)
        body = {"metadata_json": {"other": 1, "atlas_return_resolution": self.audit()}}
        saved = self.client.patch(self.event, json=body)
        self.assertEqual(saved.status_code, 200, saved.text)
        self.assertEqual(saved.json()["metadata_json"]["atlas_return_resolution"]["authenticated_user_id"], "authenticated")
        with Session(self.engine) as fresh:
            event = fresh.get(ReproductionEvent, "event")
            task = fresh.get(OperationalTask, "task")
            self.assertEqual(event.metadata_json["atlas_return_resolution"]["status"], "completed")
            self.assertEqual(task.status, "completed")
            self.assertEqual(task.due_at.date(), EXPECTED.date())
            self.assertEqual(event.reproductive_status, "awaiting_diagnosis")
        before = self.client.get(self.history).json()[0]["metadata_json"]
        self.principal.user.id = "second-user"
        retry = self.client.patch(self.event, json=body)
        self.assertEqual(retry.status_code, 200, retry.text)
        self.assertEqual(retry.json()["metadata_json"], before)
        with Session(self.engine) as fresh:
            self.assertEqual(fresh.get(OperationalTask, "task").evidence.count("Resolução do retorno:"), 1)

    def test_conflict_and_permissions_do_not_mutate_event_or_task(self):
        malformed = self.client.patch(self.event, json={"metadata_json": {
            "atlas_return_resolution": self.audit("cancelled")}})
        self.assertEqual(malformed.status_code, 409, malformed.text)
        self.principal.permissions.remove("reproduction.write")
        self.assertEqual(self.client.patch(self.event, json={"metadata_json": {}}).status_code, 403)
        self.assertEqual(self.client.patch(self.task, json={"status": "completed"}).status_code, 403)
        self.principal.permissions.add("reproduction.write")
        self.principal.company.id = "other-company"
        self.assertEqual(self.client.get(self.history).status_code, 404)
        self.assertEqual(self.client.patch(self.task, json={"status": "completed"}).status_code, 404)
        self.principal.company.id = "company"
        with Session(self.engine) as fresh:
            self.assertEqual(fresh.get(OperationalTask, "task").status, "open")
            self.assertEqual(fresh.get(ReproductionEvent, "event").metadata_json, {"other": 1})

    def test_agenda_first_and_reopen_are_consistent_over_http(self):
        completed = self.client.patch(self.task, json={"status": "cancelled", "evidence": "Nova visita"})
        self.assertEqual(completed.status_code, 200, completed.text)
        self.assertEqual(completed.json()["status"], "cancelled")
        history = self.client.get(self.history).json()[0]
        self.assertEqual(history["metadata_json"]["atlas_return_resolution"]["status"], "cancelled")
        self.assertEqual(self.client.patch(self.task, json={"status": "open"}).status_code, 409)
        self.assertEqual(self.client.patch(self.task, json={"due_at": "2026-09-05T00:00:00Z"}).status_code, 409)
        self.assertEqual(self.client.patch(self.event, json={"metadata_json": {"other": 1}}).status_code, 409)
        with Session(self.engine) as fresh:
            self.assertEqual(fresh.get(OperationalTask, "task").status, "cancelled")
            self.assertEqual(fresh.get(ReproductionEvent, "event").expected_date.date(), EXPECTED.date())

    def test_stale_forecast_and_old_manual_closure_are_refused_before_write(self):
        # Outro dispositivo reagendou após a intenção offline: o PATCH não pode forçar a data antiga.
        moved = self.client.patch(self.event, json={"expected_date": "2026-09-06T00:00:00Z"})
        self.assertEqual(moved.status_code, 200, moved.text)
        stale = self.client.patch(self.event, json={"metadata_json": {
            "atlas_return_resolution": self.audit()}})
        self.assertEqual(stale.status_code, 409, stale.text)
        with Session(self.engine) as db:
            self.assertEqual(db.get(ReproductionEvent, "event").expected_date.date().day, 6)
            self.assertEqual(db.get(OperationalTask, "task").status, "open")
            # Tarefa legada fechada manualmente em sentido oposto não pode ser sobrescrita.
            db.get(OperationalTask, "task").status = "cancelled"
            db.get(ReproductionEvent, "event").expected_date = EXPECTED
            db.commit()
        conflicting = self.client.patch(self.event, json={"metadata_json": {
            "atlas_return_resolution": self.audit()}})
        self.assertEqual(conflicting.status_code, 409, conflicting.text)
        with Session(self.engine) as db:
            self.assertNotIn("atlas_return_resolution", db.get(ReproductionEvent, "event").metadata_json)
            self.assertEqual(db.get(OperationalTask, "task").status, "cancelled")

    def test_http_cancellation_requires_reason_and_same_payload_retries(self):
        body = {"metadata_json": {"atlas_return_resolution": self.audit("cancelled", "Reagendado")}}
        saved = self.client.patch(self.event, json=body)
        self.assertEqual(saved.status_code, 200, saved.text)
        first = saved.json()["metadata_json"]["atlas_return_resolution"]
        self.principal.user.id = "different-user"
        retry = self.client.patch(self.event, json=body)
        self.assertEqual(retry.status_code, 200, retry.text)
        self.assertEqual(retry.json()["metadata_json"]["atlas_return_resolution"], first)
        with Session(self.engine) as db:
            task = db.get(OperationalTask, "task")
            self.assertEqual(task.status, "cancelled")
            self.assertIsNone(task.completed_at)
            self.assertEqual(task.evidence.count("Resolução do retorno:"), 1)

    def test_cross_user_different_resolution_is_conflict_not_second_patch(self):
        first = self.client.patch(self.event, json={"metadata_json": {
            "atlas_return_resolution": self.audit("completed")}})
        self.assertEqual(first.status_code, 200, first.text)
        self.principal.user.id = "other-user"
        competing = self.client.patch(self.event, json={"metadata_json": {
            "atlas_return_resolution": self.audit("cancelled", "Outra decisão")}})
        self.assertEqual(competing.status_code, 409, competing.text)
        with Session(self.engine) as db:
            audit = db.get(ReproductionEvent, "event").metadata_json["atlas_return_resolution"]
            self.assertEqual(audit["status"], "completed")
            self.assertEqual(audit["authenticated_user_id"], "authenticated")
            self.assertEqual(db.get(OperationalTask, "task").status, "completed")

    def test_real_bearer_session_permissions_and_revocation(self):
        # Este caso usa o middleware/dependência real; apenas get_db aponta para memória.
        self.client.app.dependency_overrides.pop(get_principal)
        self.assertIn(self.client.get(self.history).status_code, {401, 403})
        token = create_access_token(user_id="authenticated", company_id="company",
            tenant_id="tenant", role="owner", extra={"session_id": "session"})
        self.client.headers["Authorization"] = f"Bearer {token}"
        history = self.client.get(self.history)
        self.assertEqual(history.status_code, 200, history.text)
        self.assertEqual(history.headers.get("x-atlas-reproduction-returns"), "v1")
        with Session(self.engine) as db:
            db.get(Membership, "membership").permission_overrides = {"reproduction.write": "deny"}
            db.commit()
        self.assertEqual(self.client.patch(self.event, json={"metadata_json": {}}).status_code, 403)
        self.assertEqual(self.client.patch(self.task, json={"status": "completed"}).status_code, 403)
        with Session(self.engine) as db:
            db.get(Membership, "membership").permission_overrides = {}
            db.get(RefreshSession, "session").revoked_at = datetime.now(timezone.utc)
            db.commit()
        self.assertEqual(self.client.get(self.history).status_code, 401)

    def test_real_bearer_tenant_mismatch_and_expired_session(self):
        self.client.app.dependency_overrides.pop(get_principal)
        wrong = create_access_token(user_id="authenticated", company_id="company",
            tenant_id="other-tenant", role="owner", extra={"session_id": "session"})
        self.client.headers["Authorization"] = f"Bearer {wrong}"
        self.assertEqual(self.client.get(self.history).status_code, 403)
        correct = create_access_token(user_id="authenticated", company_id="company",
            tenant_id="tenant", role="owner", extra={"session_id": "session"})
        self.client.headers["Authorization"] = f"Bearer {correct}"
        with Session(self.engine) as db:
            db.get(RefreshSession, "session").expires_at = datetime.now(timezone.utc) - timedelta(seconds=1)
            db.commit()
        self.assertEqual(self.client.get(self.history).status_code, 401)


if __name__ == "__main__":
    unittest.main(verbosity=2)
