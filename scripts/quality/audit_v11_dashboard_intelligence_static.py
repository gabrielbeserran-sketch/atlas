from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
dashboard = (ROOT / 'lib/features/dashboard/presentation/screens/dashboard_screen.dart').read_text(encoding='utf-8')
service = (ROOT / 'lib/features/dashboard/data/services/atlas_operational_intelligence_service.dart').read_text(encoding='utf-8')
model = (ROOT / 'lib/features/dashboard/domain/models/atlas_operational_intelligence_data.dart').read_text(encoding='utf-8')
widget = (ROOT / 'lib/features/dashboard/presentation/widgets/operational_intelligence_card.dart').read_text(encoding='utf-8')

checks = {
    'summary_endpoint': '/livestock/intelligence/operational-summary' in service,
    'alerts_endpoint': '/livestock/intelligence/operational-alerts' in service,
    'dashboard_card': 'OperationalIntelligenceCard(' in dashboard,
    'active_farm_context': 'loadActiveFarm()' in dashboard,
    'score': 'operationalScore' in model and 'Score operacional Atlas' in widget,
    'alert_counts': 'criticalAlerts' in model and 'highAlerts' in model,
    'top_actions': 'topActions' in model and 'Prioridades recomendadas' in widget,
    'navigation_health': 'openHealth();' in dashboard,
    'navigation_reproduction': 'openReproduction();' in dashboard,
    'navigation_nutrition': 'openNutrition();' in dashboard,
    'navigation_finance': 'openFinance();' in dashboard,
    'navigation_inventory': 'openInventory();' in dashboard,
    'graceful_failure': 'operationalWarning' in dashboard,
}

for name, ok in checks.items():
    print(f"[{'OK' if ok else 'ERRO'}] {name}")

failed = [name for name, ok in checks.items() if not ok]
if failed:
    raise SystemExit(f'REPROVADO: {len(failed)} falha(s): {failed}')
print(f'APROVADO: {len(checks)}/{len(checks)} verificações')
