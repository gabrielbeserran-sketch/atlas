import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('11C.3.8 startup contracts are consolidated', () {
    final app=File('lib/app.dart').readAsStringSync();
    final boot=File('lib/core/bootstrap/atlas_bootstrap_runtime.dart').readAsStringSync();
    final session=File('lib/core/session/atlas_session_gate.dart').readAsStringSync();
    expect(app,contains('class AtlasApp extends StatefulWidget'));
    expect(app,contains('State<AtlasApp> createState()'));
    expect(boot,contains("package:flutter/foundation.dart"));
    expect(boot,contains('extends ChangeNotifier'));
    expect(session,isNot(contains('body: const SafeArea(')));
  });
}
