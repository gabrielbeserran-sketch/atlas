import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_production_storage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_herd_snapshot_storage_service.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_daily_production_data.dart';
import 'package:projeto_atlas/features/dairy_production/domain/models/dairy_herd_snapshot_data.dart';
import 'package:projeto_atlas/features/dairy_production/domain/services/dairy_indicator_calculator.dart';
import 'package:projeto_atlas/features/dairy_production/presentation/screens/dairy_production_screen.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';

DairyDailyProductionData record(DateTime at, {double liters = 120}) =>
    DairyDailyProductionData(
      date: at,
      morningLiters: liters,
      afternoonLiters: 0,
      cowsMilked: 10,
    );
Map<String, dynamic> stored(String date) => {
  'date': date,
  'morning_liters': 100,
  'afternoon_liters': 20,
  'cows_milked': 10,
};

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('data ausente, impossível ou ilegível não vira ordenha de hoje', () {
    for (final date in ['', 'inválida', '2026-02-30', '2026-13-01']) {
      expect(
        () => DairyDailyProductionData.fromMap(stored(date)),
        throwsFormatException,
      );
    }
    expect(
      () => DairyDailyProductionData.fromMap(
        stored('2026-09-26')..remove('date'),
      ),
      throwsFormatException,
    );
  });

  test(
    'número ilegível e contagem fracionária não viram zero ou vaca inteira',
    () {
      expect(
        () => DairyDailyProductionData.fromMap({
          ...stored('2026-09-26'),
          'morning_liters': 'abc',
        }),
        throwsFormatException,
      );
      expect(
        () => DairyDailyProductionData.fromMap({
          ...stored('2026-09-26'),
          'cows_milked': 1.5,
        }),
        throwsFormatException,
      );
    },
  );

  test('ordenha de hoje com horário entra na janela e não é futura', () {
    final result = const DairyIndicatorCalculator().summarize(
      [record(DateTime(2026, 9, 26, 18))],
      hectares: 10,
      referenceDate: DateTime(2026, 9, 26, 9),
    );
    expect(result.futureRecords, 0);
    expect(result.recordedDays, 1);
    expect(result.averageLitersPerDay, 120);
    expect(result.daysSinceLatestRecord, 0);
  });

  test('média representável não transborda ao somar valores finitos', () {
    final result = const DairyIndicatorCalculator().summarize(
      [
        record(DateTime(2026, 9, 26), liters: 1e308),
        record(DateTime(2026, 9, 25), liters: 1e308),
      ],
      hectares: 10,
      referenceDate: DateTime(2026, 9, 26),
    );
    expect(result.averageLitersPerDay, closeTo(1e308, 1e294));
    expect(result.litersPerMilkedCow, closeTo(1e307, 1e293));
  });

  test('salvar e excluir não sobrescrevem conteúdo ilegível', () async {
    const key = 'atlas_dairy_daily_production_f';
    final prefs = SharedPreferencesAsync();
    final service = DairyProductionStorageService(preferences: prefs);
    for (final raw in [
      'corrompido',
      '[42]',
      jsonEncode([stored('inválida')]),
    ]) {
      await prefs.setString(key, raw);
      await expectLater(
        service.upsert('f', record(DateTime(2026, 9, 26))),
        throwsFormatException,
      );
      expect(await prefs.getString(key), raw);
      await expectLater(
        service.delete('f', DateTime(2026, 9, 26)),
        throwsFormatException,
      );
      expect(await prefs.getString(key), raw);
    }
  });

  test(
    'gravação recusa produção inválida sem substituir ordenha existente',
    () async {
      const key = 'atlas_dairy_daily_production_f';
      final prefs = SharedPreferencesAsync();
      final service = DairyProductionStorageService(preferences: prefs);
      await service.upsert('f', record(DateTime(2026, 9, 26)));
      final original = await prefs.getString(key);
      final now = DateTime.now();
      final invalid = <DairyDailyProductionData>[
        DairyDailyProductionData(
          date: DateTime(2026, 9, 26),
          morningLiters: double.nan,
          afternoonLiters: 0,
          cowsMilked: 10,
        ),
        DairyDailyProductionData(
          date: DateTime(2026, 9, 26),
          morningLiters: double.infinity,
          afternoonLiters: 0,
          cowsMilked: 10,
        ),
        DairyDailyProductionData(
          date: DateTime(2026, 9, 26),
          morningLiters: -1,
          afternoonLiters: 0,
          cowsMilked: 10,
        ),
        DairyDailyProductionData(
          date: DateTime(2026, 9, 26),
          morningLiters: 1e308,
          afternoonLiters: 1e308,
          cowsMilked: 10,
        ),
        DairyDailyProductionData(
          date: DateTime(2026, 9, 26),
          morningLiters: 10,
          afternoonLiters: 0,
          cowsMilked: 0,
        ),
        DairyDailyProductionData(
          date: DateTime(now.year, now.month, now.day + 1),
          morningLiters: 10,
          afternoonLiters: 0,
          cowsMilked: 10,
        ),
      ];
      for (final value in invalid) {
        await expectLater(service.upsert('f', value), throwsFormatException);
        expect(await prefs.getString(key), original);
      }
    },
  );

  test(
    'ordenha antiga sem vacas permanece para revisão, mas não entra na média',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setString(
        'atlas_dairy_daily_production_f',
        jsonEncode([stored('2026-09-26')..['cows_milked'] = 0]),
      );
      final values = await DairyProductionStorageService(
        preferences: prefs,
      ).load('f', strict: true);
      expect(values.single.cowsMilked, 0);
      final summary = const DairyIndicatorCalculator().summarize(
        values,
        hectares: 10,
        referenceDate: DateTime(2026, 9, 26),
      );
      expect(summary.recordedDays, 0);
      expect(summary.recordsWithoutMilkedCows, 1);
    },
  );

  test(
    'estado do lote ilegível não é sobrescrito ao salvar ou excluir',
    () async {
      const key = 'atlas_dairy_herd_snapshot_f';
      final prefs = SharedPreferencesAsync();
      final service = DairyHerdSnapshotStorageService(preferences: prefs);
      final snapshot = DairyHerdSnapshotData(
        date: DateTime(2026, 9, 26),
        eligibleCows: 10,
        lactatingCows: 6,
        dryCows: 3,
      );
      for (final raw in ['corrompido', '[42]', '[{"date":"2026-02-30"}]']) {
        await prefs.setString(key, raw);
        await expectLater(
          service.load('f', strict: true),
          throwsFormatException,
        );
        await expectLater(service.upsert('f', snapshot), throwsFormatException);
        await expectLater(
          service.delete('f', snapshot.date),
          throwsFormatException,
        );
        expect(await prefs.getString(key), raw);
      }
    },
  );

  test(
    'leitura de data ilegível não cria registro nem altera conteúdo',
    () async {
      const key = 'atlas_dairy_daily_production_f';
      final prefs = SharedPreferencesAsync();
      final raw = jsonEncode([stored('inválida')]);
      await prefs.setString(key, raw);
      expect(
        await DairyProductionStorageService(preferences: prefs).load('f'),
        isEmpty,
      );
      expect(await prefs.getString(key), raw);
    },
  );

  test(
    'data válida e números textuais preservam valores sem inventar data',
    () {
      final data = DairyDailyProductionData.fromMap({
        ...stored('2024-02-29T18:30:00'),
        'morning_liters': '100,5',
        'cows_milked': '10',
      });
      expect(data.date, DateTime(2024, 2, 29));
      expect(data.totalLiters, 120.5);
      expect(data.cowsMilked, 10);
      expect(
        DairyDailyProductionData.fromMap(data.toMap()).toMap(),
        data.toMap(),
      );
    },
  );

  test(
    'limite da janela usa dia civil e exclui somente dias fora da janela',
    () {
      final result = const DairyIndicatorCalculator().summarize(
        [
          record(DateTime(2026, 8, 28, 18)),
          record(DateTime(2026, 8, 27, 18), liters: 900),
          record(DateTime(2026, 9, 27), liters: 900),
        ],
        hectares: 10,
        referenceDate: DateTime(2026, 9, 26),
      );
      expect(result.recordedDays, 1);
      expect(result.averageLitersPerDay, 120);
      expect(result.futureRecords, 1);
    },
  );

  test(
    'gravação e exclusão válidas continuam preservando outra fazenda',
    () async {
      final service = DairyProductionStorageService();
      await service.upsert('other', record(DateTime(2026, 9, 26)));
      await service.upsert('f', record(DateTime(2026, 9, 26)));
      await service.upsert('f', record(DateTime(2026, 9, 25), liters: 100));
      await service.delete('f', DateTime(2026, 9, 26));
      expect((await service.load('f', strict: true)).single.totalLiters, 100);
      expect(
        (await service.load('other', strict: true)).single.totalLiters,
        120,
      );
    },
  );

  testWidgets(
    'tela informa falha, bloqueia nova ordenha e não mostra ausência falsa',
    (tester) async {
      const key = 'atlas_dairy_daily_production_f';
      final prefs = SharedPreferencesAsync();
      await prefs.setString(key, 'corrompido');
      await tester.pumpWidget(
        const MaterialApp(
          home: DairyProductionScreen(
            farm: FarmData(
              id: 'f',
              name: 'Teste',
              city: '',
              state: '',
              animals: 10,
              area: 20,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Não foi possível ler as ordenhas'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Ainda não há produção registrada'),
        findsNothing,
      );
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNull,
      );
      expect(await prefs.getString(key), 'corrompido');
      await prefs.setString(key, '[]');
      await tester.tap(find.text('Tentar leitura novamente'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Não foi possível ler as ordenhas'),
        findsNothing,
      );
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tela expõe litros por vaca em lactação e falha de leitura do lote',
    (tester) async {
      final prefs = SharedPreferencesAsync();
      await prefs.setString('atlas_dairy_herd_snapshot_f', 'corrompido');
      await tester.pumpWidget(
        const MaterialApp(
          home: DairyProductionScreen(
            farm: FarmData(
              id: 'f',
              name: 'Teste',
              city: '',
              state: '',
              animals: 10,
              area: 20,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Litros por vaca em lactação'), findsOneWidget);
      expect(
        find.textContaining('Não foi possível ler o estado do lote'),
        findsOneWidget,
      );
      expect(
        await prefs.getString('atlas_dairy_herd_snapshot_f'),
        'corrompido',
      );
    },
  );

  testWidgets('formulário recusa infinito antes de gravar ordenha', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DairyProductionScreen(
          farm: FarmData(
            id: 'f',
            name: 'Teste',
            city: '',
            state: '',
            animals: 10,
            area: 20,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar ordenha'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Infinity');
    await tester.enterText(fields.at(1), '10');
    await tester.enterText(fields.at(2), '1');
    await tester.tap(find.text('Salvar produção'));
    await tester.pumpAndSettle();
    expect(find.textContaining('valor finito'), findsOneWidget);
    expect(find.text('Salvar produção'), findsOneWidget);
    await tester.enterText(fields.at(0), '1e308');
    await tester.enterText(fields.at(1), '1e308');
    await tester.tap(find.text('Salvar produção'));
    await tester.pump();
    expect(find.text('A soma das ordenhas é inválida.'), findsOneWidget);
    expect(
      await SharedPreferencesAsync().getString(
        'atlas_dairy_daily_production_f',
      ),
      isNull,
    );
  });

  testWidgets('ordenha do mesmo dia e exclusão exigem confirmação', (
    tester,
  ) async {
    final day = DateTime.now();
    final storage = DairyProductionStorageService();
    await storage.upsert('f', record(day));
    await tester.pumpWidget(
      const MaterialApp(
        home: DairyProductionScreen(
          farm: FarmData(
            id: 'f',
            name: 'Teste',
            city: '',
            state: '',
            animals: 10,
            area: 20,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> offerReplacement() async {
      await tester.tap(find.text('Registrar ordenha'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '200');
      await tester.enterText(fields.at(1), '0');
      await tester.enterText(fields.at(2), '10');
      await tester.tap(find.text('Salvar produção'));
      await tester.pumpAndSettle();
      expect(find.text('Substituir ordenha existente?'), findsOneWidget);
    }

    await offerReplacement();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect((await storage.load('f', strict: true)).single.totalLiters, 120);

    await offerReplacement();
    await tester.tap(find.text('Substituir'));
    await tester.pumpAndSettle();
    expect((await storage.load('f', strict: true)).single.totalLiters, 200);

    await tester.scrollUntilVisible(find.byTooltip('Excluir registro'), 300);
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir registro'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir ordenha?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(await storage.load('f', strict: true), hasLength(1));

    await tester.tap(find.byTooltip('Excluir registro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(await storage.load('f', strict: true), isEmpty);
  });

  testWidgets(
    'estado do lote também exige confirmação ao substituir e excluir',
    (tester) async {
      final day = DateTime.now();
      final storage = DairyHerdSnapshotStorageService();
      await storage.upsert(
        'f',
        DairyHerdSnapshotData(
          date: day,
          eligibleCows: 10,
          lactatingCows: 6,
          dryCows: 3,
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: DairyProductionScreen(
            farm: FarmData(
              id: 'f',
              name: 'Teste',
              city: '',
              state: '',
              animals: 10,
              area: 20,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> offerReplacement() async {
        await tester.tap(find.byTooltip('Estado do lote'));
        await tester.pumpAndSettle();
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), '12');
        await tester.enterText(fields.at(1), '7');
        await tester.enterText(fields.at(2), '3');
        await tester.tap(find.text('Salvar'));
        await tester.pumpAndSettle();
        expect(find.text('Substituir estado do lote?'), findsOneWidget);
      }

      await offerReplacement();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect((await storage.load('f', strict: true)).single.eligibleCows, 10);

      await offerReplacement();
      await tester.tap(find.text('Substituir'));
      await tester.pumpAndSettle();
      expect((await storage.load('f', strict: true)).single.eligibleCows, 12);

      await tester.scrollUntilVisible(
        find.byTooltip('Excluir estado do lote'),
        300,
      );
      await tester.tap(find.byTooltip('Excluir estado do lote'));
      await tester.pumpAndSettle();
      expect(find.text('Excluir estado do lote?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(await storage.load('f', strict: true), hasLength(1));

      await tester.tap(find.byTooltip('Excluir estado do lote'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();
      expect(await storage.load('f', strict: true), isEmpty);
    },
  );
}
