import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

final class AtlasErrorReporter {
  AtlasErrorReporter._();

  static void report(
    Object error,
    StackTrace stackTrace, {
    String context = 'runtime',
    bool fatal = false,
  }) {
    developer.log(
      'Atlas error [$context]',
      name: 'projeto_atlas',
      error: error,
      stackTrace: stackTrace,
      level: fatal ? 1200 : 1000,
    );

    if (kDebugMode) {
      debugPrint('Atlas error [$context]: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
