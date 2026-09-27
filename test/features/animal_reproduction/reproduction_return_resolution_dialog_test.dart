import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/animal_reproduction/presentation/widgets/reproduction_return_resolution_dialog.dart';
import 'package:projeto_atlas/features/animal_reproduction/presentation/screens/animal_reproduction_list_screen.dart';
import 'reproduction_return_resolution_test.dart' as fixtures;

void main() {
  testWidgets(
    'menu oferece baixa apenas para retorno pendente e respeita bloqueio',
    (tester) async {
      String? selected;
      Widget card({bool enabled = true}) => MaterialApp(
        home: Scaffold(
          body: ReproductionRecordCard(
            record: fixtures.record(),
            onEdit: () {},
            onDelete: () {},
            enabled: enabled,
            onResolveReturn: (value) => selected = value,
          ),
        ),
      );
      await tester.pumpWidget(card());
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Cancelar retorno'), findsOneWidget);
      await tester.tap(find.text('Concluir retorno'));
      await tester.pumpAndSettle();
      expect(selected, 'completed');
      await tester.pumpWidget(card(enabled: false));
      expect(
        tester
            .widget<PopupMenuButton<String>>(
              find.byType(PopupMenuButton<String>),
            )
            .enabled,
        isFalse,
      );
    },
  );
  testWidgets('cancelamento exige responsável e motivo antes de confirmar', (
    tester,
  ) async {
    ReturnResolutionInput? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showReturnResolutionDialog(
                  context,
                  cancel: true,
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
    await tester.tap(find.text('Confirmar baixa'));
    await tester.pumpAndSettle();
    expect(find.text('Informe o responsável.'), findsOneWidget);
    expect(find.text('Informe o motivo.'), findsOneWidget);
    expect(result, isNull);
    await tester.enterText(find.byType(TextFormField).first, ' Operador ');
    await tester.enterText(find.byType(TextFormField).last, ' Replanejado ');
    await tester.tap(find.text('Confirmar baixa'));
    await tester.pumpAndSettle();
    expect(result?.responsible, 'Operador');
    expect(result?.reason, 'Replanejado');
  });
  testWidgets('voltar não confirma a baixa', (tester) async {
    var finished = false;
    ReturnResolutionInput? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showReturnResolutionDialog(
                  context,
                  cancel: false,
                  responsible: 'Operador',
                );
                finished = true;
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
    expect(result, isNull);
  });
}
