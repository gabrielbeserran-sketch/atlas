import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/pilot_program/domain/models/atlas_pilot_plan.dart';

void main() {
  test('piloto inicial ainda não fecha', () {
    final p = AtlasPilotPlan.standard();
    expect(p.readyToClose, isFalse);
    expect(p.averageProgress, 0);
  });
  test('métrica calcula progresso', () {
    const m = AtlasPilotMetric(
      name: 'x',
      baseline: 0,
      target: 100,
      current: 50,
    );
    expect(m.progress, .5);
  });
}
