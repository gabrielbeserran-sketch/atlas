import 'package:projeto_atlas/core/contracts/atlas_action_contract.dart';
import 'package:projeto_atlas/core/contracts/atlas_alert_contract.dart';
import 'package:projeto_atlas/core/contracts/atlas_decision_contract.dart';
import 'package:projeto_atlas/features/action_plan/domain/adapters/atlas_action_plan_canonical_adapter.dart';
import 'package:projeto_atlas/features/action_plan/domain/models/atlas_action_plan.dart';
import 'package:projeto_atlas/features/executive_alerts/domain/adapters/atlas_executive_alert_contract_adapter.dart';
import 'package:projeto_atlas/features/executive_alerts/domain/models/atlas_executive_alert.dart';

class AtlasCanonicalOperationsData {
  const AtlasCanonicalOperationsData({
    required this.generatedAt,
    required this.actionPlan,
    required this.actions,
    required this.alerts,
  });

  final DateTime generatedAt;
  final AtlasActionPlan actionPlan;
  final List<AtlasActionContract> actions;
  final List<AtlasAlertContract> alerts;
}

/// Fachada única para disponibilizar decisões, ações e alertas em formato
/// canônico aos painéis, Copiloto e Cérebro Executivo.
class AtlasCanonicalOperationsService {
  const AtlasCanonicalOperationsService({
    this.actionPlanAdapter = const AtlasActionPlanCanonicalAdapter(),
    this.alertAdapter = const AtlasExecutiveAlertContractAdapter(),
  });

  final AtlasActionPlanCanonicalAdapter actionPlanAdapter;
  final AtlasExecutiveAlertContractAdapter alertAdapter;

  AtlasCanonicalOperationsData build({
    required List<AtlasDecisionContract> decisions,
    required AtlasExecutiveAlertSummary executiveAlerts,
    required String farmId,
    required String farmName,
    Map<String, String> farmIdsByName = const <String, String>{},
    DateTime? generatedAt,
  }) {
    final now = generatedAt ?? DateTime.now();
    final plan = actionPlanAdapter.fromDecisions(
      decisions: decisions,
      farmId: farmId,
      farmName: farmName,
      generatedAt: now,
    );

    return AtlasCanonicalOperationsData(
      generatedAt: now,
      actionPlan: plan,
      actions: actionPlanAdapter.toCanonicalActions(plan),
      alerts: alertAdapter.fromSummary(
        executiveAlerts,
        farmIdsByName: farmIdsByName,
      ),
    );
  }
}
