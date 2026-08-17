import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/publication_center/domain/models/atlas_publication_plan.dart';

void main() {
  test('publication remains blocked while criteria are incomplete', () {
    final plan = AtlasPublicationPlan.standard();
    expect(plan.ready, isFalse);
    expect(plan.completedCount, 0);
    expect(plan.progress, 0);
  });

  test('publication is ready when every criterion is complete', () {
    final source = AtlasPublicationPlan.standard();
    final plan = AtlasPublicationPlan(
      checks: source.checks
          .map(
            (item) => AtlasPublicationCheck(
              name: item.name,
              completed: true,
              channel: item.channel,
            ),
          )
          .toList(),
    );
    expect(plan.ready, isTrue);
    expect(plan.progress, 1);
  });
}
