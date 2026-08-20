from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def test_v9_reconciliation_endpoint_present():
    text=(ROOT/"app"/"routers"/"livestock.py").read_text(encoding="utf-8")
    assert '@router.get("/integrity/reconciliation")' in text
    for code in ["orphan_finance_health","orphan_finance_nutrition","orphan_stock_health","orphan_stock_nutrition","orphan_task_health","orphan_task_reproduction","stale_animal_weight","stale_reproductive_status","duplicate_finance_reference"]:
        assert code in text

def test_reproduction_refresh_is_company_scoped():
    text=(ROOT/"app"/"routers"/"livestock.py").read_text(encoding="utf-8")
    start=text.index("def _refresh_animal_reproduction_state")
    end=text.index("def _lot",start)
    block=text[start:end]
    assert "ReproductionEvent.company_id == animal.company_id" in block
