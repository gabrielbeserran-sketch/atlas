import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'session gate provides bounded loading and recoverable failure states',
    () {
      final source = File(
        'lib/core/session/atlas_session_gate.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('body: const SafeArea(')));
      expect(
        source,
        contains('constraints: const BoxConstraints(maxWidth: 540)'),
      );
      expect(source, contains('padding: const EdgeInsets.all(28)'));
      // O controlador é a única autoridade para o limite de restauração. Um
      // segundo timeout no gate interromperia uma sessão válida durante cold start.
      expect(source, isNot(contains('timeout(const Duration(seconds: 30))')));
      expect(source, contains('await controller.restore();'));
      expect(
        source,
        contains('class _StartupFailureScreen extends StatelessWidget'),
      );
      expect(source, contains("child: const Text('Tentar novamente')"));
    },
  );
}
