from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
router = (ROOT / 'backend/app/routers/livestock.py').read_text(encoding='utf-8')
schemas = (ROOT / 'backend/app/schemas/legacy.py').read_text(encoding='utf-8')
agenda = (ROOT / 'lib/features/farm_agenda/data/services/farm_agenda_storage_service.dart').read_text(encoding='utf-8')

checks = {
    'weight_update_contract': 'class WeightUpdateRequest(BaseModel):' in schemas,
    'weight_patch_endpoint': '@router.patch("/animals/{animal_id}/weights/{weight_id}"' in router,
    'weight_delete_endpoint': 'def delete_weight(' in router,
    'weight_state_refresh': 'def _refresh_animal_weight_state(' in router,
    'animal_lot_change_audit': 'reason="Alteração cadastral de lote"' in router,
    'health_patch_inventory_contract': 'inventory_quantity: float | None' in schemas,
    'health_stock_reconciliation': 'health_event_adjusted' in router and 'consumed_by_product' in router,
    'health_finance_reconciliation': 'cost_fields_changed' in router,
    'nutrition_delete_reversal': '@router.delete("/nutrition/events/{event_id}"' in router and 'nutrition_event_reversal' in router,
    'finance_integrated_entry_protection': 'Lançamento integrado deve ser alterado no módulo de origem.' in router,
    'inventory_quantity_protection': 'A quantidade deve ser alterada por uma movimentação de estoque.' in router,
    'inventory_nonzero_delete_protection': 'Zere o estoque antes de inativar o produto.' in router,
    'cross_farm_product_protection': 'A fazenda do produto não pode ser alterada.' in router,
    'cross_farm_plan_protection': 'A fazenda do plano não pode ser alterada.' in router,
    'cross_farm_finance_protection': 'A fazenda do lançamento não pode ser alterada.' in router,
    'agenda_cancel_confirmation': 'O cancelamento foi enviado, mas não foi confirmado pelo servidor.' in agenda,
}

failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(f"{'OK' if ok else 'FAIL'} {name}")

if failed:
    raise SystemExit(f"Falhas V7: {', '.join(failed)}")
print(f"APROVADO: {len(checks)}/{len(checks)} verificações")
