"""Executar diretamente; não usa tests/conftest.py nem arquivos de banco."""
import os
os.environ["ATLAS_DATABASE_URL"] = "sqlite:///:memory:"
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import unittest
from copy import deepcopy
from datetime import datetime, timezone
from types import SimpleNamespace
from unittest.mock import patch
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from fastapi import HTTPException, Response
from app.models import OperationalTask, ReproductionEvent
from app.routers.operations import update_task
from app.routers.livestock import _sync_operational_task, update_reproduction_event, add_reproduction_event, reproduction_history
from app.schemas.legacy import ReproductionEventUpdateRequest, ReproductionEventCreateRequest, OperationalTaskUpdateRequest
from app.services.reproduction_return_resolution import validate_resolution, apply_resolution_to_task, ensure_task_resolution_compatible, KEY

UTC = timezone.utc
ORIGIN = datetime(2026, 9, 1, tzinfo=UTC)
EXPECTED = datetime(2026, 9, 2, tzinfo=UTC)
NOW = datetime(2026, 9, 27, tzinfo=UTC)

def metadata(status="completed"):
    return {"other": {"keep": 1}, KEY: {"event_id": "event", "occurred_date": "01/09/2026",
        "expected_date": "02/09/2026", "responsible": "Operador declarado", "status": status,
        "resolved_at": "2026-09-03T00:00:00.000Z", "reason": "Replanejado" if status == "cancelled" else ""}}

def validate(value, previous=None, **kwargs):
    return validate_resolution(value, previous, event_id="event", occurred_at=ORIGIN,
        expected_at=EXPECTED, user_id=kwargs.get("user_id", "authenticated"), now=NOW)

class ContractTests(unittest.TestCase):
    def test_unrelated_previous_metadata_survives_resolution_patch(self):
        previous = {"foreign": {"saved": True}}
        result = validate(metadata(), previous)
        self.assertEqual(result["foreign"], {"saved": True})
        self.assertEqual(previous, {"foreign": {"saved": True}})
    def test_authenticated_author_and_metadata_preserved(self):
        value = metadata(); value[KEY]["authenticated_user_id"] = "spoofed"
        original = deepcopy(value)
        result = validate(value)
        self.assertEqual(result[KEY]["authenticated_user_id"], "authenticated")
        self.assertEqual(result["other"], {"keep": 1})
        self.assertEqual(value, original)

    def test_retry_preserves_original_author(self):
        previous = validate(metadata())
        repeated = validate(metadata(), previous, user_id="other-user")
        self.assertEqual(repeated, previous)

    def test_terminal_cannot_be_removed_or_overwritten(self):
        previous = validate(metadata())
        for value in [{}, None, metadata("cancelled")]:
            with self.subTest(value=value), self.assertRaises(ValueError): validate(value, previous)

    def test_binding_required(self):
        for field in ["event_id", "occurred_date", "expected_date"]:
            value = metadata(); value[KEY][field] = "wrong"
            with self.subTest(field=field), self.assertRaises(ValueError): validate(value)

    def test_responsible_reason_and_status(self):
        for status, field, value in [("completed", "responsible", ""),
            ("cancelled", "reason", ""), ("unknown", "status", "unknown")]:
            data = metadata(status); data[KEY][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError): validate(data)

    def test_timestamp_invalid_future_before_origin_or_noncanonical(self):
        for value in ["invalid", "2026-09-03T00:00:00", "2026-09-03T00:00:00+00:00",
            "2026-09-03T00:00:00.000000Z", "2026-09-28T00:00:00.000Z", "2026-08-01T00:00:00.000Z"]:
            data = metadata(); data[KEY]["resolved_at"] = value
            with self.subTest(value=value), self.assertRaises(ValueError): validate(data)

    def test_legacy_without_resolution_is_not_closed(self):
        self.assertEqual(validate({"other": 2}), {"other": 2})
        task = SimpleNamespace(status="open", completed_at=None, evidence="original")
        apply_resolution_to_task(task, {})
        self.assertEqual(task.status, "open")

class TaskTests(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:")
        OperationalTask.__table__.create(self.engine)
        self.principal = SimpleNamespace(company=SimpleNamespace(id="company", tenant_id="tenant"))
    def tearDown(self): self.engine.dispose()
    def sync(self, db, source="event", principal=None):
        return _sync_operational_task(db=db, principal=principal or self.principal,
            farm_id="farm", source_type="reproduction_event", source_id=source,
            title="Retorno", description="Teste", due_at=EXPECTED)

    def test_complete_cancel_retry_and_reopen_read(self):
        for state in ["completed", "cancelled"]:
            with self.subTest(state=state), Session(self.engine) as db:
                source = state
                task = self.sync(db, source)
                audit = validate(metadata(state))
                apply_resolution_to_task(task, audit); db.commit()
                evidence = task.evidence
                self.assertEqual(task.status, state)
                self.assertEqual(task.due_at.date(), EXPECTED.date())
                self.assertEqual(task.completed_at is not None, state == "completed")
                apply_resolution_to_task(self.sync(db, source), audit); db.commit()
                self.assertEqual(task.evidence, evidence)
                self.assertEqual(task.status, state)
                task_id = task.id
            with Session(self.engine) as fresh:
                saved = fresh.get(OperationalTask, task_id)
                self.assertEqual(saved.status, state)
                self.assertIn("authenticated", saved.evidence)

    def test_other_company_source_untouched(self):
        with Session(self.engine) as db:
            other = SimpleNamespace(company=SimpleNamespace(id="other", tenant_id="other"))
            foreign = self.sync(db, principal=other)
            unrelated = self.sync(db, source="unrelated")
            target = self.sync(db)
            apply_resolution_to_task(target, validate(metadata())); db.commit()
            self.assertEqual(foreign.status, "open")
            self.assertEqual(unrelated.status, "open")

    def test_edit_does_not_reopen_legacy_cancelled_return(self):
        with Session(self.engine) as db:
            task = self.sync(db)
            task.status = "cancelled"
            db.commit()
            self.assertEqual(self.sync(db).status, "cancelled")


class AgendaTests(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:")
        ReproductionEvent.__table__.create(self.engine)
        OperationalTask.__table__.create(self.engine)
        self.db = Session(self.engine)
        self.principal = SimpleNamespace(user=SimpleNamespace(id="authenticated"),
            company=SimpleNamespace(id="company"), membership=SimpleNamespace(role="owner"),
            permissions={"herd.write", "reproduction.write"})
        self.event = ReproductionEvent(id="event", tenant_id="tenant", company_id="company",
            farm_id="farm", animal_id="cow", event_type="IATF", event_code="iatf",
            occurred_at=ORIGIN, expected_date=EXPECTED, created_by="original",
            metadata_json={"other": 1}, reproductive_status="awaiting_diagnosis")
        self.task = OperationalTask(id="task", tenant_id="tenant", company_id="company",
            farm_id="farm", source_type="reproduction_event", source_id="event",
            title="Retorno", description="Original", due_at=EXPECTED, status="open", evidence="")
        self.db.add_all([self.event, self.task]); self.db.commit()

    def tearDown(self):
        self.db.close(); self.engine.dispose()

    def update(self, **changes):
        return update_task("task", OperationalTaskUpdateRequest(**changes), self.principal, self.db)

    def test_completion_persists_both_without_changing_clinical_result(self):
        self.update(status="completed", evidence="Visita realizada")
        task_id = self.task.id
        self.db.close(); self.db = Session(self.engine)
        event = self.db.get(ReproductionEvent, "event")
        task = self.db.get(OperationalTask, task_id)
        self.assertEqual(event.metadata_json[KEY]["status"], task.status)
        self.assertEqual(event.metadata_json[KEY]["authenticated_user_id"], "authenticated")
        self.assertEqual(event.metadata_json["other"], 1)
        self.assertEqual(event.reproductive_status, "awaiting_diagnosis")
        self.assertEqual(event.expected_date.date(), EXPECTED.date())
        self.assertEqual(task.completed_at.date(), datetime.now(UTC).date())

    def test_cancel_requires_reason_and_preserves_forecast(self):
        with self.assertRaises(HTTPException) as raised:
            self.update(status="cancelled")
        self.assertEqual(raised.exception.status_code, 409)
        self.assertEqual(self.task.status, "open")
        self.assertNotIn(KEY, self.event.metadata_json)
        self.update(status="cancelled", evidence="Exame reagendado pelo veterinário")
        self.assertEqual(self.event.metadata_json[KEY]["status"], "cancelled")
        self.assertIsNone(self.task.completed_at)
        self.assertEqual(self.task.due_at.date(), EXPECTED.date())

    def test_terminal_protects_state_date_evidence_and_retry_author(self):
        self.update(status="completed")
        original = deepcopy(self.event.metadata_json)
        evidence = self.task.evidence
        self.principal.user.id = "second-user"
        # Banco SQLite retorna datetime sem timezone; eco UTC equivalente é válido.
        self.update(status="completed", due_at=EXPECTED)
        self.assertEqual(self.event.metadata_json, original)
        self.assertEqual(self.task.evidence, evidence)
        for change in [{"status": "open"}, {"status": "cancelled", "evidence": "Outro"},
                {"due_at": None}, {"due_at": NOW}, {"evidence": "Substituir auditoria"}]:
            with self.subTest(change=change), self.assertRaises(HTTPException) as raised:
                self.update(**change)
            self.assertEqual(raised.exception.status_code, 409)
            self.db.rollback()
            self.assertEqual(self.task.status, "completed")
            self.assertEqual(self.event.metadata_json, original)

    def test_identical_retry_preserves_evidence_and_audit(self):
        for state in ["completed", "cancelled"]:
            with self.subTest(state=state):
                # Cada subcaso usa uma transação independente, sem arquivos.
                self.task.status = "open"; self.task.evidence = ""
                self.event.metadata_json = {"other": 1}; self.db.commit()
                self.update(status=state, evidence="Visita realizada")
                audit = deepcopy(self.event.metadata_json)
                evidence = self.task.evidence
                self.update(status=state, evidence="Visita realizada")
                self.assertEqual(self.event.metadata_json, audit)
                self.assertEqual(self.task.evidence, evidence)

    def test_permission_required_to_change_return_not_title(self):
        self.principal.permissions = {"herd.write"}
        for change in [{"status": "completed"}, {"due_at": NOW}, {"evidence": "test"}]:
            with self.assertRaises(HTTPException) as raised:
                self.update(**change)
            self.assertEqual(raised.exception.status_code, 403)
        self.update(title="Título autorizado")
        self.assertNotIn(KEY, self.event.metadata_json)
        self.assertEqual(self.task.title, "Título autorizado")

    def test_open_reschedule_updates_source_without_auto_resolution(self):
        self.update(due_at=NOW)
        self.assertEqual(self.event.expected_date.date(), NOW.date())
        self.assertEqual(self.task.due_at.date(), NOW.date())
        self.assertNotIn(KEY, self.event.metadata_json)
        with self.assertRaises(HTTPException):
            self.update(status="completed", due_at=EXPECTED)
        self.assertEqual(self.task.status, "open")
        with self.assertRaises(HTTPException):
            self.update(due_at=datetime(2026, 8, 1, tzinfo=UTC))
        self.assertEqual(self.event.expected_date.date(), NOW.date())

    def test_missing_or_foreign_source_refused_without_mutation(self):
        self.event.company_id = "foreign"; self.db.commit()
        with self.assertRaises(HTTPException) as raised:
            self.update(status="completed")
        self.assertEqual(raised.exception.status_code, 409)
        self.assertEqual(self.task.status, "open")
        self.task.company_id = "foreign"; self.db.commit()
        with self.assertRaises(HTTPException) as raised:
            self.update(title="Intrusão")
        self.assertEqual(raised.exception.status_code, 404)

    def test_duplicate_cannot_close_source(self):
        duplicate = OperationalTask(id="duplicate", tenant_id="tenant", company_id="company",
            farm_id="farm", source_type="reproduction_event", source_id="event", title="Duplicada",
            created_at=datetime(2030, 1, 1), status="cancelled")
        self.db.add(duplicate); self.db.commit()
        with self.assertRaises(HTTPException) as raised:
            update_task("duplicate", OperationalTaskUpdateRequest(status="completed"), self.principal, self.db)
        self.assertEqual(raised.exception.status_code, 409)
        self.assertNotIn(KEY, self.event.metadata_json)

    def test_legacy_closed_title_edit_does_not_invent_resolution(self):
        self.task.status = "completed"; self.db.commit()
        self.update(title="Conferir retorno antigo")
        self.assertNotIn(KEY, self.event.metadata_json)
        with self.assertRaises(HTTPException):
            self.update(status="cancelled", evidence="Outro motivo")

    def test_unlinked_manual_task_keeps_existing_behavior(self):
        self.task.source_type = "manual"; self.task.source_id = ""; self.db.commit()
        self.principal.permissions = {"herd.write"}
        self.update(status="completed")
        self.assertEqual(self.task.status, "completed")
        self.assertNotIn(KEY, self.event.metadata_json)

    def test_reproduction_refuses_conflicting_legacy_closure(self):
        self.task.status = "cancelled"; self.db.commit()
        with self.assertRaises(ValueError):
            ensure_task_resolution_compatible([self.task], validate(metadata()))
        ensure_task_resolution_compatible([self.task], validate(metadata("cancelled")))
        self.assertEqual(self.task.status, "cancelled")

class RouteTests(unittest.TestCase):
    def test_history_advertises_contract_without_changing_records(self):
        response = Response()
        db = SimpleNamespace(scalars=lambda query: SimpleNamespace(all=lambda: []))
        with patch("app.routers.livestock._animal") as lookup:
            self.assertEqual(reproduction_history("cow", response, None, db), [])
        lookup.assert_called_once_with(db, None, "cow")
        self.assertEqual(response.headers["X-Atlas-Reproduction-Returns"], "v1")

    def test_new_event_cannot_import_terminal_resolution(self):
        with patch("app.routers.livestock._animal") as lookup:
            with self.assertRaises(HTTPException) as raised:
                add_reproduction_event("cow", ReproductionEventCreateRequest(event_type="IATF", metadata_json=metadata()), None, None)
            self.assertEqual(raised.exception.status_code, 409)
            lookup.assert_not_called()

    def test_success_updates_event_and_task_before_commit(self):
        item = SimpleNamespace(id="event", occurred_at=ORIGIN, expected_date=EXPECTED,
            metadata_json={"other": 1}, event_type="Diagnóstico de gestação", event_code="pregnancy_diagnosis", reproductive_status="open",
            result="não prenhe", pregnancy_days=0)
        task = SimpleNamespace(status="open", completed_at=None, evidence="", due_at=EXPECTED)
        commits = []
        db = SimpleNamespace(scalar=lambda query: item, scalars=lambda query: SimpleNamespace(all=lambda: []), flush=lambda: None,
            commit=lambda: commits.append((item.metadata_json[KEY]["status"], task.status)), refresh=lambda item: None)
        principal = SimpleNamespace(user=SimpleNamespace(id="user"), company=SimpleNamespace(id="company"))
        animal = SimpleNamespace(id="cow", farm_id="farm", name="Matriz", tag="1")
        with patch("app.routers.livestock._animal", return_value=animal), patch("app.routers.livestock._refresh_animal_reproduction_state"), patch("app.routers.livestock._sync_operational_task", return_value=task):
            saved = update_reproduction_event("cow", "event", ReproductionEventUpdateRequest(metadata_json=metadata()), principal, db)
        self.assertEqual(commits, [("completed", "completed")])
        self.assertEqual(saved.expected_date, EXPECTED)
        self.assertEqual(saved.metadata_json[KEY]["authenticated_user_id"], "user")
        self.assertEqual(saved.reproductive_status, "open")

    def test_invalid_resolution_rejected_before_mutation(self):
        item = SimpleNamespace(id="event", occurred_at=ORIGIN, expected_date=EXPECTED, metadata_json=validate(metadata()))
        db = SimpleNamespace(scalar=lambda query: item, flush=lambda: self.fail("Não deveria gravar"))
        principal = SimpleNamespace(user=SimpleNamespace(id="user"), company=SimpleNamespace(id="company"))
        with patch("app.routers.livestock._animal", return_value=SimpleNamespace(id="cow")):
            with self.assertRaises(HTTPException) as raised:
                update_reproduction_event("cow", "event", ReproductionEventUpdateRequest(metadata_json={}), principal, db)
        self.assertEqual(raised.exception.status_code, 409)
        self.assertEqual(item.metadata_json[KEY]["status"], "completed")

    def test_conflicting_task_rejected_before_event_mutation(self):
        item = SimpleNamespace(id="event", occurred_at=ORIGIN, expected_date=EXPECTED, metadata_json={})
        task = SimpleNamespace(status="cancelled")
        db = SimpleNamespace(scalar=lambda query: item,
            scalars=lambda query: SimpleNamespace(all=lambda: [task]),
            flush=lambda: self.fail("Não deveria gravar"))
        principal = SimpleNamespace(user=SimpleNamespace(id="user"), company=SimpleNamespace(id="company"))
        with patch("app.routers.livestock._animal", return_value=SimpleNamespace(id="cow", farm_id="farm")):
            with self.assertRaises(HTTPException) as raised:
                update_reproduction_event("cow", "event", ReproductionEventUpdateRequest(metadata_json=metadata()), principal, db)
        self.assertEqual(raised.exception.status_code, 409)
        self.assertEqual(item.metadata_json, {})
        self.assertEqual(task.status, "cancelled")

if __name__ == "__main__": unittest.main(verbosity=2)
