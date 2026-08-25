import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('10B usa fonte unica e preserva posição das prioridades', () {
    final service = File(
      'lib/features/dashboard/data/services/atlas_operational_intelligence_service.dart',
    ).readAsStringSync();
    final model = File(
      'lib/features/dashboard/domain/models/atlas_operational_intelligence_data.dart',
    ).readAsStringSync();
    final backend = File(
      'backend/app/routers/livestock.py',
    ).readAsStringSync();
    final dashboard = File(
      'lib/features/dashboard/presentation/screens/dashboard_screen.dart',
    ).readAsStringSync();
    final alerts = File(
      'lib/features/dashboard/presentation/screens/operational_alert_center_screen.dart',
    ).readAsStringSync();
    final consultancy = File(
      'lib/features/consultancy_client/presentation/screens/atlas_client_consultancy_center_screen.dart',
    ).readAsStringSync();

    expect(service.contains('/livestock/intelligence/operational-summary'), isTrue);
    expect(service.contains('/livestock/intelligence/operational-alerts'), isTrue);
    expect(service.contains('summaryFarmId != farmId || alertsFarmId != farmId'), isTrue);
    expect(service.contains('summaryContract != alertsContract'), isTrue);
    expect(model.contains("map['position'] ?? map['priority']"), isTrue);
    expect(backend.contains('"position": index + 1'), isTrue);
    expect(backend.contains('"contract_version": "10B"'), isTrue);
    expect(dashboard.contains('AtlasOperationalIntelligenceService'), isTrue);
    expect(alerts.contains('AtlasOperationalIntelligenceService'), isTrue);
    expect(consultancy.contains('AtlasOperationalIntelligenceService'), isTrue);
  });
}
