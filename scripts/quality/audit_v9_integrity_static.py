from pathlib import Path
import sys
root=Path(__file__).resolve().parents[2]
t=(root/"backend/app/routers/livestock.py").read_text(encoding="utf-8")
checks={
"endpoint": '@router.get("/integrity/reconciliation")' in t,
"read_only": 'def operational_integrity_reconciliation' in t,
"finance_orphans": all(x in t for x in ["orphan_finance_health","orphan_finance_nutrition"]),
"stock_orphans": all(x in t for x in ["orphan_stock_health","orphan_stock_nutrition"]),
"task_orphans": all(x in t for x in ["orphan_task_health","orphan_task_reproduction"]),
"weight_state": "stale_animal_weight" in t,
"repro_state": "stale_reproductive_status" in t,
"duplicate_finance": "duplicate_finance_reference" in t,
"company_scope": "ReproductionEvent.company_id == animal.company_id" in t,
}
for k,v in checks.items(): print(("[OK] " if v else "[ERRO] ")+k)
print(f"APROVADO: {sum(checks.values())}/{len(checks)} verificações")
sys.exit(0 if all(checks.values()) else 1)
