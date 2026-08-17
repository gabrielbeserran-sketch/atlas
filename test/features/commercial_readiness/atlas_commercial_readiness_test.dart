import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/commercial_readiness/domain/models/atlas_commercial_readiness.dart';

void main() {
  test('preparação padrão está completa', () {
    final p = AtlasCommercialReadiness.standard();
    expect(p.ready, isTrue);
    expect(p.progress, 1);
  });
}
