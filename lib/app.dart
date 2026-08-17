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
  State<AtlasApp> createState() {
    return _AtlasAppState();
  }
}

class _AtlasAppState extends State<AtlasApp> {
  @override
  void initState() {
    super.initState();
    AtlasReactiveRuntime.instance.start();
    AtlasCommandCenterRuntime.instance.start();
    AtlasUnifiedWorkflowEngine.instance.start();
  }

  @override
  void dispose() {
    AtlasUnifiedWorkflowEngine.instance.stop();
    AtlasCommandCenterRuntime.instance.stop();
    AtlasReactiveRuntime.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AtlasCommandCenterScope(
      child: MaterialApp(
        title: 'Projeto Atlas',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AtlasSessionGate(),
      ),
    );
  }
}
