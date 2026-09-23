import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('centraliza alertas técnicos de Leite e Corte no painel', () {
    final dashboard = File(
      'lib/features/technical_dashboard/presentation/screens/technical_dashboard_screen.dart',
    ).readAsStringSync();

    expect(dashboard, contains('_productionDataQualityAlerts'));
    expect(dashboard, contains('summary.dairyOperationalDataAlerts'));
    expect(dashboard, contains('summary.beefHerd.dataQualityAlerts'));
    expect(dashboard, contains('_beefOperationalDataAlerts'));
    expect(dashboard, contains('Cobertura de pesagens (90 dias)'));
    expect(dashboard, contains('Animais ativos sem pesagem recente'));
    expect(
      dashboard,
      contains('beefLatestWeightCoverage.unweighedAnimalCount'),
    );
    expect(dashboard, contains('analysis.beefLatestWeightCoverage.percent'));
    expect(dashboard, contains('beefLatestWeightCoverage.weighedAnimalCount'));
    expect(dashboard, contains('Base do ganho médio diário'));
    expect(dashboard, contains('Idade média na venda (12 meses)'));
    expect(dashboard, contains('Vendas com idade calculável'));
    expect(dashboard, contains('_beefLatestWeightAgeDays'));
    expect(dashboard, contains('Última pesagem de animal ativo'));
    expect(dashboard, contains('última pesagem foi há'));
    expect(dashboard, contains('_dairySnapshotAgeDays'));
    expect(dashboard, contains('Atualização do estado do lote'));
    expect(dashboard, contains('Dados técnicos para revisar — Leite'));
    expect(dashboard, contains('Dados técnicos para revisar — Corte'));
    expect(dashboard, contains('Itens que precisam de revisão'));
    expect(dashboard, contains('Base de pesos do rebanho ativo'));
    expect(dashboard, contains('summary.activeAnimalsWithValidWeight'));
    expect(dashboard, contains('Complete os pesos'));
    expect(dashboard, contains('Peso médio dos ativos com peso'));
    expect(dashboard, contains('Animais por hectare de área total'));
    expect(dashboard, contains('Peso vivo por hectare de área total'));
    expect(dashboard, contains('Área total usada nestes índices'));
    expect(dashboard, contains('não substituem a lotação da área de pastagem'));
    expect(
      dashboard,
      contains('Não representam a lotação da área de pastagem'),
    );
    expect(dashboard, contains('Animais para pesar'));
    expect(dashboard, contains('analysis.pendingWeighingAnimals'));
    expect(dashboard, contains('Última pesagem válida:'));
    expect(dashboard, contains('Toque para registrar pesagem'));
    expect(dashboard, contains('AnimalWeightListScreen('));
    expect(dashboard, contains('autoOpenCreate: true'));
    expect(dashboard, contains('group: pending.group'));
    expect(dashboard, contains('await onRefresh()'));
  });
}
