import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal_weight/domain/models/animal_weight_data.dart';
import 'package:projeto_atlas/features/animal_weight/domain/services/animal_weight_event_service.dart';
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

  test(
    'data impossível ou ausente não é convertida em hoje para o servidor',
    () {
      for (final invalid in ['', '31/02/2026', '29/02/2026', '1/10/2026']) {
        final record = AnimalWeightData(
          id: 'legacy',
          date: invalid,
          weight: 440,
          notes: '',
        );
        expect(() => record.toRemoteBody(), throwsFormatException);
      }
      final future = DateTime.now().add(const Duration(days: 2));
      final futureDate =
          '${future.day.toString().padLeft(2, '0')}/'
          '${future.month.toString().padLeft(2, '0')}/${future.year}';
      expect(
        () => AnimalWeightData(
          id: 'future',
          date: futureDate,
          weight: 440,
          notes: '',
        ).toRemoteBody(),
        throwsFormatException,
      );
      const leap = AnimalWeightData(
        id: 'leap',
        date: '29/02/2024',
        weight: 440,
        notes: '',
      );
      expect(
        DateTime.parse(
          leap.toRemoteBody()['measured_at'] as String,
        ).toLocal().day,
        29,
      );
    },
  );

  test(
    'pesos não finitos e retorno remoto com data impossível não contaminam indicadores',
    () {
      for (final invalid in [0.0, -1.0, double.infinity, double.nan]) {
        final record = AnimalWeightData(
          id: 'invalid',
          date: '23/09/2026',
          weight: invalid,
          notes: '',
        );
        expect(() => record.toRemoteBody(), throwsFormatException);
      }
      final remote = AnimalWeightData.fromRemoteMap({
        'id': 'remote-invalid-date',
        'measured_at': '2026-02-31T12:00:00Z',
        'weight': 440,
        'notes': '',
      });
      expect(remote.date, isEmpty);
      expect(remote.isValidForIndicators(DateTime(2026, 10, 1)), isFalse);
      expect(
        const AnimalWeightData(
          id: 'future',
          date: '02/10/2026',
          weight: 440,
          notes: '',
        ).isValidForIndicators(DateTime(2026, 10, 1)),
        isFalse,
      );
    },
  );

  test(
    'evento de pesagem não recebe data impossível como data atual',
    () async {
      await expectLater(
        const AnimalWeightEventService().publishWeightRecorded(
          farmName: 'Fazenda',
          animalId: 'a',
          animalName: 'Animal',
          weight: const AnimalWeightData(
            id: 'old',
            date: '31/02/2026',
            weight: 440,
            notes: '',
          ),
        ),
        throwsFormatException,
      );
    },
  );

  testWidgets('edição local com data inválida não pode ser salva', (
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
                    builder: (_) => const AnimalWeightFormScreen(
                      weightRecord: AnimalWeightData(
                        id: 'old',
                        date: '31/02/2026',
                        weight: 440,
                        notes: '',
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Editar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar alterações'));
    await tester.tap(find.text('Salvar alterações'));
    await tester.pumpAndSettle();
    expect(find.text('Informe uma data válida até hoje.'), findsOneWidget);
    expect(result, isNull);
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
