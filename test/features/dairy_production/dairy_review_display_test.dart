import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_offline_stage_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_remote_lookup_service.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_remote_reconciliation.dart';
import 'package:projeto_atlas/features/dairy_production/data/services/dairy_sync_decision_service.dart';
import 'package:projeto_atlas/features/dairy_production/presentation/widgets/dairy_review_display.dart';

void main() {
  test('mostra campos conhecidos e futuros sem ocultar diferença', () {
    final fields = DairyReviewDisplay.fields('dairy_daily_production', {
      'farm_id': 'farm-a',
      'date': '2026-09-30T00:00:00',
      'morning_liters': 12.5,
      'afternoon_liters': 8,
      'cows_milked': 5,
      'notes': 'Conferir tanque',
      'future_quality_index': 3,
    });
    expect(
      DairyReviewDisplay.title('dairy_daily_production', 'farm-a:2026-09-30'),
      'Ordenha · 30/09/2026',
    );
    expect(
      fields.map((field) => field.label),
      containsAll([
        'Data',
        'Leite de manhã (L)',
        'Vacas ordenhadas',
        'Observações',
        'future_quality_index',
      ]),
    );
    expect(fields.any((field) => field.label == 'farm_id'), isFalse);
    expect(fields.first.value, '30/09/2026');
  });

  testWidgets('expande registro local alterado e mostra ambas as cópias', (
    tester,
  ) async {
    const item = DairyReviewItem(
      'dairy_daily_production',
      'farm-a:2026-09-30',
      DairyReviewStatus.localChanged,
      stagedPayload: {'morning_liters': 10, 'cows_milked': 4},
      localPayload: {'morning_liters': 12, 'cows_milked': 4},
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DairyReviewDetails(local: item)),
      ),
    );
    expect(
      find.text('Alterado neste aparelho após a preparação'),
      findsOneWidget,
    );
    await tester.tap(find.text('Ordenha · 30/09/2026'));
    await tester.pumpAndSettle();
    expect(find.text('Cópia preparada neste aparelho'), findsOneWidget);
    expect(find.text('Registro atual neste aparelho'), findsOneWidget);
    expect(find.text('Leite de manhã (L): 10'), findsOneWidget);
    expect(find.text('Leite de manhã (L): 12'), findsOneWidget);
  });

  testWidgets('mostra divergência, versão e momento da consulta', (
    tester,
  ) async {
    const local = DairyReviewItem(
      'dairy_daily_production',
      'farm-a:2026-09-30',
      DairyReviewStatus.waitingForCache,
      stagedPayload: {'morning_liters': 10},
    );
    final remote = DairyRemoteReviewEntry(
      local: local,
      remote: DairyRemoteState(
        key: const DairyLookupKey(
          entityType: 'dairy_daily_production',
          entityId: 'farm-a:2026-09-30',
        ),
        found: true,
        version: 4,
        deleted: false,
        payload: const {'morning_liters': 12},
        readAt: DateTime.utc(2026, 10, 1, 12),
      ),
      status: DairyRemoteReviewStatus.differsOnServer,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DairyReviewDetails(local: local, remote: remote),
        ),
      ),
    );
    expect(find.text('Valores diferentes no servidor'), findsOneWidget);
    await tester.tap(find.text('Ordenha · 30/09/2026'));
    await tester.pumpAndSettle();
    expect(find.text('Servidor · versão 4'), findsOneWidget);
    expect(find.text('Valores no servidor'), findsOneWidget);
    expect(find.text('Leite de manhã (L): 10'), findsOneWidget);
    expect(find.text('Leite de manhã (L): 12'), findsOneWidget);
    expect(
      find.textContaining('O servidor pode mudar após esse horário'),
      findsOneWidget,
    );
  });

  testWidgets(
    'cópia recebida antiga fica identificada como possivelmente desatualizada',
    (tester) async {
      const item = DairyReviewItem(
        'dairy_daily_production',
        'farm-a:2026-09-30',
        DairyReviewStatus.differsFromCached,
        stagedPayload: {'morning_liters': 10},
        cachedPayload: {'morning_liters': 9},
        cachedVersion: 2,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DairyReviewDetails(local: item)),
        ),
      );
      await tester.tap(find.text('Ordenha · 30/09/2026'));
      await tester.pumpAndSettle();
      expect(find.text('Última cópia recebida · versão 2'), findsOneWidget);
      expect(find.text('Leite de manhã (L): 9'), findsOneWidget);
      expect(find.text('Esta cópia pode estar desatualizada.'), findsOneWidget);
    },
  );
  testWidgets('preferência só aparece para divergência e não inicia envio', (
    tester,
  ) async {
    const local = DairyReviewItem(
      'dairy_daily_production',
      'farm-a:2026-09-30',
      DairyReviewStatus.waitingForCache,
      stagedPayload: {'morning_liters': 10},
      localPayload: {'morning_liters': 10},
    );
    final remoteState = DairyRemoteState(
      key: const DairyLookupKey(
        entityType: 'dairy_daily_production',
        entityId: 'farm-a:2026-09-30',
      ),
      found: false,
      version: 0,
      deleted: false,
      payload: const {},
      readAt: DateTime.utc(2026, 10, 5),
    );
    var selected = 0;
    Widget screen(DairyRemoteReviewStatus status) => MaterialApp(
      home: Scaffold(
        body: DairyReviewDetails(
          local: local,
          remote: DairyRemoteReviewEntry(
            local: local,
            remote: remoteState,
            status: status,
          ),
          onPreferLocal: () => selected++,
          onKeepServer: () => selected--,
        ),
      ),
    );
    await tester.pumpWidget(screen(DairyRemoteReviewStatus.absentOnServer));
    await tester.tap(find.text('Ordenha · 30/09/2026'));
    await tester.pumpAndSettle();
    expect(find.textContaining('não inicia o envio'), findsOneWidget);
    await tester.tap(find.text('Preferir este aparelho'));
    expect(selected, 1);
    await tester.pumpWidget(screen(DairyRemoteReviewStatus.sameOnServer));
    await tester.tap(find.text('Ordenha · 30/09/2026'));
    await tester.pumpAndSettle();
    expect(find.text('Preferir este aparelho'), findsNothing);
  });

  testWidgets('preferência antiga sinaliza mudança local', (tester) async {
    const local = DairyReviewItem(
      'dairy_daily_production',
      'farm-a:2026-09-30',
      DairyReviewStatus.localChanged,
      stagedPayload: {'morning_liters': 10},
      localPayload: {'morning_liters': 12},
    );
    final saved = DairySavedDecision(
      entityType: local.entityType,
      entityId: local.entityId,
      choice: DairyDecisionChoice.preferLocal,
      stagedPayload: const {'morning_liters': 10},
      remoteVersion: 1,
      remoteDeleted: false,
      remotePayload: const {},
      decidedAt: DateTime.utc(2026, 10, 5),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DairyReviewDetails(
            local: local,
            decision: saved,
            onRemoveDecision: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ordenha · 30/09/2026'));
    await tester.pumpAndSettle();
    expect(find.textContaining('exige nova conferência'), findsOneWidget);
    expect(find.text('Retirar preferência'), findsOneWidget);
  });
}
