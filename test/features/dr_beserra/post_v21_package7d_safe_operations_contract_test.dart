import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_command.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/models/dr_beserra_operation_draft.dart';
import 'package:projeto_atlas/features/dr_beserra/domain/services/dr_beserra_operation_parser.dart';

void main() {
  const parser = DrBeserraOperationParser();

  test('monta vacinação somente quando há dados obrigatórios', () {
    final complete = parser.parse(
      intent: DrBeserraIntent.openHealth,
      rawText:
          'vacinar brinco 101 com aftosa dose 5 ml responsável João',
    );
    expect(complete, isNotNull);
    expect(complete!.kind, DrBeserraOperationKind.health);
    expect(complete.animalTag, '101');
    expect(complete.eventType, 'Vacinação');
    expect(complete.product, 'aftosa');
    expect(complete.dose, '5 ml');
    expect(complete.responsible, 'joao');
    expect(complete.isComplete, isTrue);

    final incomplete = parser.parse(
      intent: DrBeserraIntent.openHealth,
      rawText: 'vacinar brinco 101',
    );
    expect(incomplete, isNotNull);
    expect(incomplete!.isComplete, isFalse);
    expect(incomplete.missingFields, contains('produto'));
    expect(incomplete.missingFields, contains('dose'));
    expect(incomplete.missingFields, contains('responsável'));
  });

  test('monta diagnóstico reprodutivo e exige resultado', () {
    final draft = parser.parse(
      intent: DrBeserraIntent.openReproduction,
      rawText:
          'diagnóstico de gestação brinco 205 prenhe responsável Maria',
    );
    expect(draft, isNotNull);
    expect(draft!.kind, DrBeserraOperationKind.reproduction);
    expect(draft.eventType, 'Diagnóstico de gestação');
    expect(draft.result, 'Positivo');
    expect(draft.isComplete, isTrue);

    final missingResult = parser.parse(
      intent: DrBeserraIntent.openReproduction,
      rawText: 'diagnóstico de gestação brinco 205 responsável Maria',
    );
    expect(missingResult, isNotNull);
    expect(
      missingResult!.missingFields,
      contains('resultado do diagnóstico'),
    );
  });

  test('monta movimentação coletiva por intervalo de brincos', () {
    final draft = parser.parse(
      intent: DrBeserraIntent.openHandling,
      rawText:
          'mover brincos 100 a 120 para lote Recria responsável Pedro',
    );
    expect(draft, isNotNull);
    expect(
      draft!.kind,
      DrBeserraOperationKind.handlingLotMovement,
    );
    expect(draft.earringStart, '100');
    expect(draft.earringEnd, '120');
    expect(draft.destinationLotName, 'recria');
    expect(draft.responsible, 'pedro');
    expect(draft.isComplete, isTrue);
  });

  test('gateway usa somente serviços oficiais e confirmação explícita', () {
    final gateway = File(
      'lib/features/dr_beserra/data/services/'
      'dr_beserra_command_gateway.dart',
    ).readAsStringSync();

    expect(gateway.contains('confirmOperation('), isTrue);
    expect(gateway.contains('_health.createRecord('), isTrue);
    expect(gateway.contains('_reproduction.createRecord('), isTrue);
    expect(gateway.contains('_handling.execute('), isTrue);
    expect(gateway.contains('AtlasHttpClient'), isFalse);
    expect(gateway.contains('SharedPreferences'), isFalse);
  });

  test('escritas possuem confirmação de persistência/resultado', () {
    final gateway = File(
      'lib/features/dr_beserra/data/services/'
      'dr_beserra_command_gateway.dart',
    ).readAsStringSync();

    expect(gateway.contains('if (!created.synced'), isTrue);
    expect(gateway.contains('result.affectedCount != selected.length'), isTrue);
    expect(
      gateway.contains(
        'O servidor não confirmou a movimentação de todos os animais.',
      ),
      isTrue,
    );
  });

  test('interface separa interpretação de confirmação', () {
    final screen = File(
      'lib/features/dr_beserra/presentation/screens/'
      'dr_beserra_screen.dart',
    ).readAsStringSync();

    expect(screen.contains('confirmationOperation'), isTrue);
    expect(screen.contains('confirmOperation()'), isTrue);
    expect(
      screen.contains('gateway.confirmOperation('),
      isTrue,
    );
    expect(screen.contains('_ConfirmationBar'), isTrue);
  });
}
