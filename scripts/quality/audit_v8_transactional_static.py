from pathlib import Path
import ast

ROOT = Path(__file__).resolve().parents[2]
router = (ROOT / "backend/app/routers/livestock.py").read_text(encoding="utf-8")
ops = (ROOT / "backend/app/routers/operations.py").read_text(encoding="utf-8")
tests = (ROOT / "backend/tests/test_v8_transactional_roundtrip.py").read_text(encoding="utf-8")
marco2 = (ROOT / "backend/tests/test_marco2_management_crud.py").read_text(encoding="utf-8")

# Syntax gate for the central transactional modules and V8 tests.
for rel in [
    "backend/app/routers/livestock.py",
    "backend/app/routers/operations.py",
    "backend/app/schemas/legacy.py",
    "backend/tests/test_v8_transactional_roundtrip.py",
    "backend/tests/test_marco2_management_crud.py",
]:
    ast.parse((ROOT / rel).read_text(encoding="utf-8"), filename=rel)

checks = {
    "weight_patch": '@router.patch("/animals/{animal_id}/weights/{weight_id}"' in router,
    "weight_delete": 'def delete_weight(' in router and '_refresh_animal_weight_state' in router,
    "lot_patch_audit": 'reason="Alteração cadastral de lote"' in router,
    "health_stock_reversal": 'reference_type="health_event_reversal"' in router,
    "health_finance_reconcile": 'linked_finance = db.scalars' in router,
    "health_task_cleanup": '_delete_source_tasks(' in router,
    "nutrition_delete_reversal": '@router.delete("/nutrition/events/{event_id}"' in router and 'nutrition_event_reversal' in router,
    "integrated_finance_protection": 'Lançamento integrado deve ser alterado no módulo de origem.' in router and 'Lançamento integrado deve ser excluído no módulo de origem.' in router,
    "inventory_direct_quantity_block": 'A quantidade deve ser alterada por uma movimentação de estoque.' in router,
    "inventory_nonzero_delete_block": 'Zere o estoque antes de inativar o produto.' in router,
    "agenda_patch": '@router.patch("/tasks/{task_id}"' in ops,
    "roundtrip_weight_test": 'test_v8_weight_patch_delete_refreshes_animal_state' in tests,
    "roundtrip_health_test": 'test_v8_health_patch_and_delete_reconcile_stock_finance_and_task' in tests,
    "roundtrip_nutrition_test": 'test_v8_nutrition_delete_reverses_stock_and_finance' in tests,
    "roundtrip_invariant_test": 'test_v8_integrated_finance_and_inventory_invariants' in tests,
    "roundtrip_agenda_test": 'test_v8_agenda_task_roundtrip_persists_status' in tests,
    "legacy_test_updated": 'Limpeza do teste Marco 2' in marco2,
}

failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(("OK" if ok else "FAIL"), name)
print(f"APROVADO: {len(checks)-len(failed)}/{len(checks)} verificações")
if failed:
    raise SystemExit("Falharam: " + ", ".join(failed))
