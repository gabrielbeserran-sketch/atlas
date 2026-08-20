from __future__ import annotations

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
ROUTER = ROOT / "backend" / "app" / "routers" / "livestock.py"
text = ROUTER.read_text(encoding="utf-8")

checks = {
    "alerts_endpoint": '@router.get("/intelligence/operational-alerts")' in text,
    "summary_endpoint": '@router.get("/intelligence/operational-summary")' in text,
    "read_only_contract": "Motor V10 de alertas operacionais" in text,
    "v9_reconciliation_reused": "operational_integrity_reconciliation(" in text,
    "inventory_signals": "stock_below_minimum" in text and "stock_expired" in text,
    "health_signals": "health_followup_overdue" in text and "withdrawal_active" in text,
    "herd_signals": "low_body_condition" in text and "weight_stale" in text,
    "nutrition_signals": "negative_daily_gain" in text and "nutrition_plan_expired" in text,
    "reproduction_signals": "calving_due" in text and "calving_overdue" in text,
    "finance_signals": "finance_overdue_" in text,
    "agenda_signals": "task_overdue" in text and "task_due" in text,
    "priority_score": "priority_score" in text,
    "recommended_action": "recommended_action" in text,
    "executive_score": "operational_score" in text and "operational_level" in text,
    "top_actions": "top_actions" in text,
}

failed = []
for name, ok in checks.items():
    prefix = "[OK]" if ok else "[ERRO]"
    print(f"{prefix} {name}")
    if not ok:
        failed.append(name)

print()
if failed:
    print(f"REPROVADO: {len(failed)} falha(s): {', '.join(failed)}")
    raise SystemExit(1)

print(f"APROVADO: {len(checks)}/{len(checks)} verificações")
