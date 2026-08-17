import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_auth_sync_enterprise/domain/models/atlas_auth_sync_record.dart';

class AtlasAuthSyncAnalytics {
  const AtlasAuthSyncAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.totalPending,
    required this.totalRetries,
    required this.averageProgress,
    required this.averageSuccessRate,
    required this.averageRisk,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final int totalPending;
  final int totalRetries;
  final double averageProgress;
  final double averageSuccessRate;
  final double averageRisk;
  final int score;
  final List<String> recommendations;
}

class AtlasAuthSyncAnalyticsService {
  const AtlasAuthSyncAnalyticsService();

  AtlasAuthSyncAnalytics analyze({
    required AtlasAuthSyncModule module,
    required List<AtlasAuthSyncRecord> records,
  }) {
    final items = records
        .where((record) => record.module == module)
        .toList(growable: false);

    final represented = items
        .map((record) => record.feature)
        .where((value) => value.trim().isNotEmpty)
        .toSet();

    final coverage = module.features.isEmpty
        ? 0.0
        : represented.length * 100.0 / module.features.length;

    final operational = items.where((record) => record.isOperational).length;

    final alerts = items.fold<int>(
      0,
      (total, record) =>
          total + record.alertCount + (record.isCritical ? 1 : 0),
    );

    double averageOf(double Function(AtlasAuthSyncRecord) selector) {
      if (items.isEmpty) return 0;
      return items.map(selector).reduce((a, b) => a + b) / items.length;
    }

    final pending = items.fold<int>(
      0,
      (total, record) => total + record.pendingCount,
    );
    final retries = items.fold<int>(
      0,
      (total, record) => total + record.retryCount,
    );
    final progress = averageOf((record) => record.progressPercent.toDouble());
    final success = averageOf((record) => record.successRatePercent);
    final risk = averageOf((record) => record.riskPercent);

    var score = 30;
    score += math.min(25, coverage.round() * 25 ~/ 100);
    score += math.min(20, operational * 4);
    score += math.min(15, progress.round() * 15 ~/ 100);
    score += math.min(15, success.round() * 15 ~/ 100);
    score -= math.min(30, alerts * 5);
    score -= math.min(15, pending);
    score -= math.min(20, risk.round() * 20 ~/ 100);
    score = score.clamp(0, 100).toInt();

    final recommendations = <String>[
      for (final feature in module.features)
        if (!represented.contains(feature)) 'Implantar ou registrar: $feature.',
      if (alerts > 0)
        'Existem $alerts alertas de autenticação ou sincronização; priorize os críticos.',
      if (pending > 0)
        'Existem $pending operações pendentes; revise conectividade, fila e confirmação do servidor.',
      if (items.isEmpty)
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      ...switch (module) {
        AtlasAuthSyncModule.secureUserRegistration => const [
          'Valide e-mail, senha e aceite de termos no servidor.',
          'Não ative contas sem confirmação segura.',
        ],
        AtlasAuthSyncModule.secureTokenLogin => const [
          'Use tokens curtos, renovação controlada e revogação.',
          'Não armazene tokens sensíveis em texto simples.',
        ],
        AtlasAuthSyncModule.passwordRecovery => const [
          'Use token temporário de uso único.',
          'Invalide sessões antigas após redefinição.',
        ],
        AtlasAuthSyncModule.multiFactorAuthentication => const [
          'Proteja códigos de recuperação.',
          'Exija reautenticação em operações críticas.',
        ],
        AtlasAuthSyncModule.roleBasedAccessControl => const [
          'Aplique menor privilégio e escopo multempresa.',
          'Revise permissões após mudança de função.',
        ],
        AtlasAuthSyncModule.sensitiveDataProtection => const [
          'Separe segredos do código-fonte.',
          'Faça rotação de chaves e mantenha trilha de auditoria.',
        ],
        AtlasAuthSyncModule.immutableAuditLogs => const [
          'Registre ator, ação, recurso, data e origem.',
          'Proteja logs contra alteração e exclusão.',
        ],
        AtlasAuthSyncModule.structuredOfflineDatabase => const [
          'Use schema versionado e migrações locais.',
          'Não use SharedPreferences para dados relacionais críticos.',
        ],
        AtlasAuthSyncModule.synchronizationEngine => const [
          'Mantenha fila persistente, idempotência e retentativas.',
          'Confirme no servidor antes de remover itens da fila.',
        ],
        AtlasAuthSyncModule.realConflictResolution => const [
          'Compare versões e origem das alterações.',
          'Mantenha revisão manual para conflitos críticos.',
        ],
      },
    ];

    return AtlasAuthSyncAnalytics(
      coveragePercent: coverage,
      recordCount: items.length,
      operationalCount: operational,
      alertCount: alerts,
      totalPending: pending,
      totalRetries: retries,
      averageProgress: progress,
      averageSuccessRate: success,
      averageRisk: risk,
      score: score,
      recommendations: recommendations,
    );
  }
}
