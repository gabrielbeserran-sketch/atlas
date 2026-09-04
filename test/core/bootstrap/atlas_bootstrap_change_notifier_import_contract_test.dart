import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bootstrap runtime imports foundation for ChangeNotifier', () {
    final source = File(
      'lib/core/bootstrap/atlas_bootstrap_runtime.dart',
    ).readAsStringSync();

    expect(source, contains("package:flutter/foundation.dart"));
    expect(source, contains('extends ChangeNotifier'));
    expect(source, contains('notifyListeners()'));
  });
}
