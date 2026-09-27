import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';

class BeefHerdIndicators {
  const BeefHerdIndicators({
    required this.activeAnimals,
    required this.commercialExits,
    required this.offtakeRate,
    required this.commercialRevenue,
    required this.averageSaleValue,
    required this.averageSaleAgeMonths,
    required this.salesWithKnownAge,
    required this.salesWithoutKnownAge,
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
    this.ambiguousAnimalRecords = 0,
  });

  final int activeAnimals;
  final int commercialExits;

  /// Saídas comerciais datadas / rebanho exposto (ativo + saídas), em 12 meses.
  final double? offtakeRate;

  /// Soma dos valores positivos/finitos; nulo se ausentes ou não calculáveis.
  /// Zero é reservado à ausência de saídas comerciais datadas na janela.
  final double? commercialRevenue;
  final double? averageSaleValue;

  /// Idade média aproximada nas vendas datadas, em meses gregorianos médios.
  final double? averageSaleAgeMonths;
  final int salesWithKnownAge;
  final int salesWithoutKnownAge;
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
  final int ambiguousAnimalRecords;
  bool get commercialRevenueIsPartial =>
      commercialExitsWithValue > 0 &&
      commercialExitsWithValue < commercialExits;
  bool get hasUncalculableCommercialValues =>
      (commercialExitsWithValue > 0 && commercialRevenue == null) ||
      (commercialExitsWithValue > 0 && averageSaleValue == null) ||
      (salesWithWeightAndValue > 0 && averageSalePricePerKg == null);

  String? get primaryMortalityCause {
    if (mortalityByCause.isEmpty) return null;
    final entries = mortalityByCause.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  List<String> get dataQualityAlerts {
    final alerts = <String>[];
    if (ambiguousAnimalRecords > 0) {
      alerts.add(
        '$ambiguousAnimalRecords registro(s) de animais com identificação ausente/repetida ficaram fora dos indicadores.',
      );
    }
    if (hasUncalculableCommercialValues) {
      alerts.add(
        'Há valores comerciais fora do intervalo calculável; revise valores e pesos antes de usar os indicadores indisponíveis.',
      );
    }
    if (commercialExitsWithoutDate > 0) {
      alerts.add(
        '$commercialExitsWithoutDate venda(s) não têm data válida e ficaram fora dos indicadores de 12 meses.',
      );
    }
    if (salesWithoutValue > 0) {
      alerts.add(
        '$salesWithoutValue venda(s) datada(s) não têm valor de venda válido.',
      );
    }
    if (salesWithoutWeight > 0) {
      alerts.add(
        '$salesWithoutWeight venda(s) datada(s) não têm peso válido para calcular R\$/kg.',
      );
    }
    if (salesWithoutKnownAge > 0) {
      alerts.add(
        '$salesWithoutKnownAge venda(s) datada(s) não têm nascimento válido anterior à venda para calcular idade.',
      );
    }
    if (mortalitiesWithoutDate > 0) {
      alerts.add(
        '$mortalitiesWithoutDate óbito(s) não têm data válida e ficaram fora da taxa de mortalidade.',
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
    final ids = <String, int>{};
    for (final animal in animals) {
      ids.update(animal.id, (count) => count + 1, ifAbsent: () => 1);
    }
    final uniqueAnimals = animals
        .where((animal) => animal.id.trim().isNotEmpty && ids[animal.id] == 1)
        .toList();
    final active = uniqueAnimals
        .where((animal) => animal.status == 'Ativo')
        .length;
    final allSold = uniqueAnimals
        .where((animal) => animal.status == 'Vendido')
        .toList();
    final sold = allSold.where((animal) {
      final date = _date(animal.saleDate);
      return date != null && !date.isBefore(start) && !date.isAfter(now);
    }).toList();
    final exits = sold.length;
    final exposed = active + exits;
    final allDead = uniqueAnimals
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
    final salesWithValue = sold
        .where((animal) => animal.saleValue.isFinite && animal.saleValue > 0)
        .toList();
    final salesWithWeightAndValue = salesWithValue
        .where((animal) => animal.weight.isFinite && animal.weight > 0)
        .toList();
    final revenue = salesWithValue.fold<double>(
      0,
      (sum, animal) => sum + animal.saleValue,
    );
    final meanValueWithWeight = _finiteMean(
      salesWithWeightAndValue.map((animal) => animal.saleValue),
    );
    final meanSaleWeight = _finiteMean(
      salesWithWeightAndValue.map((animal) => animal.weight),
    );
    final pricePerKg =
        meanValueWithWeight == null ||
            meanSaleWeight == null ||
            meanSaleWeight <= 0
        ? null
        : meanValueWithWeight / meanSaleWeight;
    final saleAgesInDays = <int>[];
    for (final animal in sold) {
      final birthDate = _date(animal.birthDate);
      final saleDate = _date(animal.saleDate)!;
      if (birthDate == null || birthDate.isAfter(saleDate)) continue;
      final birthDay = DateTime.utc(
        birthDate.year,
        birthDate.month,
        birthDate.day,
      );
      final saleDay = DateTime.utc(saleDate.year, saleDate.month, saleDate.day);
      saleAgesInDays.add(saleDay.difference(birthDay).inDays);
    }
    return BeefHerdIndicators(
      activeAnimals: active,
      commercialExits: exits,
      offtakeRate: exposed == 0 ? null : exits / exposed * 100,
      commercialRevenue: exits == 0
          ? 0
          : salesWithValue.isEmpty || !revenue.isFinite
          ? null
          : revenue,
      averageSaleValue: _finiteMean(
        salesWithValue.map((animal) => animal.saleValue),
      ),
      averageSaleAgeMonths: saleAgesInDays.isEmpty
          ? null
          : saleAgesInDays.reduce((a, b) => a + b) /
                saleAgesInDays.length /
                30.4375,
      salesWithKnownAge: saleAgesInDays.length,
      salesWithoutKnownAge: exits - saleAgesInDays.length,
      commercialExitsWithValue: salesWithValue.length,
      salesWithWeightAndValue: salesWithWeightAndValue.length,
      commercialExitsWithoutDate: allSold
          .where((animal) => _date(animal.saleDate) == null)
          .length,
      salesWithoutValue: exits - salesWithValue.length,
      salesWithoutWeight: sold
          .where((animal) => !animal.weight.isFinite || animal.weight <= 0)
          .length,
      averageSalePricePerKg:
          pricePerKg != null && pricePerKg.isFinite && pricePerKg > 0
          ? pricePerKg
          : null,
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
      ambiguousAnimalRecords: animals.length - uniqueAnimals.length,
    );
  }

  double? _finiteMean(Iterable<double> source) {
    final values = source.toList();
    if (values.isEmpty) return null;
    final scale = values.reduce((a, b) => a > b ? a : b);
    final mean =
        scale *
        values.fold<double>(
          0,
          (sum, value) => sum + (value / scale) / values.length,
        );
    return mean.isFinite && mean > 0 ? mean : null;
  }

  DateTime? _date(String value) {
    final normalized = value.trim();
    final br = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(normalized);
    if (br != null) {
      return _strictDate(
        int.parse(br.group(3)!),
        int.parse(br.group(2)!),
        int.parse(br.group(1)!),
      );
    }

    final iso = RegExp(
      r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:T.*)?$',
    ).firstMatch(normalized);
    if (iso == null) return null;
    return _strictDate(
      int.parse(iso.group(1)!),
      int.parse(iso.group(2)!),
      int.parse(iso.group(3)!),
    );
  }

  DateTime? _strictDate(int year, int month, int day) {
    if (year < 1900 || month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  bool _isUnknownCause(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty || normalized == 'não informada';
  }
}
