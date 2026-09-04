import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/authentication/presentation/screens/login_screen.dart';

void main() {
  testWidgets('login has a bounded desktop scroll viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1264, 681));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
