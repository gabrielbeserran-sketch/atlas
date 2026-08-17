import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/field_operations/domain/models/atlas_field_operation.dart';

void main() {
  test('identifica operação em massa, identificação e anexo', () {
    const operation = AtlasFieldOperation(
      operationType: 'create',
      entityType: 'field_weight',
      entityIds: ['a1', 'a2'],
      payload: {'rfid': 'TAG-1', 'photo_path': 'foto.jpg'},
    );
    expect(operation.isBulk, isTrue);
    expect(operation.hasIdentification, isTrue);
    expect(operation.hasAttachment, isTrue);
  });
}
