import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/features/farm_operations/data/services/atlas_operations_repository.dart';
import 'package:projeto_atlas/features/farm_operations/domain/models/atlas_farm_operation.dart';
import 'package:projeto_atlas/features/farm_operations/presentation/screens/atlas_operations_center_screen.dart';

void main() {
  late ValueNotifier<bool> access;
  late AtlasOperationsRepository repository;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    access = ValueNotifier(true);
    repository = AtlasOperationsRepository.scoped(
      tenantId: 't',
      companyId: 'c',
      farmId: 'f',
    );
  });
  tearDown(() => access.dispose());
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: AtlasOperationsCenterScreen(
          farmId: 'f',
          companyId: 'c',
          tenantId: 't',
          actorId: 'owner',
          accessChanges: access,
          isAuthorized: () => access.value,
          canRecover: () => false,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> create(WidgetTester tester, {String cost = '150,25'}) async {
    await tester.tap(find.text('Nova operação').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).at(0),
      'Conferir bebedouro TESTE',
    );
    await tester.enterText(find.byType(TextField).at(1), 'Equipe de teste');
    await tester.enterText(find.byType(TextField).at(2), cost);
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect((await repository.load()).length, 1);
  }

  Future<void> menu(WidgetTester tester, String action) async {
    await tester.ensureVisible(find.byType(PopupMenuButton<String>).first);
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(action));
    await tester.pumpAndSettle();
  }

  // A fila estática de escritas e as transições compartilham a mesma zona
  // FakeAsync neste ensaio integrado, assim como numa sessão do aplicativo.
  testWidgets(
    'fluxo integrado: criar, reler, editar, excluir e revogar acesso',
    (tester) async {
      await open(tester);
      await create(tester);
      final items = await repository.loadReadOnly(farmId: 'f');
      expect(items.single.title, 'Conferir bebedouro TESTE');
      expect(items.single.plannedCost, 150.25);
      expect(items.single.responsible, 'Equipe de teste');
      expect(
        await AtlasOperationsRepository.scoped(
          tenantId: 't',
          companyId: 'other',
          farmId: 'f',
        ).load(),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
      await open(tester);
      expect(find.text('Conferir bebedouro TESTE'), findsOneWidget);
      await menu(tester, 'Editar');
      await tester.enterText(
        find.byType(TextField).at(0),
        'Conferir bebedouro EDITADO',
      );
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(
        (await repository.load()).single.title,
        'Conferir bebedouro EDITADO',
      );
      expect((await repository.load()).single.plannedCost, 150.25);

      final otherFarm = AtlasOperationsRepository.scoped(
        tenantId: 't',
        companyId: 'c',
        farmId: 'other-farm',
      );
      await otherFarm.save([
        AtlasFarmOperation.fromJson({
          ...(await repository.load()).single.toJson(),
          'id': 'other',
          'farmId': 'other-farm',
        }),
      ]);
      await menu(tester, 'Excluir');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect((await repository.load()).length, 1);
      await menu(tester, 'Excluir');
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();
      expect(await repository.load(), isEmpty);
      expect((await otherFarm.load()).single.id, 'other');

      for (final value in {'150.25': 150.25, '1.250,75': 1250.75}.entries) {
        await create(tester, cost: value.key);
        expect((await repository.load()).single.plannedCost, value.value);
        await menu(tester, 'Excluir');
        await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
        await tester.pumpAndSettle();
        expect(await repository.load(), isEmpty);
      }
      await tester.tap(find.text('Nova operação').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Não salvar');
      access.value = false;
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(await repository.load(), isEmpty);
    },
  );

  testWidgets('custo inválido não fecha formulário nem grava operação', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Nova operação').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Validar custo');
    for (final value in ['inválido', '-10', 'NaN', 'Infinity']) {
      await tester.enterText(find.byType(TextField).at(2), value);
      await tester.tap(find.text('Salvar'));
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(await repository.load(), isEmpty);
    }
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
