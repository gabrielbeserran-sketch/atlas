import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('O Projeto Atlas possui um widget raiz válido', () {
    const app = AtlasApp();

    expect(app, isA<StatefulWidget>());
    expect(app.createState(), isNotNull);
  });
}
