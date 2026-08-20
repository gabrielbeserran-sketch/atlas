from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DASHBOARD = ROOT / 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
CENTER = ROOT / 'lib/features/dashboard/presentation/screens/operational_alert_center_screen.dart'
CARD = ROOT / 'lib/features/dashboard/presentation/widgets/operational_intelligence_card.dart'
MODEL = ROOT / 'lib/features/dashboard/domain/models/atlas_operational_intelligence_data.dart'
SERVICE = ROOT / 'lib/features/dashboard/data/services/atlas_operational_intelligence_service.dart'

checks = {
    'alert_center_screen': CENTER.exists(),
    'dashboard_opens_center': 'openOperationalAlertCenter' in DASHBOARD.read_text(encoding='utf-8'),
    'card_has_all_alerts_action': 'Ver todos os alertas' in CARD.read_text(encoding='utf-8'),
    'search_filter': 'Buscar alerta' in CENTER.read_text(encoding='utf-8'),
    'severity_filter': "labelText: 'Criticidade'" in CENTER.read_text(encoding='utf-8'),
    'area_filter': "labelText: 'Área'" in CENTER.read_text(encoding='utf-8'),
    'sorting': "labelText: 'Ordenar por'" in CENTER.read_text(encoding='utf-8'),
    'resolution_guide': 'Ação recomendada' in CENTER.read_text(encoding='utf-8'),
    'automatic_resolution_contract': 'desaparece automaticamente quando a causa real é corrigida' in CENTER.read_text(encoding='utf-8'),
    'area_navigation': 'widget.onOpenArea(alert.area)' in CENTER.read_text(encoding='utf-8'),
    'refresh_after_return': 'await loadDashboard();' in DASHBOARD.read_text(encoding='utf-8'),
    'alerts_endpoint_preserved': '/livestock/intelligence/operational-alerts' in SERVICE.read_text(encoding='utf-8'),
    'summary_endpoint_preserved': '/livestock/intelligence/operational-summary' in SERVICE.read_text(encoding='utf-8'),
    'entity_context_preserved': 'entityType' in MODEL.read_text(encoding='utf-8') and 'entityId' in MODEL.read_text(encoding='utf-8'),
}

failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(f"[{'OK' if ok else 'ERRO'}] {name}")

if failed:
    print(f"\nREPROVADO: {len(checks)-len(failed)}/{len(checks)} verificações")
    raise SystemExit(1)

print(f"\nAPROVADO: {len(checks)}/{len(checks)} verificações")
