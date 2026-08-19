import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Rebanho não possui timeout local de oito segundos', () {
    final source = File(
      'lib/features/herd/presentation/screens/herd_overview_screen.dart',
    ).readAsStringSync();

    expect(source.contains('Duration(seconds: 8)'), isFalse);
    expect(source.contains('return await loader().timeout('), isFalse);
    expect(source.contains('return await loader();'), isTrue);
  });

  test('Rebanho preserva fallback em falha transitória', () {
    final source = File(
      'lib/features/herd/presentation/screens/herd_overview_screen.dart',
    ).readAsStringSync();

    expect(source.contains('required List<T> fallback'), isTrue);
    expect(source.contains('previousGroups'), isTrue);
    expect(source.contains('previousAnimals'), isTrue);
  });

  test('Filtro de lote é expansível e usa ellipsis', () {
    final source = File(
      'lib/features/herd/presentation/screens/herd_overview_screen.dart',
    ).readAsStringSync();

    expect(source.contains('isExpanded: true'), isTrue);
    expect(source.contains('TextOverflow.ellipsis'), isTrue);
  });
}
