import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:projeto_atlas/core/errors/atlas_error_reporter.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_runtime.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_runtime.dart';
import 'package:projeto_atlas/features/unified_workflow/domain/services/atlas_unified_workflow_engine.dart';

enum AtlasBootstrapStage {
  idle,
  firstFrameReady,
  pluginsReady,
  runtimesReady,
  degraded,
}

class AtlasBootstrapRuntime extends ChangeNotifier {
  AtlasBootstrapRuntime._();

  static final AtlasBootstrapRuntime instance = AtlasBootstrapRuntime._();

  AtlasBootstrapStage _stage = AtlasBootstrapStage.idle;
  final List<String> _warnings = <String>[];
  bool _started = false;

  AtlasBootstrapStage get stage => _stage;
  List<String> get warnings => List.unmodifiable(_warnings);
  bool get isStarted => _started;
  bool get isDegraded => _stage == AtlasBootstrapStage.degraded;

  void markFirstFrameReady() {
    if (_stage == AtlasBootstrapStage.idle) {
      _stage = AtlasBootstrapStage.firstFrameReady;
      notifyListeners();
    }
  }

  Future<void> startDeferred() async {
    if (_started) return;
    _started = true;
    markFirstFrameReady();

    if (_warnings.isEmpty) {
      _stage = AtlasBootstrapStage.pluginsReady;
      notifyListeners();
    }

    await _guard(
      'reactive-runtime',
      () async {
        AtlasReactiveRuntime.instance.start();
      },
      timeout: const Duration(seconds: 4),
    );

    await _guard(
      'command-center-runtime',
      () async {
        AtlasCommandCenterRuntime.instance.start();
      },
      timeout: const Duration(seconds: 4),
    );

    await _guard(
      'unified-workflow-runtime',
      () => AtlasUnifiedWorkflowEngine.instance.start(),
      timeout: const Duration(seconds: 6),
    );

    _stage = _warnings.isEmpty
        ? AtlasBootstrapStage.runtimesReady
        : AtlasBootstrapStage.degraded;
    notifyListeners();
  }

  Future<void> _guard(
    String name,
    FutureOr<void> Function() action, {
    required Duration timeout,
  }) async {
    try {
      await Future<void>.sync(action).timeout(timeout);
    } catch (error, stackTrace) {
      _warnings.add('$name: $error');
      _stage = AtlasBootstrapStage.degraded;
      notifyListeners();

      AtlasErrorReporter.report(
        error,
        stackTrace,
        context: 'bootstrap:$name',
        fatal: false,
      );
    }
  }

  void stop() {
    try {
      AtlasUnifiedWorkflowEngine.instance.stop();
    } catch (_) {}
    try {
      AtlasCommandCenterRuntime.instance.stop();
    } catch (_) {}
    try {
      AtlasReactiveRuntime.instance.stop();
    } catch (_) {}
    _started = false;
  }
}
