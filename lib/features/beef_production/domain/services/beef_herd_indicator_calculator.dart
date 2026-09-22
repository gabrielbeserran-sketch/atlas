import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';

class BeefHerdIndicators {
  const BeefHerdIndicators({
    required this.activeAnimals,
    required this.commercialExits,
    required this.offtakeRate,
    required this.commercialRevenue,
    required this.averageSaleValue,
    required this.commercialExitsWithValue,
    required this.salesWithWeightAndValue,
    required this.commercialExitsWithoutDate,
    required this.salesWithoutValue,
    required this.salesWithoutWeight,
    required this.averageSalePricePerKg,
    required this.mortalities,
    required this.mortalitiesWithoutDate,
    required this.mortalitiesWithoutCause,
    required this.mortalityRate,
    required this.mortalityByCause,
  });

  final int activeAnimals;
  final int commercialExits;

  /// Saídas comerciais datadas / rebanho exposto (ativo + saídas), em 12 meses.
  final double? offtakeRate;
  final double commercialRevenue;
  final double? averageSaleValue;
  final int commercialExitsWithValue;
  final int salesWithWeightAndValue;
  final int commercialExitsWithoutDate;
  final int salesWithoutValue;
  final int salesWithoutWeight;
  final double? averageSalePricePerKg;
  final int mortalities;
  final int mortalitiesWithoutDate;
  final int mortalitiesWithoutCause;
  final double? mortalityRate;
  final Map<String, int> mortalityByCause;

  String? get primaryMortalityCause {
    if (mortalityByCause.isEmpty) return null;
    final entries = mortalityByCause.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  List<String> get dataQualityAlerts {
    final alerts = <String>[];
    if (commercialExitsWithoutDate > 0) {
      alerts.add(
        '$commercialExitsWithoutDate venda(s) não têm data e ficaram fora dos indicadores de 12 meses.',
      );
    }
    if (salesWithoutValue > 0) {
      alerts.add(
        '$salesWithoutValue venda(s) datada(s) não têm valor de venda.',
      );
    }
    if (salesWithoutWeight > 0) {
      alerts.add(
        '$salesWithoutWeight venda(s) datada(s) não têm peso para calcular R\$/kg.',
      );
    }
    if (mortalitiesWithoutDate > 0) {
      alerts.add(
        '$mortalitiesWithoutDate óbito(s) não têm data e ficaram fora da taxa de mortalidade.',
      );
    }
    if (mortalitiesWithoutCause > 0) {
      alerts.add(
        '$mortalitiesWithoutCause óbito(s) datado(s) não têm causa informada.',
      );
    }
    return alerts;
  }
}

class BeefHerdIndicatorCalculator {
  const BeefHerdIndicatorCalculator();

  BeefHerdIndicators calculate({
    required List<AnimalData> animals,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final start = DateTime(now.year - 1, now.month, now.day);
    final active = animals.where((animal) => animal.status == 'Ativo').length;
    final allSold = animals
        .where((animal) => animal.status == 'Vendido')
        .toList();
    final sold = allSold.where((animal) {
      final date = _date(animal.saleDate);
      return date != null && !date.isBefore(start) && !date.isAfter(now);
    }).toList();
    final exits = sold.length;
    final exposed = active + exits;
    final allDead = animals
        .where((animal) => animal.status == 'Morto')
        .toList();
    final deadAnimals = allDead.where((animal) {
      final date = _date(animal.deathDate);
      return date != null && !date.isBefore(start) && !date.isAfter(now);
    }).toList();
    final mortalities = deadAnimals.length;
    final mortalityByCause = <String, int>{};
    for (final animal in deadAnimals) {
      final cause = animal.deathCause.trim().isEmpty
          ? 'Não informada'
          : animal.deathCause;
      mortalityByCause[cause] = (mortalityByCause[cause] ?? 0) + 1;
    }
    final mortalityExposed = active + mortalities;
    final revenue = sold.fold<double>(
      0,
      (sum, animal) => sum + animal.saleValue,
    );
    final salesWithValue = sold
        .where((animal) => animal.saleValue > 0)
        .toList();
    final salesWithWeightAndValue = salesWithValue
        .where((animal) => animal.weight > 0)
        .toList();
    final totalSaleValueWithWeight = salesWithWeightAndValue.fold<double>(
      0,
      (sum, animal) => sum + animal.saleValue,
    );
    final totalSaleWeight = salesWithWeightAndValue.fold<double>(
      0,
      (sum, animal) => sum + animal.weight,
    );
    return BeefHerdIndicators(
      activeAnimals: active,
      commercialExits: exits,
      offtakeRate: exposed == 0 ? null : exits / exposed * 100,
      commercialRevenue: revenue,
      averageSaleValue: salesWithValue.isEmpty
          ? null
          : salesWithValue.fold<double>(
                  0,
                  (sum, animal) => sum + animal.saleValue,
                ) /
                salesWithValue.length,
      commercialExitsWithValue: salesWithValue.length,
      salesWithWeightAndValue: salesWithWeightAndValue.length,
      commercialExitsWithoutDate: allSold
          .where((animal) => _date(animal.saleDate) == null)
          .length,
      salesWithoutValue: sold.where((animal) => animal.saleValue <= 0).length,
      salesWithoutWeight: sold.where((animal) => animal.weight <= 0).length,
      averageSalePricePerKg: totalSaleWeight == 0
          ? null
          : totalSaleValueWithWeight / totalSaleWeight,
      mortalities: mortalities,
      mortalitiesWithoutDate: allDead
          .where((animal) => _date(animal.deathDate) == null)
          .length,
      mortalitiesWithoutCause: deadAnimals
          .where((animal) => _isUnknownCause(animal.deathCause))
          .length,
      mortalityRate: mortalityExposed == 0
          ? null
          : mortalities / mortalityExposed * 100,
      mortalityByCause: mortalityByCause,
    );
  }

  DateTime? _date(String value) {
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    return day == null || month == null || year == null
        ? null
        : DateTime(year, month, day);
  }

  bool _isUnknownCause(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty || normalized == 'não informada';
  }
}
