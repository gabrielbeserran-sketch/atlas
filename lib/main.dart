import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text_windows/speech_to_text_windows.dart';

import 'app.dart';
import 'core/errors/atlas_error_reporter.dart';
import 'core/widgets/atlas_error_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (defaultTargetPlatform == TargetPlatform.windows) {
    SpeechToTextWindows.registerWith();
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AtlasErrorReporter.report(
      details.exception,
      details.stack ?? StackTrace.current,
      context: 'flutter',
      fatal: false,
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AtlasErrorReporter.report(
      error,
      stackTrace,
      context: 'platform',
      fatal: true,
    );
    return true;
  };

  ErrorWidget.builder = (details) {
    return Material(
      child: AtlasErrorState(
        title: 'O Atlas encontrou um problema nesta tela',
        message:
            'Feche esta tela e tente novamente. '
            'Se o problema persistir, registre o momento e a operação realizada.',
      ),
    );
  };

  runApp(const AtlasApp());
}
