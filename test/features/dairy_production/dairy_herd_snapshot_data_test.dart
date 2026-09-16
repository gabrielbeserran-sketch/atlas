import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_herd_snapshot_data.dart';

void main() {
  test('calcula e persiste perdas gestacionais com denominador explícito', () {
    final snapshot = DairyHerdSnapshotData(
      date: DateTime(2026, 9, 16),
      eligibleCows: 80,
      lactatingCows: 54,
      dryCows: 18,
      pregnanciesMonitored: 25,
      pregnancyLosses: 2,
    );

    expect(snapshot.pregnancyLossPercent, 8);
    final restored = DairyHerdSnapshotData.fromMap(snapshot.toMap());
    expect(restored.pregnanciesMonitored, 25);
    expect(restored.pregnancyLosses, 2);
    expect(restored.pregnancyLossPercent, 8);
  });

  test('não inventa percentual quando não há gestações acompanhadas', () {
    final snapshot = DairyHerdSnapshotData(
      date: DateTime(2026, 9, 16),
      eligibleCows: 10,
      lactatingCows: 6,
      dryCows: 3,
    );

    expect(snapshot.pregnancyLossPercent, isNull);
  });
}
