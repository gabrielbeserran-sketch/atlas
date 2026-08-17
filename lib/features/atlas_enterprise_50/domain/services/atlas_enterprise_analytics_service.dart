import 'package:projeto_atlas/features/atlas_enterprise_50/domain/models/atlas_enterprise_record.dart';

class AtlasEnterpriseAnalytics {
  const AtlasEnterpriseAnalytics({
    required this.totalRecords,
    required this.completedRecords,
    required this.alertRecords,
    required this.totalValue,
    required this.progressPercent,
    required this.score,
    required this.recommendations,
  });

  final int totalRecords;
  final int completedRecords;
  final int alertRecords;
  final double totalValue;
  final double progressPercent;
  final int score;
  final List<String> recommendations;
}

class AtlasEnterpriseAnalyticsService {
  const AtlasEnterpriseAnalyticsService();

  AtlasEnterpriseAnalytics analyze({
    required List<AtlasEnterpriseRecord> records,
    required int totalCapabilities,
  }) {
    final completed = records.where((record) => record.isCompleted).length;
    final alerts = records.where((record) => record.isAlert).length;
    final totalValue = records.fold<double>(
      0,
      (total, record) => total + record.totalValue,
    );
    final coveredSteps = records.map((record) => record.stepId).toSet().length;
    final progress = totalCapabilities == 0
        ? 0.0
        : (coveredSteps / totalCapabilities * 100).clamp(0, 100).toDouble();

    var score = 35;
    score += (progress * 0.45).round();
    score += completed.clamp(0, 10) * 2;
    score -= alerts.clamp(0, 10) * 3;
    score = score.clamp(0, 100).toInt();

    final recommendations = <String>[
      if (records.isEmpty)
        'Cadastre o primeiro registro para iniciar a inteligência do pacote.',
      if (coveredSteps < totalCapabilities)
        'Existem ${totalCapabilities - coveredSteps} funcionalidades sem registros operacionais.',
      if (alerts > 0) 'Há $alerts registro(s) em atenção ou estado crítico.',
      if (completed > 0)
        '$completed registro(s) foram concluídos e compõem o histórico de execução.',
      if (progress >= 80)
        'A cobertura do pacote está avançada; priorize qualidade, integração e auditoria.',
    ];

    return AtlasEnterpriseAnalytics(
      totalRecords: records.length,
      completedRecords: completed,
      alertRecords: alerts,
      totalValue: totalValue,
      progressPercent: progress,
      score: score,
      recommendations: recommendations,
    );
  }
}
