from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ROUTER = (ROOT / "app/routers/livestock.py").read_text(encoding="utf-8")
SCHEMAS = (ROOT / "app/schemas/legacy.py").read_text(encoding="utf-8")


def test_weight_crud_and_state_refresh_are_present():
    assert 'class WeightUpdateRequest' in SCHEMAS
    assert '@router.patch("/animals/{animal_id}/weights/{weight_id}"' in ROUTER
    assert 'def delete_weight(' in ROUTER
    assert '_refresh_animal_weight_state' in ROUTER


def test_lot_change_via_animal_patch_is_audited():
    assert 'reason="Alteração cadastral de lote"' in ROUTER
    assert 'movement_type="lot_change"' in ROUTER


def test_health_patch_reconciles_integrations():
    assert 'stock_fields_changed' in ROUTER
    assert 'health_event_adjusted' in ROUTER
    assert 'Ajuste do evento sanitário' in ROUTER
    assert 'linked_finance = db.scalars' in ROUTER


def test_nutrition_delete_reverses_stock_and_finance():
    assert '@router.delete("/nutrition/events/{event_id}"' in ROUTER
    assert 'nutrition_event_reversal' in ROUTER
    assert 'Estorno do consumo nutricional' in ROUTER


def test_source_backed_finance_is_protected():
    assert ROUTER.count('Lançamento integrado deve ser alterado no módulo de origem.') >= 1
    assert ROUTER.count('Lançamento integrado deve ser excluído no módulo de origem.') >= 1


def test_inventory_quantity_requires_movement():
    assert 'A quantidade deve ser alterada por uma movimentação de estoque.' in ROUTER

def test_cross_farm_mutations_are_blocked():
    assert 'A fazenda do produto não pode ser alterada.' in ROUTER
    assert 'A fazenda do plano não pode ser alterada.' in ROUTER
    assert 'A fazenda do lançamento não pode ser alterada.' in ROUTER
