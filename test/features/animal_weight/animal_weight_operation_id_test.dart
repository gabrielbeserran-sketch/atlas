import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:projeto_atlas/features/animal_weight/presentation/screens/animal_weight_form_screen.dart';

void main() {
  test('identificador da operação persiste no cache e no payload remoto', () {
    const record = AnimalWeightData(
      id: 'local-weight-1',
      date: '23/09/2026',
      weight: 440,
      notes: 'Jejum',
      clientOperationId: '4d430ca2-6390-4d16-9f51-10a65c1e4809',
    );
    final restored = AnimalWeightData.fromMap(record.toMap());
    expect(restored.clientOperationId, record.clientOperationId);
    expect(
      restored.toRemoteBody()['client_operation_id'],
      record.clientOperationId,
    );

    const legacy = AnimalWeightData(
      id: 'old',
      date: '23/09/2026',
      weight: 440,
      notes: '',
    );
    expect(legacy.toRemoteBody().containsKey('client_operation_id'), isFalse);
  });

  test('resposta remota preserva o identificador para conciliação', () {
    final record = AnimalWeightData.fromRemoteMap({
      'id': 'weight-server-1',
      'measured_at': '2026-09-23T12:00:00Z',
      'weight': 440,
      'notes': '',
      'client_operation_id': 'operation-123',
    });
    expect(record.id, 'weight-server-1');
    expect(record.isRemote, isTrue);
    expect(record.clientOperationId, 'operation-123');
  });

  testWidgets('nova pesagem recebe UUID estável antes do envio', (
    tester,
  ) async {
    AnimalWeightData? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await Navigator.of(context).push<AnimalWeightData>(
                  MaterialPageRoute(
                    builder: (_) => const AnimalWeightFormScreen(),
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Peso em kg'),
      '440',
    );
    await tester.ensureVisible(find.text('Salvar pesagem'));
    await tester.tap(find.text('Salvar pesagem'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.id, result!.clientOperationId);
    expect(result!.clientOperationId.length, 36);
    expect(result!.toRemoteBody()['client_operation_id'], result!.id);
  });
}
