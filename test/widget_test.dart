import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/app.dart';

void main() {
  testWidgets('Atlas pinta uma interface antes de iniciar infraestrutura', (
    tester,
  ) async {
    await tester.pumpWidget(const AtlasApp());

    expect(
      find.byKey(const ValueKey<String>('atlas-first-frame')),
      findsOneWidget,
    );

    expect(find.text('Projeto Atlas'), findsOneWidget);

    expect(find.text('Preparando o ambiente...'), findsOneWidget);
  });
}
