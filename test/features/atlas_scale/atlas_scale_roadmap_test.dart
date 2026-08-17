import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_scale/domain/models/atlas_scale_roadmap.dart';

void main() {
  test('scale roadmap exposes a bounded progress', () {
    final roadmap = AtlasScaleRoadmap.standard();
    expect(roadmap.horizonYears, 5);
    expect(roadmap.progress, inInclusiveRange(0, 1));
    expect(roadmap.pillars, isNotEmpty);
  });
}
