import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/release_management/domain/models/atlas_release_plan.dart';

void main() {
  test('release exige todos os checks', () {
    final p = AtlasReleasePlan.standard();
    expect(p.canDeploy, isFalse);
    expect(p.progress, closeTo(.8, .001));
  });
}
