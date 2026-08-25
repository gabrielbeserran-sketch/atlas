import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('10A preserva vínculo operacional e resultado mensurável', () {
    final service = File('lib/features/consultancy_client/data/services/atlas_consultancy_action_service.dart').readAsStringSync();
    final model = File('lib/features/consultancy_client/domain/models/atlas_consultancy_action.dart').readAsStringSync();
    final card = File('lib/features/consultancy_client/presentation/widgets/atlas_consultancy_action_plan_card.dart').readAsStringSync();
    expect(service.contains("'source_entity_type': priority.entityType"), isTrue);
    expect(service.contains('/business/consulting/actions/outcomes'), isTrue);
    expect(model.contains('outcomeStatus'), isTrue);
    expect(model.contains('baselineMetrics'), isTrue);
    expect(card.contains('Melhora observada'), isTrue);
  });
}
