import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/shared/design_system/iconography/atlas_livestock_mark.dart';

void main() {
  testWidgets('Rebanho renderiza a cabeca Nelore vetorial', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: AtlasLivestockMark(size: 32))),
      ),
    );

    expect(find.byType(AtlasLivestockMark), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Animais usa brinco pecuario e nao pata', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AtlasAnimalsGroupIcon())),
    );

    expect(find.byIcon(Icons.sell_outlined), findsOneWidget);
    expect(find.byIcon(Icons.pets_outlined), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renderer central troca apenas Rebanho', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AtlasNavigationIcon(
                routeLabel: 'Rebanho',
                fallback: Icons.groups_outlined,
              ),
              AtlasNavigationIcon(
                routeLabel: 'Sanidade',
                fallback: Icons.health_and_safety_outlined,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(AtlasLivestockMark), findsOneWidget);
    expect(find.byIcon(Icons.groups_outlined), findsNothing);
    expect(find.byIcon(Icons.health_and_safety_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

// R6 visual-contract note:
// AtlasLivestockMark is intentionally implemented by
// _AtlasApprovedHerdHeadPainter: hornless frontal bovine head matching the
// user-approved option, not the superseded horned R5 drawing.
