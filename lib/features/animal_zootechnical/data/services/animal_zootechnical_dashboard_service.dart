import 'dart:math' as math;

import 'package:projeto_atlas/features/animal/data/services/animal_enterprise_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_weight/data/services/animal_weight_storage_service.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:projeto_atlas/features/animal_zootechnical/domain/models/animal_zootechnical_dashboard_data.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class AnimalZootechnicalDashboardService {
  AnimalZootechnicalDashboardService({
    AnimalEnterpriseService? enterprise,
    AnimalWeightStorageService? weightStorage,
  })  : _enterprise = enterprise ?? AnimalEnterpriseService(),
        _weightStorage = weightStorage ?? AnimalWeightStorageService();

  final AnimalEnterpriseService _enterprise;
  final AnimalWeightStorageService _weightStorage;

  Future<AnimalZootechnicalDashboardData> build({
    required AnimalData animal,
    required FarmData farm,
    required HerdGroupData group,
  }) async {
    final weights = await _weightStorage.loadWeights(
      farmName: farm.name,
      groupName: group.name,
      animalId: animal.id,
    );

    weights.sort(
      (first, second) =>
          _parseDate(first.date).compareTo(_parseDate(second.date)),
    );

    final currentWeight =
        weights.isNotEmpty ? weights.last.weight : animal.weight;

    final previousWeight =
        weights.length >= 2 ? weights[weights.length - 2].weight : null;

    final weightVariation = previousWeight == null
        ? null
        : currentWeight - previousWeight;

    final averageDailyGain = _calculateAverageDailyGain(weights);

    final groupAnimals = await _enterprise.listAnimals(
      farmId: farm.id?.trim() ?? '',
      lotId: group.id,
    );

    final groupWeights = groupAnimals
        .map((item) => item.id == animal.id ? currentWeight : item.weight)
        .where((value) => value > 0)
        .toList(growable: false);

    final average = groupWeights.isEmpty
        ? currentWeight
        : groupWeights.reduce((a, b) => a + b) / groupWeights.length;

    final sortedWeights = [...groupWeights]..sort();
    final median = _median(sortedWeights);

    final rankedAnimals = groupAnimals
        .map(
          (item) => (
            id: item.id,
            weight: item.id == animal.id ? currentWeight : item.weight,
          ),
        )
        .where((item) => item.weight > 0)
        .toList();

    rankedAnimals.sort(
      (first, second) => second.weight.compareTo(first.weight),
    );

    final rankIndex = rankedAnimals.indexWhere(
      (item) => item.id == animal.id,
    );
    final rank = rankIndex == -1 ? 0 : rankIndex + 1;
    final groupSize = rankedAnimals.length;

    final percentile = groupSize <= 1 || rank <= 0
        ? 0.0
        : ((groupSize - rank) / (groupSize - 1)) * 100.0;

    return AnimalZootechnicalDashboardData(
      currentWeight: currentWeight,
      previousWeight: previousWeight,
      weightVariation: weightVariation,
      averageDailyGain: averageDailyGain,
      projectedWeight30Days: _project(
        currentWeight,
        averageDailyGain,
        30,
      ),
      projectedWeight60Days: _project(
        currentWeight,
        averageDailyGain,
        60,
      ),
      projectedWeight90Days: _project(
        currentWeight,
        averageDailyGain,
        90,
      ),
      groupAverageWeight: average,
      groupMedianWeight: median,
      groupRank: rank,
      groupSize: groupSize,
      percentile: percentile,
      weightHistory: List.unmodifiable(weights),
      trend: _trend(weights, averageDailyGain),
      consistencyScore: _consistency(weights),
      dataQuality: _dataQuality(weights),
    );
  }

  double? _calculateAverageDailyGain(
    List<AnimalWeightData> weights,
  ) {
    if (weights.length < 2) return null;

    final first = weights.first;
    final last = weights.last;
    final days =
        _parseDate(last.date).difference(_parseDate(first.date)).inDays;

    if (days <= 0) return null;
    return (last.weight - first.weight) / days;
  }

  double? _project(
    double currentWeight,
    double? dailyGain,
    int days,
  ) {
    if (dailyGain == null) return null;
    return math.max(0, currentWeight + dailyGain * days);
  }

  double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final middle = values.length ~/ 2;

    if (values.length.isOdd) return values[middle];

    return (values[middle - 1] + values[middle]) / 2;
  }

  String _trend(
    List<AnimalWeightData> weights,
    double? dailyGain,
  ) {
    if (weights.length < 2 || dailyGain == null) {
      return 'Dados insuficientes';
    }

    if (dailyGain > 0.20) return 'Ganho acelerado';
    if (dailyGain > 0.05) return 'Ganho positivo';
    if (dailyGain >= -0.05) return 'Estável';
    return 'Perda de peso';
  }

  double _consistency(List<AnimalWeightData> weights) {
    if (weights.length < 3) return 0;

    final gains = <double>[];

    for (var index = 1; index < weights.length; index++) {
      final previous = weights[index - 1];
      final current = weights[index];
      final days = _parseDate(current.date)
          .difference(_parseDate(previous.date))
          .inDays;

      if (days > 0) {
        gains.add((current.weight - previous.weight) / days);
      }
    }

    if (gains.length < 2) return 50;

    final mean = gains.reduce((a, b) => a + b) / gains.length;
    final variance = gains
            .map((value) => math.pow(value - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        gains.length;
    final deviation = math.sqrt(variance);

    return (100 - deviation * 100).clamp(0, 100).toDouble();
  }

  String _dataQuality(List<AnimalWeightData> weights) {
    if (weights.isEmpty) return 'Baixa';
    if (weights.length == 1) return 'Básica';
    if (weights.length < 4) return 'Intermediária';
    return 'Boa';
  }

  DateTime _parseDate(String value) {
    final normalized = value.trim();
    final iso = DateTime.tryParse(normalized);
    if (iso != null) return iso;

    final parts = normalized.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return DateTime(1900);
  }
}
