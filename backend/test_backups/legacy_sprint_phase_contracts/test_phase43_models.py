
from app.models import (
    FinancialEntry,
    HealthEvent,
    HerdLot,
    InventoryProduct,
    LivestockAnimal,
    NutritionEvent,
    ReproductionEvent,
    WeightRecord,
)


def test_phase43_models_have_expected_tables():
    assert HerdLot.__tablename__ == "herd_lots"
    assert LivestockAnimal.__tablename__ == "livestock_animals"
    assert WeightRecord.__tablename__ == "weight_records"
    assert ReproductionEvent.__tablename__ == "reproduction_events"
    assert HealthEvent.__tablename__ == "health_events"
    assert InventoryProduct.__tablename__ == "inventory_products"
    assert FinancialEntry.__tablename__ == "financial_entries"
    assert NutritionEvent.__tablename__ == "nutrition_events"
