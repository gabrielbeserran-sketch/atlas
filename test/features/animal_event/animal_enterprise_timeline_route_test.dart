import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Timeline Enterprise usa o domínio oficial livestock', () {
    final source = File(
      'lib/features/animal_event/data/services/'
      'animal_enterprise_timeline_service.dart',
    ).readAsStringSync();

    expect(source.contains('/livestock/animals/\$animalId/timeline'), isTrue);
    expect(source.contains("'/animals/\$animalId/timeline'"), isFalse);
  });
}
