import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Windows cold start keeps safe splash and isolates voice invocation',
    () {
      final app = File('lib/app.dart').readAsStringSync();
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final voice = File(
        'lib/features/dr_beserra/data/services/dr_beserra_voice_service.dart',
      ).readAsStringSync();

      expect(app, contains('class _AtlasFirstFrame extends StatelessWidget'));
      expect(app, contains('Preparando o ambiente...'));
      expect(app, contains('class _AtlasStartupFailure extends StatelessWidget'));

      expect(pubspec, contains('speech_to_text: ^7.4.0'));
      expect(pubspec, contains('speech_to_text_windows:'));
      expect(
        pubspec,
        contains('path: third_party/speech_to_text_windows_stub'),
      );

      expect(
        voice,
        contains('defaultTargetPlatform == TargetPlatform.windows'),
      );
      expect(
        voice,
        contains(
          'Reconhecimento de voz está temporariamente indisponível no Windows.',
        ),
      );
    },
  );
}
