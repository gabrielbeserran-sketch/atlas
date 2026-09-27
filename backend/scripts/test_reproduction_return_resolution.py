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
from fastapi import HTTPException
from app.models import OperationalTask
from app.routers.livestock import _sync_operational_task, update_reproduction_event, add_reproduction_event
from app.schemas.legacy import ReproductionEventUpdateRequest, ReproductionEventCreateRequest
from app.services.reproduction_return_resolution import validate_resolution, apply_resolution_to_task, KEY

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

class RouteTests(unittest.TestCase):
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
        db = SimpleNamespace(scalar=lambda query: item, flush=lambda: None,
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

if __name__ == "__main__": unittest.main(verbosity=2)
