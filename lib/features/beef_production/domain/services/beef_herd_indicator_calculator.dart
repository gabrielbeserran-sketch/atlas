import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';

class BeefHerdIndicators {
  const BeefHerdIndicators({
    required this.activeAnimals,
    required this.commercialExits,
    required this.offtakeRate,
    required this.commercialRevenue,
    required this.averageSaleValue,
  });

  final int activeAnimals;
  final int commercialExits;

  /// Saídas comerciais datadas / rebanho exposto (ativo + saídas), em 12 meses.
  final double? offtakeRate;
  final double commercialRevenue;
  final double? averageSaleValue;
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
    final sold = animals.where((animal) {
      if (animal.status != 'Vendido') return false;
      final date = _date(animal.saleDate);
      return date != null && !date.isBefore(start) && !date.isAfter(now);
    }).toList();
    final exits = sold.length;
    final exposed = active + exits;
    final revenue = sold.fold<double>(
      0,
      (sum, animal) => sum + animal.saleValue,
    );
    final salesWithValue = sold
        .where((animal) => animal.saleValue > 0)
        .toList();
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
}
