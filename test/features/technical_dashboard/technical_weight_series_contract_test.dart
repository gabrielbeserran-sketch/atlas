import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a série de pesagens preserva a data real da última medição', () {
    final point = File(
      'lib/features/technical_dashboard/domain/models/technical_weight_series_point.dart',
    ).readAsStringSync();
    final service = File(
      'lib/features/technical_dashboard/domain/services/technical_dashboard_service.dart',
    ).readAsStringSync();

    expect(point, contains('latestMeasurementDate'));
    final calculator = File(
      'lib/features/technical_dashboard/domain/services/technical_weight_monthly_point_calculator.dart',
    ).readAsStringSync();
    final dashboard = File(
      'lib/features/technical_dashboard/presentation/screens/technical_dashboard_screen.dart',
    ).readAsStringSync();

    expect(service, contains('TechnicalWeightMonthlyPointCalculator'));
    expect(calculator, contains('latestMeasurementDate: latestDate!'));
    expect(calculator, contains('day.isAfter(today)'));
    expect(
      dashboard,
      contains('_WeightEvolutionCard(points: analysis.weightSeries)'),
    );
    expect(dashboard, contains('Evolução do peso por animal'));
    expect(dashboard, contains('point.animalCount'));
  });
}
