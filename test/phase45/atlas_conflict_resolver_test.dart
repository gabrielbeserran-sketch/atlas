import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/sync/atlas_conflict_resolver.dart';

void main() {
  test('marks edited conflicting fields for review', () {
    const resolver = AtlasConflictResolver();

    final result = resolver.resolve(
      local: {'weight': 500, 'name': 'Animal A'},
      remote: {'weight': 480, 'name': 'Animal A'},
      locallyEditedFields: {'weight'},
      justification: 'Pesagem realizada offline.',
    );

    expect(result.payload['weight'], 500);
    expect(result.payload['_requires_manual_review'], isTrue);
  });
}
