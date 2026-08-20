from pathlib import Path

root = Path(__file__).resolve().parents[2]

dashboard = (
    root / "lib/features/dashboard/presentation/screens/dashboard_screen.dart"
).read_text(encoding="utf-8")
alerts = (
    root
    / "lib/features/dashboard/presentation/screens/"
    / "operational_alert_center_screen.dart"
).read_text(encoding="utf-8")
herd = (
    root / "lib/features/herd/presentation/screens/herd_overview_screen.dart"
).read_text(encoding="utf-8")
agenda = (
    root
    / "lib/features/farm_agenda/presentation/screens/"
    / "farm_agenda_list_screen.dart"
).read_text(encoding="utf-8")

checks = {
    "no_hardcoded_user_greeting": "Olá, Gabriel!" not in dashboard,
    "advanced_analysis_grouped": "AdvancedAnalysisAccessCard" in dashboard,
    "dashboard_clutter_reduced": (
        dashboard.count("ExecutiveDashboardAccessCard(") == 1
        and dashboard.count("TechnicalDashboardAccessCard(") == 1
    ),
    "alert_filters_responsive": (
        "final compact = constraints.maxWidth < 720;" in alerts
    ),
    "alert_action_responsive": (
        "final compact = constraints.maxWidth < 650;" in alerts
    ),
    "herd_header_responsive": (
        "final compact = constraints.maxWidth < 620;" in herd
    ),
    "herd_filters_responsive": (
        "hintText: 'Brinco, SISBOV, nome ou raça'" in herd
    ),
    "herd_actions_compact": "PopupMenuButton<String>" in herd,
    "agenda_selector_scrollable": (
        "SingleChildScrollView(" in agenda
        and "scrollDirection: Axis.horizontal" in agenda
        and "showSelectedIcon: false" in agenda
    ),
}

for name, ok in checks.items():
    print(f"[{'OK' if ok else 'ERRO'}] {name}")

failed = [name for name, ok in checks.items() if not ok]
if failed:
    raise SystemExit(f"REPROVADO: {failed}")

print(f"APROVADO: {len(checks)}/{len(checks)} verificações")
