from pathlib import Path

root = Path(__file__).resolve().parents[2]
router = (root / "backend/app/routers/livestock.py").read_text(encoding="utf-8")
dashboard = (
    root / "lib/features/dashboard/presentation/screens/dashboard_screen.dart"
).read_text(encoding="utf-8")
agenda = (
    root
    / "lib/features/farm_agenda/data/services/farm_agenda_storage_service.dart"
).read_text(encoding="utf-8")
model = (
    root
    / "lib/features/dashboard/domain/models/"
    / "atlas_operational_intelligence_data.dart"
).read_text(encoding="utf-8")

checks = {
    "smart_agenda_endpoint": "/intelligence/smart-agenda/reconcile" in router,
    "weight_schedule": "weight_schedule" in router,
    "nutrition_schedule": 'source_type="nutrition_plan"' in router,
    "health_schedule": 'source_type="health_event"' in router,
    "reproduction_schedule": 'source_type="reproduction_event"' in router,
    "agenda_idempotence": "_sync_operational_task" in router,
    "pregnancy_indicator": "pregnancy_rate_percent" in router,
    "gmd_indicator": "average_gmd_kg_day" in router,
    "cost_per_animal": "cost_per_active_animal" in router,
    "critical_stock": "critical_stock_items" in router,
    "overdue_tasks": "overdue_tasks" in router,
    "nutrition_monthly_cost": "nutrition_monthly_cost" in router,
    "flutter_reconcile": "reconcileSmartAgenda" in dashboard,
    "flutter_executive_card": "ExecutiveIndicatorsCard" in dashboard,
    "flutter_model": "pregnancyRatePercent" in model,
    "agenda_service_endpoint": "/livestock/intelligence/smart-agenda/reconcile" in agenda,
}

for name, passed in checks.items():
    print(f"[{'OK' if passed else 'ERRO'}] {name}")

failed = [name for name, passed in checks.items() if not passed]
if failed:
    raise SystemExit(f"REPROVADO: {failed}")

print(f"APROVADO: {len(checks)}/{len(checks)} verificações")
