import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'atlas_orchestrator_models.dart';

class AtlasOrchestratorRepository {
  static const String _tasksKey = 'atlas_orchestrator_tasks_v1';
  static const String _runsKey = 'atlas_orchestrator_runs_v1';

  Future<List<AtlasOrchestratorTask>> loadTasks() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw = preferences.getString(_tasksKey);
    if (raw == null || raw.isEmpty) {
      return defaultTasks();
    }
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (dynamic item) => AtlasOrchestratorTask.fromJson(
            Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
          ),
        )
        .toList();
  }

  Future<void> saveTasks(List<AtlasOrchestratorTask> tasks) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _tasksKey,
      jsonEncode(
        tasks.map((AtlasOrchestratorTask task) => task.toJson()).toList(),
      ),
    );
  }

  Future<List<AtlasOrchestratorRun>> loadRuns() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw = preferences.getString(_runsKey);
    if (raw == null || raw.isEmpty) {
      return <AtlasOrchestratorRun>[];
    }
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (dynamic item) => AtlasOrchestratorRun.fromJson(
            Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
          ),
        )
        .toList();
  }

  Future<void> saveRuns(List<AtlasOrchestratorRun> runs) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _runsKey,
      jsonEncode(
        runs.take(20).map((AtlasOrchestratorRun run) => run.toJson()).toList(),
      ),
    );
  }

  List<AtlasOrchestratorTask> defaultTasks() => const <AtlasOrchestratorTask>[
    AtlasOrchestratorTask(
      id: 'collect',
      name: 'Coleta de dados',
      module: 'Integration Core',
      order: 1,
      enabled: true,
      status: AtlasPipelineStatus.idle,
      durationMs: 0,
    ),
    AtlasOrchestratorTask(
      id: 'validate',
      name: 'Validação do contexto',
      module: 'Data Governance',
      order: 2,
      enabled: true,
      status: AtlasPipelineStatus.idle,
      durationMs: 0,
    ),
    AtlasOrchestratorTask(
      id: 'consolidate',
      name: 'Consolidação operacional',
      module: 'Digital Twin',
      order: 3,
      enabled: true,
      status: AtlasPipelineStatus.idle,
      durationMs: 0,
    ),
    AtlasOrchestratorTask(
      id: 'analytics',
      name: 'Execução analítica',
      module: 'Business Intelligence',
      order: 4,
      enabled: true,
      status: AtlasPipelineStatus.idle,
      durationMs: 0,
    ),
    AtlasOrchestratorTask(
      id: 'decision',
      name: 'Priorização de decisões',
      module: 'Executive Brain',
      order: 5,
      enabled: true,
      status: AtlasPipelineStatus.idle,
      durationMs: 0,
    ),
    AtlasOrchestratorTask(
      id: 'automation',
      name: 'Distribuição de ações',
      module: 'Workflow Automation',
      order: 6,
      enabled: true,
      status: AtlasPipelineStatus.idle,
      durationMs: 0,
    ),
    AtlasOrchestratorTask(
      id: 'audit',
      name: 'Auditoria e observabilidade',
      module: 'Observability',
      order: 7,
      enabled: true,
      status: AtlasPipelineStatus.idle,
      durationMs: 0,
    ),
  ];
}
