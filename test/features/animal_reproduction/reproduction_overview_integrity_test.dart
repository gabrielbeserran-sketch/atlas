import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/presentation/screens/reproduction_overview_screen.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

AnimalReproductionData event(
  String id, {
  String status = '',
  String result = '',
  String code = 'pregnancy_diagnosis',
  String date = '01/09/2026',
  String expectedDate = '',
}) => AnimalReproductionData(
  id: id,
  type: 'Diagnóstico de gestação',
  date: date,
  result: result,
  bullOrSemen: '',
  responsible: '',
  notes: '',
  eventCode: code,
  reproductiveStatus: status,
  expectedDate: expectedDate,
);

Future<void> show(
  WidgetTester tester,
  List<AnimalReproductionData> records,
) async {
  tester.view.resetPhysicalSize();
  tester.view.physicalSize = const Size(1800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: ReproductionOverviewScreen(
        contextLoader: () async => [
          ReproductionAnimalContext(
            farm: const FarmData(
              name: 'Teste',
              city: 'Cidade',
              state: 'GO',
              animals: 1,
              area: 10,
            ),
            group: const HerdGroupData(
              name: 'Matrizes',
              category: 'Matrizes',
              capacity: 10,
              paddock: 'P1',
            ),
            animal: AnimalData(
              id: 'cow',
              name: 'Matriz',
              tag: '1',
              sex: 'Fêmea',
              breed: 'G',
              birthDate: '01/01/2020',
              weight: 450,
              status: 'Ativo',
            ),
            records: records,
          ),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  testWidgets(
    'retorno inválido tem aviso e evento ilegível não vira histórico realizado',
    (tester) async {
      await show(tester, [
        event('invalid', date: '31/02/2026', expectedDate: '31/02/2026'),
      ]);
      expect(find.text('1 retorno(s) com data inválida'), findsOneWidget);
      expect(find.text('Sem evento realizado com data válida'), findsOneWidget);
      expect(
        find.textContaining('ação(ões) reprodutiva(s) vencida(s)'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('texto não prenhe não vira diagnóstico positivo', (tester) async {
    await show(tester, [event('p', result: 'não prenhe')]);
    expect(find.text('Sem base válida'), findsWidgets);
    expect(find.text('Concepção observada: 100,0%'), findsNothing);
    expect(find.text('Razão histórica (12 meses)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'situação do último diagnóstico prevalece sobre positivo antigo',
    (tester) async {
      await show(tester, [
        event('p', status: 'Prenhe'),
        event('o', status: 'Vazia', date: '02/09/2026'),
      ]);
      expect(find.text('0,0%'), findsOneWidget);
      expect(
        find.text('Prenhes sobre matrizes com diagnóstico atual válido'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('parto após diagnóstico mostra aviso e ausência de base atual', (
    tester,
  ) async {
    await show(tester, [
      event('p', status: 'Prenhe'),
      event('parto', code: 'calving', date: '02/09/2026'),
    ]);
    expect(find.textContaining('posterior ao último parto'), findsOneWidget);
    expect(find.text('Sem base válida'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
