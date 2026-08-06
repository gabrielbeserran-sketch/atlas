import 'package:projeto_atlas/features/optimization_engine/domain/models/atlas_optimization_request.dart';
import 'package:projeto_atlas/features/scenario_simulator/domain/models/atlas_simulation_result.dart';

class AtlasOptimizationResult {
  const AtlasOptimizationResult({
    required this.id,
    required this.request,
    required this.generatedAt,
    required this.candidates,
    required this.bestCandidate,
    required this.summary,
    required this.selectionReasons,
  });

  final String id;
  final AtlasOptimizationRequest request;
  final DateTime generatedAt;
  final List<AtlasOptimizationCandidate> candidates;
  final AtlasOptimizationCandidate bestCandidate;
  final String summary;
  final List<String> selectionReasons;
}

class AtlasOptimizationCandidate {
  const AtlasOptimizationCandidate({
    required this.position,
    required this.name,
    required this.result,
    required this.optimizationScore,
    required this.objectiveScore,
    required this.financialScore,
    required this.riskScore,
    required this.balanceScore,
    required this.isEligible,
    required this.constraintNotes,
  });

  final int position;
  final String name;
  final AtlasSimulationResult result;
  final double optimizationScore;
  final double objectiveScore;
  final double financialScore;
  final double riskScore;
  final double balanceScore;
  final bool isEligible;
  final List<String> constraintNotes;
}
