import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/farm_handling/domain/models/farm_handling_batch_result.dart';

void main() {
  test('resultado informa repetição idempotente do servidor', () {
    final result = FarmHandlingBatchResult.fromMap({
      'handling_id': 'handling-1',
      'action': 'sale_or_exit',
      'affected_count': 20,
      'summary': '20 animais baixados.',
      'repeated': true,
      'finance_entry_id': 'finance-1',
    });

    expect(result.repeated, isTrue);
    expect(result.affectedCount, 20);
    expect(result.financeEntryId, 'finance-1');
  });

  test('serviço usa histórico oficial e batch oficial', () {
    final service = File(
      'lib/features/farm_handling/data/services/'
      'farm_handling_enterprise_service.dart',
    ).readAsStringSync();

    expect(service.contains("'/livestock/handling/batch'"), isTrue);
    expect(service.contains("'/livestock/handling/history'"), isTrue);
    expect(service.contains('requestList('), isTrue);
  });

  test('tela mantém chave de operação após falha e limpa após sucesso', () {
    final screen = File(
      'lib/features/farm_handling/presentation/screens/'
      'farm_handling_screen.dart',
    ).readAsStringSync();

    expect(screen.contains('pendingOperationKey'), isTrue);
    expect(screen.contains('_ensureOperationKey()'), isTrue);
    expect(screen.contains("'idempotency_key': pendingOperationKey"), isTrue);
    expect(screen.contains('_clearOperationKey();'), isTrue);
    expect(
      screen.contains(
        'Nenhum registro foi duplicado.',
      ),
      isTrue,
    );
  });

  test('manejo exibe histórico auditável sem recriar módulo paralelo', () {
    final screen = File(
      'lib/features/farm_handling/presentation/screens/'
      'farm_handling_screen.dart',
    ).readAsStringSync();

    expect(screen.contains('Manejos recentes'), isTrue);
    expect(screen.contains('_HandlingHistoryCard'), isTrue);
    expect(screen.contains('Realizar manejo'), isTrue);
  });

  test('intervalo de brincos, lote e seleção manual permanecem', () {
    final screen = File(
      'lib/features/farm_handling/presentation/screens/'
      'farm_handling_screen.dart',
    ).readAsStringSync();

    expect(screen.contains('_SelectionMode.wholeLot'), isTrue);
    expect(screen.contains('_SelectionMode.earringRange'), isTrue);
    expect(screen.contains('_SelectionMode.manualSelection'), isTrue);
    expect(screen.contains('Brinco inicial'), isTrue);
    expect(screen.contains('Brinco final'), isTrue);
  });
}
