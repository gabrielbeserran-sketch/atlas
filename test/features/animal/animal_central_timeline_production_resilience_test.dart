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

  test('Timeline Enterprise usa serviço oficial sem timeout local', () {
    expect(
      source.contains(
        'static const String _enterpriseTimelineLoadLabel =',
      ),
      isTrue,
    );
    expect(source.contains("'Timeline Enterprise';"), isTrue);
    expect(
      source.contains(
        'enterpriseTimelineService.loadTimeline(animal.id)',
      ),
      isTrue,
    );
    expect(
      source.contains('label: _enterpriseTimelineLoadLabel'),
      isTrue,
    );
    expect(
      source.contains(
        'enterpriseTimelineService.loadTimeline(animal.id).timeout(',
      ),
      isFalse,
    );
  });

  test('contrato da Timeline não depende de texto de log ou interface', () {
    expect(
      source.contains(
        'static const String _enterpriseTimelineLoadLabel =',
      ),
      isTrue,
    );
    expect(
      source.contains('label: _enterpriseTimelineLoadLabel'),
      isTrue,
    );

    // O contrato não deve exigir uma frase específica de debugPrint.
    // Logs podem mudar sem alterar o comportamento de rede.
    expect(
      source.contains(
        'enterpriseTimelineService.loadTimeline(animal.id)',
      ),
      isTrue,
    );
  });
}
