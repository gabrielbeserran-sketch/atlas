import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'O Projeto Atlas inicia corretamente',
    (WidgetTester tester) async {
      await tester.pumpWidget(const AtlasApp());

      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
