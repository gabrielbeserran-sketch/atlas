import 'package:projeto_atlas/features/observability/domain/models/atlas_observability_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasObservabilityRepository {
  static const String _storageKey = 'atlas_observability_data_v1';

  Future<AtlasObservabilityData> load() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? saved = preferences.getString(_storageKey);
    if (saved == null || saved.isEmpty) {
      return _initialData();
    }
    try {
      return AtlasObservabilityData.fromJson(saved);
    } catch (_) {
      return _initialData();
    }
  }

  Future<void> save(AtlasObservabilityData data) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, data.toJson());
  }

  AtlasObservabilityData _initialData() {
    final DateTime now = DateTime.now();
    return AtlasObservabilityData(
      lastDiagnosticAt: null,
      healthChecks: <AtlasHealthCheck>[
        AtlasHealthCheck(
          id: 'integration',
          module: 'Integration Core',
          description: 'Comunicação central entre os módulos.',
          status: AtlasHealthStatus.healthy,
          responseTimeMs: 84,
          checkedAt: now,
        ),
        AtlasHealthCheck(
          id: 'sync',
          module: 'Sync & Cloud',
          description: 'Fila de sincronização e conectividade.',
          status: AtlasHealthStatus.warning,
          responseTimeMs: 218,
          checkedAt: now,
        ),
        AtlasHealthCheck(
          id: 'storage',
          module: 'Armazenamento local',
          description: 'Persistência e integridade dos dados locais.',
          status: AtlasHealthStatus.healthy,
          responseTimeMs: 46,
          checkedAt: now,
        ),
        AtlasHealthCheck(
          id: 'workflow',
          module: 'Workflow Automation',
          description: 'Execução das regras e ações automáticas.',
          status: AtlasHealthStatus.healthy,
          responseTimeMs: 112,
          checkedAt: now,
        ),
        AtlasHealthCheck(
          id: 'copilot',
          module: 'AI Copilot',
          description: 'Construção de contexto e análises inteligentes.',
          status: AtlasHealthStatus.warning,
          responseTimeMs: 306,
          checkedAt: now,
        ),
      ],
      logs: <AtlasSystemLog>[
        AtlasSystemLog(
          id: 'log_initial_1',
          module: 'Sync & Cloud',
          message: 'Um item permanece aguardando nova tentativa de envio.',
          level: AtlasLogLevel.warning,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        AtlasSystemLog(
          id: 'log_initial_2',
          module: 'Integration Core',
          message: 'Verificação de comunicação concluída com sucesso.',
          level: AtlasLogLevel.info,
          createdAt: now.subtract(const Duration(hours: 5)),
          resolved: true,
        ),
      ],
    );
  }
}
