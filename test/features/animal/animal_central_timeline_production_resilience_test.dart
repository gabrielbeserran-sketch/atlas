import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'lib/features/animal/presentation/screens/animal_detail_screen.dart',
  ).readAsStringSync();

  test('Central do Animal não possui timeout local de 6 ou 8 segundos', () {
    expect(source.contains('Duration(seconds: 6)'), isFalse);
    expect(source.contains('Duration(seconds: 8)'), isFalse);
    expect(source.contains('return await loader().timeout('), isFalse);
    expect(source.contains('return await loader();'), isTrue);
  });

  test('Central preserva fallback em falhas transitórias', () {
    expect(source.contains('required List<T> fallback'), isTrue);
    expect(source.contains('List<T>.unmodifiable(fallback)'), isTrue);
  });

  test('Timeline Enterprise usa cliente oficial sem timeout local', () {
    expect(source.contains("label: 'Timeline Enterprise'"), isTrue);
    expect(
      source.contains('ATLAS Animal Central [Timeline Enterprise]'),
      isTrue,
    );
  });
}
