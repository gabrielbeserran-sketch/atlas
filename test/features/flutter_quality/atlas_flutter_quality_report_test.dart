import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/flutter_quality/domain/models/atlas_flutter_quality_report.dart';

void main() {
  test('calcula aprovação do gate', () {
    final r = AtlasFlutterQualityReport(
      checks: {'a': true, 'b': true},
      generatedAt: DateTime.utc(2026),
    );
    expect(r.approved, isTrue);
    expect(r.percent, 100);
  });
}
