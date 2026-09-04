import 'dart:async';

import 'package:flutter/material.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_runtime.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_scope.dart';
import 'package:projeto_atlas/core/reactivity/atlas_reactive_runtime.dart';
import 'package:projeto_atlas/features/unified_workflow/domain/services/atlas_unified_workflow_engine.dart';

import 'core/session/atlas_session_gate.dart';
import 'shared/theme/app_theme.dart';

class AtlasApp extends StatefulWidget {
  const AtlasApp({super.key});

  @override
  State<AtlasApp> createState() => _AtlasAppState();
}

class _AtlasAppState extends State<AtlasApp> {
  bool _operationalLayerEnabled = false;
  bool _startupScheduled = false;
  Timer? _operationalLayerTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scheduleOperationalLayer(),
    );
  }

  void _scheduleOperationalLayer() {
    if (!mounted || _startupScheduled) {
      return;
    }

    _startupScheduled = true;

    /*
     * O frame inicial precisa chegar ao compositor Windows antes de qualquer
     * infraestrutura do Atlas.
     */
    _operationalLayerTimer = Timer(const Duration(milliseconds: 900), () {
      _operationalLayerTimer = null;

      if (!mounted) {
        return;
      }

      setState(() {
        _operationalLayerEnabled = true;
      });

      unawaited(_startBackgroundRuntimes());
    });
  }

  Future<void> _startBackgroundRuntimes() async {
    try {
      AtlasReactiveRuntime.instance.start();
    } catch (error, stackTrace) {
      debugPrint('ATLAS ReactiveRuntime startup: $error');

      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      AtlasCommandCenterRuntime.instance.start();
    } catch (error, stackTrace) {
      debugPrint('ATLAS CommandCenterRuntime startup: $error');

      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      await AtlasUnifiedWorkflowEngine.instance.start().timeout(
        const Duration(seconds: 8),
      );
    } catch (error, stackTrace) {
      debugPrint('ATLAS UnifiedWorkflow startup: $error');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _operationalLayerTimer?.cancel();

    try {
      AtlasUnifiedWorkflowEngine.instance.stop();
    } catch (_) {}

    try {
      AtlasCommandCenterRuntime.instance.stop();
    } catch (_) {}

    try {
      AtlasReactiveRuntime.instance.stop();
    } catch (_) {}

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_operationalLayerEnabled) {
      return const MaterialApp(
        title: 'Projeto Atlas',
        debugShowCheckedModeBanner: false,
        home: _AtlasFirstFrame(),
      );
    }

    return MaterialApp(
      title: 'Projeto Atlas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AtlasOperationalRoot(),
    );
  }
}

class _AtlasFirstFrame extends StatelessWidget {
  const _AtlasFirstFrame();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: ValueKey<String>('atlas-first-frame'),
      backgroundColor: Color(0xFFF4F6F4),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF123F2D),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Projeto Atlas',
              style: TextStyle(
                color: Color(0xFF123F2D),
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Preparando o ambiente...',
              style: TextStyle(color: Color(0xFF66736C), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtlasOperationalRoot extends StatelessWidget {
  const _AtlasOperationalRoot();

  @override
  Widget build(BuildContext context) {
    try {
      /*
       * AtlasCommandCenterScope instancia AtlasCommandCenterRuntime.instance.
       * Por isso ele só pode entrar DEPOIS do primeiro frame.
       */
      return AtlasCommandCenterScope(child: const AtlasSessionGate());
    } catch (error, stackTrace) {
      debugPrint('ATLAS operational root: $error');

      debugPrintStack(stackTrace: stackTrace);

      return _AtlasStartupFailure(message: error.toString());
    }
  }
}

class _AtlasStartupFailure extends StatelessWidget {
  const _AtlasStartupFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 54,
                  color: Color(0xFFB54708),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Falha ao iniciar os serviços do Atlas',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
