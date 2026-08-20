from __future__ import annotations

from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]


def test_nutrition_response_matches_current_model() -> None:
    text = (
        BACKEND_ROOT / "app" / "schemas" / "legacy.py"
    ).read_text(encoding="utf-8")

    start = text.index("class NutritionEventResponse")
    end = text.index("\n\nclass OperationalAlertResponse", start)
    block = text[start:end]

    assert "amount_per_animal" in block
    assert "animal_count" in block
    assert "planned_quantity" in block
    assert "observed_daily_gain_kg" in block
    assert "feed_conversion" in block
    assert "quantity_per_head" not in block


def test_legacy_nutrition_create_maps_quantity_per_head() -> None:
    text = (
        BACKEND_ROOT / "app" / "routers" / "livestock.py"
    ).read_text(encoding="utf-8")

    assert "amount_per_animal=payload.quantity_per_head" in text
    assert "planned_quantity=payload.total_quantity" in text
