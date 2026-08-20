from __future__ import annotations

from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]
ROUTER = BACKEND_ROOT / "app" / "routers" / "livestock.py"


def _text() -> str:
    return ROUTER.read_text(encoding="utf-8")


def test_v10_alerts_endpoint_exists_and_is_read_only() -> None:
    text = _text()
    assert '@router.get("/intelligence/operational-alerts")' in text
    block = text[
        text.index('def operational_intelligence_alerts'):
        text.index('@router.get("/intelligence/operational-summary")')
    ]
    assert "db.add(" not in block
    assert "db.delete(" not in block
    assert "db.commit(" not in block


def test_v10_summary_endpoint_exists() -> None:
    text = _text()
    assert '@router.get("/intelligence/operational-summary")' in text
    assert "operational_score" in text
    assert "top_actions" in text


def test_v10_reuses_v9_reconciliation() -> None:
    text = _text()
    assert "operational_integrity_reconciliation(" in text
    assert "integrity_" in text


def test_v10_covers_cross_module_signals() -> None:
    text = _text()
    for marker in (
        "stock_below_minimum",
        "health_followup_overdue",
        "withdrawal_active",
        "low_body_condition",
        "negative_daily_gain",
        "calving_due",
        "nutrition_plan_expired",
        "finance_overdue_",
        "task_overdue",
    ):
        assert marker in text


def test_v10_alerts_are_company_and_farm_scoped() -> None:
    text = _text()
    block = text[
        text.index('def operational_intelligence_alerts'):
        text.index('@router.get("/intelligence/operational-summary")')
    ]
    assert "principal.company.id" in block
    assert "farm_id == farm_id" in block
    assert "_farm_allowed(db, principal, farm_id)" in block
