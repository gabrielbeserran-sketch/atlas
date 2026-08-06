import 'dart:convert';

import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_economic_intelligence_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_financial_models.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_financial_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasEconomicIntelligenceService {
  AtlasEconomicIntelligenceService._();

  static final AtlasEconomicIntelligenceService instance =
      AtlasEconomicIntelligenceService._();

  static const String _metricsKey =
      'atlas_economic_production_metrics_v1';
  static const String _scenariosKey =
      'atlas_economic_investment_scenarios_v1';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<List<AtlasEconomicProductionMetric>> loadMetrics({
    String? farmName,
  }) async {
    final values = await _decodeList(
      _metricsKey,
      AtlasEconomicProductionMetric.fromMap,
    );
    final filtered = _filterFarm(
      values,
      farmName,
      (item) => item.farmName,
    )..sort(
        (first, second) =>
            second.periodEnd.compareTo(first.periodEnd),
      );
    return filtered;
  }

  Future<void> saveMetric(
    AtlasEconomicProductionMetric metric,
  ) async {
    final values = await _decodeList(
      _metricsKey,
      AtlasEconomicProductionMetric.fromMap,
    );
    _upsert(values, metric, (item) => item.id);
    await _saveList(
      _metricsKey,
      values.map((item) => item.toMap()).toList(),
    );
  }

  Future<List<AtlasEconomicInvestmentScenario>>
      loadScenarios({
    String? farmName,
  }) async {
    final values = await _decodeList(
      _scenariosKey,
      AtlasEconomicInvestmentScenario.fromMap,
    );
    return _filterFarm(
      values,
      farmName,
      (item) => item.farmName,
    );
  }

  Future<void> saveScenario(
    AtlasEconomicInvestmentScenario scenario,
  ) async {
    final values = await _decodeList(
      _scenariosKey,
      AtlasEconomicInvestmentScenario.fromMap,
    );
    _upsert(values, scenario, (item) => item.id);
    await _saveList(
      _scenariosKey,
      values.map((item) => item.toMap()).toList(),
    );
  }

  Future<AtlasEconomicSnapshot> buildSnapshot({
    required String? farmName,
    required List<AtlasEconomicProductionMetric> metrics,
  }) async {
    final transactions =
        await AtlasFinancialService.instance.loadTransactions(
      farmName: farmName,
    );

    final settledIncome = transactions
        .where(
          (item) =>
              item.type ==
                  AtlasFinancialTransactionType.income &&
              item.isSettled,
        )
        .fold<double>(
          0,
          (total, item) => total + item.amount,
        );

    final settledExpense = transactions
        .where(
          (item) =>
              item.type ==
                  AtlasFinancialTransactionType.expense &&
              item.isSettled,
        )
        .fold<double>(
          0,
          (total, item) => total + item.amount,
        );

    final productionRevenue = metrics.fold<double>(
      0,
      (total, item) => total + item.revenue,
    );
    final variableCosts = metrics.fold<double>(
      0,
      (total, item) => total + item.variableCost,
    );
    final fixedCosts = metrics.fold<double>(
      0,
      (total, item) => total + item.fixedCost,
    );

    final revenue = settledIncome + productionRevenue;
    final totalExpense =
        settledExpense + variableCosts + fixedCosts;
    final ebitda = revenue - variableCosts - fixedCosts;
    final netResult = revenue - totalExpense;
    final margin =
        revenue <= 0 ? 0.0 : netResult / revenue * 100;
    final investedCapital = metrics.fold<double>(
      0,
      (total, item) => total + item.totalCost,
    );
    final roi = investedCapital <= 0
        ? 0.0
        : netResult / investedCapital * 100;

    final payable = transactions
        .where(
          (item) =>
              item.type ==
                  AtlasFinancialTransactionType.expense &&
              !item.isSettled &&
              item.status !=
                  AtlasFinancialTransactionStatus.cancelled,
        )
        .fold<double>(
          0,
          (total, item) => total + item.amount,
        );

    final receivable = transactions
        .where(
          (item) =>
              item.type ==
                  AtlasFinancialTransactionType.income &&
              !item.isSettled &&
              item.status !=
                  AtlasFinancialTransactionStatus.cancelled,
        )
        .fold<double>(
          0,
          (total, item) => total + item.amount,
        );

    final liquidity =
        payable <= 0 ? receivable : receivable / payable;

    return AtlasEconomicSnapshot(
      revenue: revenue,
      variableCosts: variableCosts,
      fixedCosts: fixedCosts,
      ebitda: ebitda,
      netResult: netResult,
      operatingMarginPercent: margin,
      roiPercent: roi,
      liquidity: liquidity,
      projectedBalance30Days:
          _projectCashFlow(transactions, 30),
      projectedBalance90Days:
          _projectCashFlow(transactions, 90),
      projectedBalance365Days:
          _projectCashFlow(transactions, 365),
      financialScore: _score(
        margin: margin,
        roi: roi,
        liquidity: liquidity,
        netResult: netResult,
      ),
    );
  }

  double _projectCashFlow(
    List<AtlasFinancialTransaction> transactions,
    int days,
  ) {
    final limit = DateTime.now().add(Duration(days: days));
    return transactions.where((item) {
      return item.dueAt.isBefore(limit) &&
          item.status !=
              AtlasFinancialTransactionStatus.cancelled;
    }).fold<double>(
      0,
      (total, item) =>
          total +
          (item.type == AtlasFinancialTransactionType.income
              ? item.amount
              : -item.amount),
    );
  }

  double _score({
    required double margin,
    required double roi,
    required double liquidity,
    required double netResult,
  }) {
    var score = 50.0;
    score += margin.clamp(-20, 25);
    score += (roi / 2).clamp(-15, 20);
    score += ((liquidity - 1) * 10).clamp(-15, 15);
    if (netResult > 0) {
      score += 10;
    } else if (netResult < 0) {
      score -= 10;
    }
    return score.clamp(0, 100);
  }

  List<String> buildRecommendations({
    required AtlasEconomicSnapshot snapshot,
    required List<AtlasEconomicProductionMetric> metrics,
  }) {
    final recommendations = <String>[];

    if (snapshot.netResult < 0) {
      recommendations.add(
        'O resultado líquido está negativo. Priorize cortes em custos variáveis e renegociação de despesas.',
      );
    }
    if (snapshot.operatingMarginPercent < 10) {
      recommendations.add(
        'A margem operacional está abaixo de 10%. Reavalie preços, produtividade e centros de custo.',
      );
    }
    if (snapshot.liquidity < 1) {
      recommendations.add(
        'A liquidez está abaixo de 1. Reforce caixa e reprograme compromissos de curto prazo.',
      );
    }

    final inefficient = metrics.where(
      (item) => item.marginPercent < 0,
    );
    for (final item in inefficient) {
      recommendations.add(
        '${atlasEconomicActivityLabel(item.activity)} apresenta margem negativa no período analisado.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'A estrutura econômica está equilibrada. Preserve controle de custos e acompanhe as projeções.',
      );
    }
    return recommendations;
  }

  Map<AtlasEconomicActivity, double> profitabilityByActivity(
    List<AtlasEconomicProductionMetric> metrics,
  ) {
    final values = <AtlasEconomicActivity, double>{};
    for (final item in metrics) {
      values[item.activity] =
          (values[item.activity] ?? 0) + item.operatingResult;
    }
    return values;
  }

  Future<List<T>> _decodeList<T>(
    String key,
    T Function(Map<String, dynamic>) fromMap,
  ) async {
    final encoded = await _preferences.getString(key);
    if (encoded == null || encoded.trim().isEmpty) {
      return <T>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;
      return decoded
          .map(
            (item) => fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <T>[];
    }
  }

  Future<void> _saveList(
    String key,
    List<Map<String, dynamic>> values,
  ) {
    return _preferences.setString(key, jsonEncode(values));
  }

  void _upsert<T>(
    List<T> values,
    T value,
    String Function(T) readId,
  ) {
    final index = values.indexWhere(
      (item) => readId(item) == readId(value),
    );
    if (index == -1) {
      values.add(value);
    } else {
      values[index] = value;
    }
  }

  List<T> _filterFarm<T>(
    List<T> values,
    String? farmName,
    String? Function(T) readFarm,
  ) {
    final normalized = farmName?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return values;
    }
    return values.where((value) {
      return readFarm(value)?.trim().toLowerCase() ==
          normalized;
    }).toList();
  }
}
