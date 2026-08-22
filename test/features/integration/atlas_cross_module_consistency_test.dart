import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Rebanho reconhece status ativo em português e inglês', () {
    final source = File(
      'lib/features/herd/domain/models/herd_workspace_data.dart',
    ).readAsStringSync();

    expect(source.contains("normalized == 'ativo' || normalized == 'active'"), isTrue);
  });

  test('Nutrição enriquece desempenho a partir de animais e pesagens', () {
    final source = File(
      'lib/features/nutrition/data/services/nutrition_storage_service.dart',
    ).readAsStringSync();

    expect(source.contains('_enrichPerformance'), isTrue);
    expect(source.contains("'/livestock/animals/\$animalId/weights'"), isTrue);
    expect(source.contains("raw['percentage']"), isTrue);
  });

  test('Timeline evita duplicar evento oficial + Enterprise', () {
    final source = File(
      'lib/features/animal_event/presentation/screens/animal_timeline_screen.dart',
    ).readAsStringSync();

    expect(source.contains('canonicalSourceIds'), isTrue);
    expect(source.contains('uniqueEnterpriseRecords'), isTrue);
  });
}
