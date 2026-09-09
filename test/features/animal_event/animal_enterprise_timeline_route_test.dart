import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Timeline Enterprise usa o domínio oficial livestock', () {
    final source = File(
      'lib/features/animal_event/data/services/'
      'animal_enterprise_timeline_service.dart',
    ).readAsStringSync();

    expect(
      source.contains('/livestock/animals/\$animalId/timeline'),
      isTrue,
    );
    expect(
      source.contains("'/animals/\$animalId/timeline'"),
      isFalse,
    );
  });

  test('PDF do histórico preserva layout premium em página única', () {
    final source = File(
      'lib/features/animal_event/presentation/screens/'
      'animal_timeline_screen.dart',
    ).readAsStringSync();

    expect(source.contains('pw.Page('), isTrue);
    expect(source.contains('PdfPageFormat.a4.landscape'), isTrue);
    expect(source.contains("assets/branding/beserra_logo.png"), isTrue);
    expect(source.contains('timelineItems.reversed'), isTrue);
    expect(source.contains('_pdfPremiumTimeline(entries)'), isTrue);
    expect(source.contains('Gerar PDF premium em página única'), isTrue);
  });
}
