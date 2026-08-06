from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def test_phase2_models_and_routes_exist():
    models=(ROOT/'app/models.py').read_text(encoding='utf-8'); router=(ROOT/'app/routers/livestock.py').read_text(encoding='utf-8')
    assert 'class NutritionIngredient(Base)' in models
    assert 'class NutritionPlan(Base)' in models
    assert '@router.get("/inventory/alerts"' in router
    assert '@router.post("/nutrition/lots/{lot_id}/consumption"' in router
    assert 'movement_type="nutrition_consumption"' in router

def test_phase3_financial_contract_exists():
    models=(ROOT/'app/models.py').read_text(encoding='utf-8'); router=(ROOT/'app/routers/livestock.py').read_text(encoding='utf-8')
    for field in ['cost_center','animal_id','lot_id','recurring','recurrence_rule']:
        assert field in models
    assert '@router.get("/finance/summary"' in router
    assert '@router.get("/finance/cash-flow"' in router
    assert 'cost_per_animal' in router

def test_migrations_are_chained():
    m21=(ROOT/'alembic/versions/20260806_0021_phase2_nutrition_inventory.py').read_text(encoding='utf-8')
    m22=(ROOT/'alembic/versions/20260806_0022_phase3_finance_costs.py').read_text(encoding='utf-8')
    assert 'down_revision = "20260806_0020"' in m21
    assert 'down_revision="20260806_0021"' in m22
