import 'package:projeto_atlas/core/contracts/atlas_alert_contract.dart';
import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/features/executive_alerts/domain/models/atlas_executive_alert.dart';

/// Converte alertas já produzidos pelo Executive Alerts para o contrato único.
///
/// Nenhuma nova regra de alerta é criada aqui. O serviço existente permanece
/// sendo a fonte de verdade; este adaptador apenas padroniza a saída.
class AtlasExecutiveAlertContractAdapter {
  const AtlasExecutiveAlertContractAdapter();

  List<AtlasAlertContract> fromSummary(
    AtlasExecutiveAlertSummary summary, {
    Map<String, String> farmIdsByName = const <String, String>{},
  }) {
    return summary.alerts
        .map(
          (alert) =>
              fromAlert(alert, farmId: farmIdsByName[alert.farmName] ?? ''),
        )
        .toList(growable: false);
  }

  AtlasAlertContract fromAlert(
    AtlasExecutiveAlert alert, {
    String farmId = '',
  }) {
    final dueAt = alert.responseDeadlineDays < 0
        ? null
        : alert.generatedAt.add(Duration(days: alert.responseDeadlineDays));

    return AtlasAlertContract(
      id: alert.id,
      farmId: farmId,
      farmName: alert.farmName,
      createdAt: alert.generatedAt,
      title: alert.title,
      description: alert.description,
      area: alert.area.name,
      sourceModule: 'executive_alerts:${alert.type.name}',
      priority: _priority(alert.severity),
      risk: _risk(alert.severity),
      status: AtlasCanonicalStatus.pending,
      dueAt: dueAt,
      relatedEntityIds: const <String>[],
      recommendedAction: alert.recommendation,
    );
  }

  AtlasCanonicalPriority _priority(AtlasExecutiveAlertSeverity severity) {
    switch (severity) {
      case AtlasExecutiveAlertSeverity.informational:
        return AtlasCanonicalPriority.low;
      case AtlasExecutiveAlertSeverity.attention:
        return AtlasCanonicalPriority.medium;
      case AtlasExecutiveAlertSeverity.high:
        return AtlasCanonicalPriority.high;
      case AtlasExecutiveAlertSeverity.critical:
        return AtlasCanonicalPriority.critical;
    }
  }

  AtlasCanonicalRisk _risk(AtlasExecutiveAlertSeverity severity) {
    switch (severity) {
      case AtlasExecutiveAlertSeverity.informational:
        return AtlasCanonicalRisk.low;
      case AtlasExecutiveAlertSeverity.attention:
        return AtlasCanonicalRisk.medium;
      case AtlasExecutiveAlertSeverity.high:
        return AtlasCanonicalRisk.high;
      case AtlasExecutiveAlertSeverity.critical:
        return AtlasCanonicalRisk.critical;
    }
  }
}

extension AtlasExecutiveAlertSummaryCanonicalExtension
    on AtlasExecutiveAlertSummary {
  List<AtlasAlertContract> toCanonicalAlerts({
    Map<String, String> farmIdsByName = const <String, String>{},
  }) {
    return const AtlasExecutiveAlertContractAdapter().fromSummary(
      this,
      farmIdsByName: farmIdsByName,
    );
  }
}
