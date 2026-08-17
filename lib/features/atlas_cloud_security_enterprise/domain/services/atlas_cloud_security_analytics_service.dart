import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_cloud_security_enterprise/domain/models/atlas_cloud_security_record.dart';

class AtlasCloudSecurityAnalytics {
  const AtlasCloudSecurityAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.overdueCount,
    required this.averageProgress,
    required this.averageAvailability,
    required this.averageRisk,
    required this.totalRetries,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final int overdueCount;
  final double averageProgress;
  final double averageAvailability;
  final double averageRisk;
  final int totalRetries;
  final int score;
  final List<String> recommendations;
}

class AtlasCloudSecurityAnalyticsService {
  const AtlasCloudSecurityAnalyticsService();

  AtlasCloudSecurityAnalytics analyze({
    required AtlasCloudSecurityModule module,
    required List<AtlasCloudSecurityRecord> records,
  }) {
    final moduleRecords = records
        .where((record) => record.module == module)
        .toList(growable: false);

    final represented = moduleRecords
        .map((record) => record.feature)
        .where((value) => value.trim().isNotEmpty)
        .toSet();

    final coverage = module.features.isEmpty
        ? 0.0
        : represented.length * 100.0 / module.features.length;

    final operational = moduleRecords
        .where((record) => record.isOperational)
        .length;
    final overdue = moduleRecords.where((record) => record.isOverdue).length;

    final alerts = moduleRecords.fold<int>(
      0,
      (total, record) =>
          total +
          record.alertCount +
          (record.isCritical ? 1 : 0) +
          (record.isOverdue ? 1 : 0),
    );

    double averageOf(double Function(AtlasCloudSecurityRecord) selector) {
      if (moduleRecords.isEmpty) return 0;
      return moduleRecords.map(selector).reduce((a, b) => a + b) /
          moduleRecords.length;
    }

    final averageProgress = averageOf(
      (record) => record.progressPercent.toDouble(),
    );
    final averageAvailability = averageOf(
      (record) => record.availabilityPercent,
    );
    final averageRisk = averageOf((record) => record.riskPercent);
    final totalRetries = moduleRecords.fold<int>(
      0,
      (total, record) => total + record.retryCount,
    );

    var score = 30;
    score += math.min(25, coverage.round() * 25 ~/ 100);
    score += math.min(20, operational * 4);
    score += math.min(15, averageProgress.round() * 15 ~/ 100);
    score += math.min(15, averageAvailability.round() * 15 ~/ 100);
    score -= math.min(30, alerts * 5);
    score -= math.min(15, overdue * 5);
    score -= math.min(20, averageRisk.round() * 20 ~/ 100);
    score = score.clamp(0, 100).toInt();

    final recommendations = <String>[];

    for (final feature in module.features) {
      if (!represented.contains(feature)) {
        recommendations.add('Implantar ou registrar: $feature.');
      }
    }

    if (overdue > 0) {
      recommendations.add(
        'Existem $overdue registros vencidos; revise prazos, responsáveis e controles.',
      );
    }

    if (alerts > 0) {
      recommendations.add(
        'Existem $alerts alertas de segurança ou disponibilidade; priorize os críticos.',
      );
    }

    if (moduleRecords.isEmpty) {
      recommendations.add(
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      );
    } else {
      recommendations.addAll(switch (module) {
        AtlasCloudSecurityModule.professionalAuthentication => const [
          'Implemente MFA, expiração de sessão e bloqueio por tentativas.',
          'Nunca armazene senhas em texto simples.',
        ],
        AtlasCloudSecurityModule.usersAndCompanies => const [
          'Separe usuários, empresas, fazendas e papéis.',
          'Revogue acessos imediatamente após desligamentos.',
        ],
        AtlasCloudSecurityModule.cloudDatabase => const [
          'Use migrações versionadas e ambientes separados.',
          'Monitore disponibilidade, erro e desempenho.',
        ],
        AtlasCloudSecurityModule.offlineSynchronization => const [
          'Mantenha fila persistente e retentativas controladas.',
          'Exiba claramente o status de sincronização.',
        ],
        AtlasCloudSecurityModule.conflictResolution => const [
          'Registre versões e origem de cada alteração.',
          'Permita revisão manual para conflitos críticos.',
        ],
        AtlasCloudSecurityModule.automatedBackup => const [
          'Teste restauração periodicamente.',
          'Mantenha retenção e cópia fora do ambiente principal.',
        ],
        AtlasCloudSecurityModule.dataEncryption => const [
          'Use TLS em trânsito e criptografia em repouso.',
          'Separe segredos do código-fonte e faça rotação de chaves.',
        ],
        AtlasCloudSecurityModule.userAuditLogs => const [
          'Registre quem, quando, onde e o que mudou.',
          'Proteja logs contra alteração e exclusão indevida.',
        ],
        AtlasCloudSecurityModule.integrationCenter => const [
          'Armazene credenciais em serviço seguro.',
          'Monitore falhas, latência e limites das APIs.',
        ],
        AtlasCloudSecurityModule.securityCenter => const [
          'Centralize sessões, incidentes, permissões e backups.',
          'Priorize riscos por severidade, alcance e urgência.',
        ],
      });
    }

    return AtlasCloudSecurityAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      alertCount: alerts,
      overdueCount: overdue,
      averageProgress: averageProgress,
      averageAvailability: averageAvailability,
      averageRisk: averageRisk,
      totalRetries: totalRetries,
      score: score,
      recommendations: recommendations,
    );
  }
}
