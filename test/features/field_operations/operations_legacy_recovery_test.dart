import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/features/farm_operations/data/services/atlas_operations_repository.dart';
import 'operations_scoped_save_test.dart' show operation;
import 'package:projeto_atlas/features/farm_operations/presentation/screens/operations_legacy_recovery_screen.dart';

void main() {
  late AtlasOperationsRepository scoped;
  late Map<String, dynamic> record;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    scoped = AtlasOperationsRepository.scoped(
      tenantId: 't',
      companyId: 'c',
      farmId: 'f',
    );
    record = operation('old', null).toJson();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('atlas_farm_operations_v1', jsonEncode([record]));
  });
  Future<int> recover({bool confirmation = true, bool authorized = true}) =>
      scoped.recoverLegacy(
        reviewed: [record],
        actorId: 'admin',
        confirmedOwnership: confirmation,
        isAuthorized: () => authorized,
      );
  testWidgets('revisão exige declaração e cancelar não importa', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OperationsLegacyRecoveryScreen(
          repository: scoped,
          actorId: 'admin',
          farmId: 'f',
          isAuthorized: () => true,
        ),
      ),
    );
    expect(find.text('old'), findsNothing);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('Revisar registros'));
    await tester.pumpAndSettle();
    expect(find.text('old'), findsOneWidget);
    await tester.tap(find.text('old'));
    await tester.pump();
    await tester.tap(find.text('Recuperar selecionadas'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar atribuição'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(await scoped.load(), isEmpty);
  });
  test(
    'seleção explícita copia uma vez, com auditoria e origem intacta',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final before = prefs.getString('atlas_farm_operations_v1');
      expect(await recover(), 1);
      expect(await recover(), 0);
      final items = await scoped.load();
      expect(items.length, 1);
      expect(items.single.farmId, 'f');
      expect(prefs.getString('atlas_farm_operations_v1'), before);
      final stored =
          jsonDecode(
                prefs.getString(
                  AtlasOperationsRepository.scopedKey('t', 'c', 'f'),
                )!,
              )
              as List;
      expect(stored.single['_atlasLegacyRecovery']['actorId'], 'admin');
      expect(stored.single['_atlasLegacyRecovery']['sourceFarmId'], isNull);
      expect(stored.single['_atlasLegacyRecovery']['confirmedOwnership'], true);
    },
  );
  test('sem confirmação/acesso não lê revisão nem recupera', () async {
    await expectLater(recover(confirmation: false), throwsStateError);
    await expectLater(recover(authorized: false), throwsStateError);
    await expectLater(
      scoped.reviewLegacy(isAuthorized: () => false),
      throwsStateError,
    );
    expect(await scoped.load(), isEmpty);
  });
  test('fonte modificada depois da revisão não é copiada', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'atlas_farm_operations_v1',
      jsonEncode([
        {...record, 'title': 'Mudou'},
      ]),
    );
    await expectLater(recover(), throwsStateError);
    expect(await scoped.load(), isEmpty);
  });
  test('IDs ambíguos na origem bloqueiam cópia', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'atlas_farm_operations_v1',
      jsonEncode([record, record]),
    );
    await expectLater(recover(), throwsStateError);
    expect(await scoped.load(), isEmpty);
  });
  test('conflito com destino não sobrescreve tarefa existente', () async {
    final id = 'legacy_${base64Url.encode(utf8.encode('old'))}';
    await scoped.save([operation(id, 'f')]);
    await expectLater(recover(), throwsStateError);
    expect((await scoped.load()).single.id, id);
  });
  test(
    'editar recuperada preserva auditoria e repetição não desfaz edição',
    () async {
      await recover();
      final item = (await scoped.load()).single;
      await scoped.save([item.copyWith(title: 'Editada')]);
      expect(await recover(), 0);
      expect((await scoped.load()).single.title, 'Editada');
      final prefs = await SharedPreferences.getInstance();
      final stored =
          jsonDecode(
                prefs.getString(
                  AtlasOperationsRepository.scopedKey('t', 'c', 'f'),
                )!,
              )
              as List;
      expect(stored.single['_atlasLegacyRecovery']['actorId'], 'admin');
    },
  );
  test('perda de contexto antes de persistir preserva destino', () async {
    var checks = 0;
    await expectLater(
      scoped.recoverLegacy(
        reviewed: [record],
        actorId: 'admin',
        confirmedOwnership: true,
        isAuthorized: () => ++checks == 1,
      ),
      throwsStateError,
    );
    expect(await scoped.load(), isEmpty);
  });
  test(
    'recuperação não importa itens não selecionados ou outra empresa',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'atlas_farm_operations_v1',
        jsonEncode([record, operation('other', 'g').toJson()]),
      );
      await recover();
      expect((await scoped.load()).length, 1);
      expect(
        await AtlasOperationsRepository.scoped(
          tenantId: 't',
          companyId: 'other',
          farmId: 'f',
        ).load(),
        isEmpty,
      );
    },
  );
}
