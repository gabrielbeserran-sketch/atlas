import 'dart:ui';

import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);

    debugPrint('ATLAS FLUTTER ERROR: ${details.exceptionAsString()}');

    final stack = details.stack;

    if (stack != null) {
      debugPrintStack(label: 'ATLAS FLUTTER STACK', stackTrace: stack);
    }
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    debugPrint('ATLAS PLATFORM ERROR: $error');

    debugPrintStack(label: 'ATLAS PLATFORM STACK', stackTrace: stackTrace);

    /*
     * false é proposital.
     *
     * Durante a estabilização do bootstrap, uma exceção fatal não pode ser
     * silenciosamente considerada tratada.
     */
    return false;
  };

  ErrorWidget.builder = (details) {
    return Material(
      color: const Color(0xFFF4F6F4),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 54,
                    color: Color(0xFFB42318),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'O Atlas encontrou um problema de interface',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    details.exceptionAsString(),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  };

  runApp(const AtlasApp());
}
