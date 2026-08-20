import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Dashboard inclui Agenda Inteligente e indicadores executivos', () {
    final screen = File(
      'lib/features/dashboard/presentation/screens/dashboard_screen.dart',
    ).readAsStringSync();
    final service = File(
      'lib/features/farm_agenda/data/services/'
      'farm_agenda_storage_service.dart',
    ).readAsStringSync();
    final model = File(
      'lib/features/dashboard/domain/models/'
      'atlas_operational_intelligence_data.dart',
    ).readAsStringSync();

    expect(screen.contains('reconcileSmartAgenda'), isTrue);
    expect(screen.contains('ExecutiveIndicatorsCard'), isTrue);
    expect(
      service.contains('/livestock/intelligence/smart-agenda/reconcile'),
      isTrue,
    );
    expect(model.contains('pregnancyRatePercent'), isTrue);
    expect(model.contains('averageGmdKgDay'), isTrue);
    expect(model.contains('nutritionMonthlyCost'), isTrue);
  });
}
