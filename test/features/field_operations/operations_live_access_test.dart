import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/features/farm_operations/data/services/atlas_operations_repository.dart';
import 'package:projeto_atlas/features/farm_operations/presentation/atlas_operations_navigation.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('revogação antes da fila impede escrita', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('atlas_farm_operations_v1', '[]');
    await expectLater(
      AtlasOperationsRepository().save(
        [],
        farmId: 'f',
        isAuthorized: () => false,
      ),
      throwsStateError,
    );
    expect(prefs.getString('atlas_farm_operations_v1'), '[]');
  });
  test('revogação após leitura impede persistência e libera fila', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('atlas_farm_operations_v1', ' [] ');
    var checks = 0;
    await expectLater(
      AtlasOperationsRepository().save(
        [],
        farmId: 'f',
        isAuthorized: () => ++checks == 1,
      ),
      throwsStateError,
    );
    expect(checks, 2);
    expect(prefs.getString('atlas_farm_operations_v1'), ' [] ');
    await AtlasOperationsRepository().save(
      [],
      farmId: 'f',
      isAuthorized: () => true,
    );
    expect(prefs.getString('atlas_farm_operations_v1'), '[]');
  });
  testWidgets('perder acesso remove conteúdo e não reativa rota antiga', (
    tester,
  ) async {
    final access = ValueNotifier(true);
    bool Function()? writeCheck;
    await tester.pumpWidget(
      MaterialApp(
        home: OperationsAccessGuard(
          changes: access,
          isAuthorized: () => access.value,
          builder: (check) {
            writeCheck = check;
            return const Scaffold(body: Text('Dados da fazenda anterior'));
          },
        ),
      ),
    );
    expect(find.text('Dados da fazenda anterior'), findsOneWidget);
    expect(writeCheck!(), isTrue);
    access.value = false;
    await tester.pump();
    expect(find.text('Dados da fazenda anterior'), findsNothing);
    expect(find.textContaining('O contexto de acesso mudou.'), findsOneWidget);
    expect(writeCheck!(), isFalse);
    access.value = true;
    await tester.pump();
    expect(writeCheck!(), isFalse);
    expect(find.text('Dados da fazenda anterior'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    access.dispose();
  });
  testWidgets('dispose desautoriza chamada capturada', (tester) async {
    final access = ValueNotifier(true);
    bool Function()? check;
    await tester.pumpWidget(
      MaterialApp(
        home: OperationsAccessGuard(
          changes: access,
          isAuthorized: () => true,
          builder: (value) {
            check = value;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    expect(check!(), isFalse);
    access.value = false;
    access.dispose();
  });
}
