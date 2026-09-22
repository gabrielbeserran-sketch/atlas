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
    expect(service, contains('latestMeasurementDate: monthEntries.last.date'));
    expect(service, contains('!item.date.isAfter(referenceDate)'));
  });
}
