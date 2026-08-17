import 'package:projeto_atlas/core/contracts/atlas_canonical_types.dart';
import 'package:projeto_atlas/core/contracts/atlas_decision_contract.dart';
import 'package:projeto_atlas/features/decision_engine_v2/domain/models/atlas_decision_engine_v2_data.dart';

/// Adaptador oficial entre o Decision Engine V2 e o contrato canônico de
/// decisões do Atlas.
///
/// Este arquivo não recalcula decisões. Ele apenas traduz o resultado já
/// produzido pelo motor principal para a linguagem comum consumida pelo
/// Executive Brain, painéis, copiloto, alertas e planos de ação.
class AtlasDecisionEngineV2ContractAdapter {
  const AtlasDecisionEngineV2ContractAdapter();

  List<AtlasDecisionContract> adaptData(
    AtlasDecisionEngineV2Data data, {
    String Function(AtlasDecisionV2Action action)? farmIdResolver,
  }) {
    return data.rankedActions
        .map(
          (action) => adaptAction(
            action,
            generatedAt: data.generatedAt,
            farmId: farmIdResolver?.call(action),
          ),
        )
        .toList(growable: false);
  }

  AtlasDecisionContract adaptAction(
    AtlasDecisionV2Action action, {
    required DateTime generatedAt,
    String? farmId,
  }) {
    final resolvedFarmId = _resolveFarmId(
      farmId: farmId,
      farmName: action.farmName,
    );

    return AtlasDecisionContract(
      id: action.id,
      farmId: resolvedFarmId,
      farmName: action.farmName,
      generatedAt: generatedAt,
      title: action.title,
      description: action.description,
      reasoning: action.reasoning,
      expectedResult: action.expectedResult,
      sourceModule: 'decision_engine_v2',
      category: action.category.name,
      priority: _priority(action.priority),
      horizon: _horizon(action.horizon),
      risk: _risk(action.risk),
      confidencePercent: action.confidencePercent.clamp(0.0, 100.0).toDouble(),
      decisionScore: action.decisionScore.clamp(0.0, 100.0).toDouble(),
      expectedFinancialImpact: action.expectedFinancialImpact,
      deadline: generatedAt.add(
        Duration(days: action.deadlineDays < 0 ? 0 : action.deadlineDays),
      ),
      dependencies: List<String>.unmodifiable(action.dependencies),
      evidence: List<String>.unmodifiable(_buildEvidence(action)),
    );
  }

  String _resolveFarmId({required String? farmId, required String farmName}) {
    final explicitId = farmId?.trim();
    if (explicitId != null && explicitId.isNotEmpty) {
      return explicitId;
    }

    final normalized = farmName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return normalized.isEmpty ? 'farm_not_informed' : normalized;
  }

  List<String> _buildEvidence(AtlasDecisionV2Action action) {
    final evidence = <String>[
      'Posição no ranking: ${action.position}',
      'Impacto técnico: ${action.impactScore.toStringAsFixed(1)}',
      'Urgência: ${atlasDecisionV2UrgencyLabel(action.urgency)}',
      'Esforço: ${atlasDecisionV2EffortLabel(action.effort)}',
      'Prazo operacional: ${action.deadlineDays} dia(s)',
    ];

    if (action.investmentValue != 0) {
      evidence.add(
        'Investimento estimado: ${action.investmentValue.toStringAsFixed(2)}',
      );
    }

    if (action.expectedReturnValue != 0) {
      evidence.add(
        'Retorno estimado: ${action.expectedReturnValue.toStringAsFixed(2)}',
      );
    }

    if (action.roiPercent != 0) {
      evidence.add('ROI estimado: ${action.roiPercent.toStringAsFixed(1)}%');
    }

    return evidence;
  }

  AtlasCanonicalPriority _priority(AtlasDecisionV2Priority value) {
    switch (value) {
      case AtlasDecisionV2Priority.low:
        return AtlasCanonicalPriority.low;
      case AtlasDecisionV2Priority.medium:
        return AtlasCanonicalPriority.medium;
      case AtlasDecisionV2Priority.high:
        return AtlasCanonicalPriority.high;
      case AtlasDecisionV2Priority.critical:
        return AtlasCanonicalPriority.critical;
    }
  }

  AtlasCanonicalHorizon _horizon(AtlasDecisionV2Horizon value) {
    switch (value) {
      case AtlasDecisionV2Horizon.today:
        return AtlasCanonicalHorizon.today;
      case AtlasDecisionV2Horizon.week:
        return AtlasCanonicalHorizon.week;
      case AtlasDecisionV2Horizon.month:
        return AtlasCanonicalHorizon.month;
    }
  }

  AtlasCanonicalRisk _risk(AtlasDecisionV2Risk value) {
    switch (value) {
      case AtlasDecisionV2Risk.low:
        return AtlasCanonicalRisk.low;
      case AtlasDecisionV2Risk.medium:
        return AtlasCanonicalRisk.medium;
      case AtlasDecisionV2Risk.high:
        return AtlasCanonicalRisk.high;
      case AtlasDecisionV2Risk.critical:
        return AtlasCanonicalRisk.critical;
    }
  }
}

extension AtlasDecisionEngineV2CanonicalExtension on AtlasDecisionEngineV2Data {
  /// Expõe as decisões do motor V2 no contrato único do projeto.
  List<AtlasDecisionContract> toCanonicalDecisions({
    String Function(AtlasDecisionV2Action action)? farmIdResolver,
  }) {
    return const AtlasDecisionEngineV2ContractAdapter().adaptData(
      this,
      farmIdResolver: farmIdResolver,
    );
  }
}
