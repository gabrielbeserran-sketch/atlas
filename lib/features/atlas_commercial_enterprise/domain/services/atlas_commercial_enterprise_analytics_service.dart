import 'dart:math' as math;

import 'package:projeto_atlas/features/atlas_commercial_enterprise/domain/models/atlas_commercial_enterprise_record.dart';

class AtlasCommercialEnterpriseAnalytics {
  const AtlasCommercialEnterpriseAnalytics({
    required this.coveragePercent,
    required this.recordCount,
    required this.operationalCount,
    required this.alertCount,
    required this.totalPotentialValue,
    required this.totalActualValue,
    required this.averageProbability,
    required this.averageProgress,
    required this.averageSatisfaction,
    required this.score,
    required this.recommendations,
  });

  final double coveragePercent;
  final int recordCount;
  final int operationalCount;
  final int alertCount;
  final double totalPotentialValue;
  final double totalActualValue;
  final double averageProbability;
  final double averageProgress;
  final double averageSatisfaction;
  final int score;
  final List<String> recommendations;

  double get conversionPercent {
    if (totalPotentialValue == 0) return 0.0;
    return totalActualValue * 100 / totalPotentialValue.abs();
  }
}

class AtlasCommercialEnterpriseAnalyticsService {
  const AtlasCommercialEnterpriseAnalyticsService();

  AtlasCommercialEnterpriseAnalytics analyze({
    required AtlasCommercialEnterpriseModule module,
    required List<AtlasCommercialEnterpriseRecord> records,
  }) {
    final moduleRecords = records
        .where((record) => record.module == module)
        .toList(growable: false);

    final represented = moduleRecords
        .map((record) => record.feature)
        .where((feature) => feature.trim().isNotEmpty)
        .toSet();

    final coverage = module.features.isEmpty
        ? 0.0
        : represented.length * 100.0 / module.features.length;

    final operational = moduleRecords
        .where((record) => record.isOperational)
        .length;

    final alerts = moduleRecords.fold<int>(
      0,
      (total, record) =>
          total +
          record.alertCount +
          (record.isCritical ? 1 : 0) +
          (record.isOverdue ? 1 : 0),
    );

    double averageOf(
      double Function(AtlasCommercialEnterpriseRecord) selector,
    ) {
      if (moduleRecords.isEmpty) return 0.0;
      return moduleRecords
              .map(selector)
              .reduce((a, b) => a + b) /
          moduleRecords.length;
    }

    final totalPotentialValue = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.potentialValue,
    );

    final totalActualValue = moduleRecords.fold<double>(
      0.0,
      (total, record) => total + record.actualValue,
    );

    final averageProbability =
        averageOf((record) => record.probabilityPercent);
    final averageProgress =
        averageOf((record) => record.progressPercent.toDouble());
    final averageSatisfaction =
        averageOf((record) => record.satisfactionPercent);

    var score = 30;
    score += math.min(25, coverage.round() * 25 ~/ 100);
    score += math.min(20, operational * 4);
    score += math.min(
      15,
      averageProbability.round() * 15 ~/ 100,
    );
    score += math.min(10, averageProgress.round() ~/ 10);
    score += math.min(
      10,
      averageSatisfaction.round() * 10 ~/ 100,
    );
    score -= math.min(35, alerts * 5);
    score = score.clamp(0, 100).toInt();

    return AtlasCommercialEnterpriseAnalytics(
      coveragePercent: coverage,
      recordCount: moduleRecords.length,
      operationalCount: operational,
      alertCount: alerts,
      totalPotentialValue: totalPotentialValue,
      totalActualValue: totalActualValue,
      averageProbability: averageProbability,
      averageProgress: averageProgress,
      averageSatisfaction: averageSatisfaction,
      score: score,
      recommendations: _recommendations(
        module: module,
        records: moduleRecords,
        represented: represented,
        alerts: alerts,
      ),
    );
  }

  List<String> _recommendations({
    required AtlasCommercialEnterpriseModule module,
    required List<AtlasCommercialEnterpriseRecord> records,
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
        'Existem $alerts alertas, prazos vencidos ou registros críticos; revise responsáveis e próximas ações.',
      );
    }

    if (records.isEmpty) {
      items.add(
        'Cadastre o primeiro registro do ${module.packageLabel}.',
      );
      return items;
    }

    items.addAll(
      switch (module) {
        AtlasCommercialEnterpriseModule.premiumCrm =>
          const [
            'Registre toda interação relevante e mantenha a próxima ação atualizada.',
            'Segmente clientes por perfil, potencial e relacionamento.',
          ],
        AtlasCommercialEnterpriseModule.intelligentPipeline =>
          const [
            'Revise probabilidade e valor em cada mudança de etapa.',
            'Evite oportunidades sem responsável, prazo ou próxima ação.',
          ],
        AtlasCommercialEnterpriseModule.digitalContracts =>
          const [
            'Controle versões, aprovações, vigência e condições principais.',
            'Nunca substitua revisão jurídica por automação.',
          ],
        AtlasCommercialEnterpriseModule.electronicSignature =>
          const [
            'Registre signatários, ordem, evidências e conclusão.',
            'Use provedor homologado para validade jurídica real.',
          ],
        AtlasCommercialEnterpriseModule.customerManagement =>
          const [
            'Mantenha dados, documentos e classificação atualizados.',
            'Restrinja acesso a informações pessoais e financeiras.',
          ],
        AtlasCommercialEnterpriseModule.afterSales =>
          const [
            'Acompanhe satisfação, solicitações e oportunidades de renovação.',
            'Feche o ciclo entre promessa comercial e entrega real.',
          ],
        AtlasCommercialEnterpriseModule.commercialIndicators =>
          const [
            'Padronize período, fonte e fórmula de cada indicador.',
            'Compare previsão, realizado, conversão e ciclo de vendas.',
          ],
        AtlasCommercialEnterpriseModule.servicesMarketplace =>
          const [
            'Valide escopo, proposta, contratado e avaliação.',
            'Mantenha regras de reputação, disputa e cancelamento.',
          ],
        AtlasCommercialEnterpriseModule.auctions =>
          const [
            'Registre lotes, lances, arremates e liquidação com auditoria.',
            'Use integrações seguras para pagamentos e documentos.',
          ],
        AtlasCommercialEnterpriseModule.commercialCenter =>
          const [
            'Centralize pipeline, contratos, alertas e receita.',
            'Priorize oportunidades por valor, chance, prazo e risco.',
          ],
      },
    );

    return items;
  }
}
