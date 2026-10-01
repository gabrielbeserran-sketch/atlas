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
}
