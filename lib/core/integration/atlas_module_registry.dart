import 'atlas_integration_module.dart';

class AtlasModuleRegistry {
  AtlasModuleRegistry._();

  static final AtlasModuleRegistry instance = AtlasModuleRegistry._();

  final List<AtlasIntegrationModule> _modules = <AtlasIntegrationModule>[
    AtlasIntegrationModule(
      id: 'command_center',
      name: 'Command Center',
      category: 'Gestão',
      description: 'Briefing, prioridades e tarefas executivas.',
      isEnabled: true,
      isHealthy: true,
      pendingEvents: 2,
      lastActivity: DateTime.now(),
    ),
    AtlasIntegrationModule(
      id: 'digital_twin',
      name: 'Digital Twin',
      category: 'Inteligência',
      description: 'Representação consolidada da propriedade.',
      isEnabled: true,
      isHealthy: true,
      pendingEvents: 1,
      lastActivity: DateTime.now(),
    ),
    AtlasIntegrationModule(
      id: 'workflow',
      name: 'Workflow Automation',
      category: 'Automação',
      description: 'Regras, gatilhos e execuções automáticas.',
      isEnabled: true,
      isHealthy: true,
      pendingEvents: 3,
      lastActivity: DateTime.now(),
    ),
    AtlasIntegrationModule(
      id: 'sync',
      name: 'Sync & Cloud',
      category: 'Infraestrutura',
      description: 'Fila central de sincronização e conflitos.',
      isEnabled: true,
      isHealthy: true,
      pendingEvents: 4,
      lastActivity: DateTime.now(),
    ),
    AtlasIntegrationModule(
      id: 'reporting',
      name: 'Reporting',
      category: 'Documentos',
      description: 'Relatórios técnicos e executivos.',
      isEnabled: true,
      isHealthy: true,
      pendingEvents: 0,
      lastActivity: DateTime.now(),
    ),
    AtlasIntegrationModule(
      id: 'copilot',
      name: 'AI Copilot',
      category: 'Inteligência',
      description: 'Contexto inteligente e apoio à decisão.',
      isEnabled: true,
      isHealthy: true,
      pendingEvents: 1,
      lastActivity: DateTime.now(),
    ),
    AtlasIntegrationModule(
      id: 'governance',
      name: 'Data Governance',
      category: 'Segurança',
      description: 'Backup, recuperação e integridade de dados.',
      isEnabled: true,
      isHealthy: true,
      pendingEvents: 0,
      lastActivity: DateTime.now(),
    ),
    AtlasIntegrationModule(
      id: 'enterprise',
      name: 'Enterprise Platform',
      category: 'Administração',
      description: 'Empresas, usuários, permissões e auditoria.',
      isEnabled: true,
      isHealthy: true,
      pendingEvents: 0,
      lastActivity: DateTime.now(),
    ),
  ];

  List<AtlasIntegrationModule> get modules =>
      List<AtlasIntegrationModule>.unmodifiable(_modules);

  void toggle(String id) {
    final int index = _modules.indexWhere((AtlasIntegrationModule item) => item.id == id);
    if (index < 0) {
      return;
    }
    final AtlasIntegrationModule current = _modules[index];
    _modules[index] = current.copyWith(isEnabled: !current.isEnabled);
  }

  void markAllHealthy() {
    for (int index = 0; index < _modules.length; index++) {
      _modules[index] = _modules[index].copyWith(
        isHealthy: true,
        pendingEvents: 0,
        lastActivity: DateTime.now(),
      );
    }
  }
}
