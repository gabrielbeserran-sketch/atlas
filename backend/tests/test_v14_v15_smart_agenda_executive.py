from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ROUTER = ROOT / "app" / "routers" / "livestock.py"


def source() -> str:
    return ROUTER.read_text(encoding="utf-8")


def test_smart_agenda_endpoint_exists() -> None:
    text = source()
    assert '"/intelligence/smart-agenda/reconcile"' in text
    assert "def smart_agenda_reconcile" in text


def test_smart_agenda_sources_are_integrated() -> None:
    text = source()
    for source_type in (
        "weight_schedule",
        "nutrition_plan",
        "health_event",
        "reproduction_event",
    ):
        assert source_type in text


def test_weight_mutations_resync_agenda() -> None:
    text = source()
    assert text.count("_sync_weight_schedule_task(") >= 4


def test_nutrition_plan_mutations_resync_agenda() -> None:
    text = source()
    assert text.count("_sync_nutrition_plan_task(") >= 4


def test_executive_indicators_are_in_summary() -> None:
    text = source()
    for field in (
        "pregnancy_rate_percent",
        "average_weight_kg",
        "average_gmd_kg_day",
        "cost_per_active_animal",
        "critical_stock_items",
        "overdue_tasks",
        "nutrition_monthly_cost",
    ):
        assert field in text
