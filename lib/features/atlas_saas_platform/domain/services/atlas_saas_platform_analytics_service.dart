import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_saas_platform/domain/models/atlas_saas_platform_record.dart';

class AtlasSaasPlatformAnalytics {
  const AtlasSaasPlatformAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.pendingCount,
    required this.alertCount,
    required this.totalAmount,
    required this.totalQuantity,
    required this.averageUsage,
    required this.averageProgress,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int pendingCount;
  final int alertCount;
  final double totalAmount;
  final int totalQuantity;
  final double averageUsage;
  final double averageProgress;
  final int score;
  final List<String> recommendations;
}

class AtlasSaasPlatformAnalyticsService {
  const AtlasSaasPlatformAnalyticsService();

  AtlasSaasPlatformAnalytics analyze({
    required AtlasSaasPlatformModule module,
    required List<AtlasSaasPlatformRecord> records,
  }) {
    final moduleRecords = records
        .where((record) => record.module == module)
        .toList(growable: false);

    final represented = moduleRecords
        .map((record) => record.feature)
        .where((feature) => feature.trim().isNotEmpty)
        .toSet();

    final double coveragePercent = module.features.isEmpty
        ? 0.0
        : represented.length * 100.0 / module.features.length;

    final operationalCount = moduleRecords
        .where((record) => record.isOperational)
        .length;

    final pendingCount = moduleRecords.where((record) {
      return !record.isOperational && !record.isCritical;
    }).length;

    final alertCount = moduleRecords.fold<int>(
      0,
      (total, record) =>
          total +
          record.alertCount +
          (record.isCritical ? 1 : 0) +
          (record.isOverdue ? 1 : 0),
    );

    final totalAmount = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.amount,
    );

    final totalQuantity = moduleRecords.fold<int>(
      0,
      (total, record) => total + record.quantity,
    );

    final double averageUsage = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                  .map((record) => record.usagePercent)
                  .reduce((a, b) => a + b) /
              moduleRecords.length;

    final double averageProgress = moduleRecords.isEmpty
        ? 0.0
        : moduleRecords
                  .map((record) => record.progressPercent)
                  .reduce((a, b) => a + b) /
              moduleRecords.length;

    var score = 30;
    score += math.min(30, coveragePercent.round() * 30 ~/ 100);
    score += math.min(25, operationalCount * 5);
    score += math.min(10, averageProgress.round() ~/ 10);
    score -= math.min(40, alertCount * 6);
    score = score.clamp(0, 100).toInt();

    return AtlasSaasPlatformAnalytics(
      coveragePercent: coveragePercent,
      recordCount: moduleRecords.length,
      operationalCount: operationalCount,
      pendingCount: pendingCount,
      alertCount: alertCount,
      totalAmount: totalAmount,
      totalQuantity: totalQuantity,
      averageUsage: averageUsage,
      averageProgress: averageProgress,
      score: score,
      recommendations: _recommendations(
        module: module,
        records: moduleRecords,
        represented: represented,
        alerts: alertCount,
      ),
    );
  }

  List<String> _recommendations({
    required AtlasSaasPlatformModule module,
    required List<AtlasSaasPlatformRecord> records,
    required Set<String> represented,
    required int alerts,
  }) {
    final items = <String>[];

    for (final feature in module.features) {
      if (!represented.contains(feature)) {
        items.add('Implantar ou registrar: $feature.');
      }
    }

    if (alerts > 0) {
      items.add(
        'Existem $alerts alertas, vencimentos ou bloqueios; revise responsáveis e prazos.',
      );
    }

    if (records.isEmpty) {
      items.add('Cadastre o primeiro registro do ${module.packageLabel}.');
    } else {
      items.addAll(switch (module) {
        AtlasSaasPlatformModule.accessControl => const [
          'Aplique menor privilégio e revise permissões periodicamente.',
          'Registre alterações de acesso e encerre sessões suspeitas.',
        ],
        AtlasSaasPlatformModule.multiCompany => const [
          'Isole dados e configurações por empresa.',
          'Defina administradores e regras de consolidação.',
        ],
        AtlasSaasPlatformModule.multiFarm => const [
          'Associe cada usuário apenas às fazendas autorizadas.',
          'Padronize indicadores antes de comparar propriedades.',
        ],
        AtlasSaasPlatformModule.subscriptions => const [
          'Defina claramente limites, benefícios e regras de renovação.',
          'Mantenha histórico de mudanças de plano.',
        ],
        AtlasSaasPlatformModule.billing => const [
          'Concilie faturas, recebimentos e inadimplência.',
          'Automatize lembretes sem perder a revisão financeira.',
        ],
        AtlasSaasPlatformModule.pixPayments => const [
          'Valide valor, recebedor e identificador antes da cobrança.',
          'Mantenha conciliação e devoluções auditáveis.',
        ],
        AtlasSaasPlatformModule.cardPayments => const [
          'Nunca armazene dados sensíveis de cartão diretamente.',
          'Trate estornos e chargebacks com trilha de auditoria.',
        ],
        AtlasSaasPlatformModule.licensing => const [
          'Acompanhe expiração, consumo e exceções de uso.',
          'Evite bloqueios inesperados com alertas antecipados.',
        ],
        AtlasSaasPlatformModule.consultantMarketplace => const [
          'Valide identidade, especialidade e reputação dos consultores.',
          'Registre escopo, proposta, aceite e avaliação.',
        ],
        AtlasSaasPlatformModule.producerPortal => const [
          'Mostre apenas dados autorizados ao produtor.',
          'Centralize documentos, solicitações e indicadores compartilhados.',
        ],
      });
    }

    return items;
  }
}
