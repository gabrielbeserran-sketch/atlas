/// Taxonomia canônica das capacidades de inteligência do Atlas.
///
/// Uma capacidade representa o que o usuário quer fazer. Telas e engines
/// históricas são implementações dessas capacidades e não produtos paralelos.
enum AtlasIntelligenceCapabilityFamily {
  conversation,
  diagnosis,
  prediction,
  decision,
  executive,
}

class AtlasIntelligenceCapabilityDefinition {
  const AtlasIntelligenceCapabilityDefinition({
    required this.family,
    required this.title,
    required this.description,
    required this.legacyImplementations,
    required this.implementationRoots,
    this.nativeTabIndex,
  });

  final AtlasIntelligenceCapabilityFamily family;
  final String title;
  final String description;

  /// Nomes históricos preservados para auditoria e reconciliação.
  ///
  /// Não devem voltar a ser usados como portas concorrentes no menu.
  final List<String> legacyImplementations;

  /// Pacotes que implementam ou implementaram esta capacidade.
  ///
  /// Esta lista é uma fronteira de arquitetura: um pacote pode continuar a
  /// existir enquanto for necessário, mas não ganha uma rota principal só por
  /// existir no repositório.
  final List<String> implementationRoots;

  /// Aba da Central que oferece a capacidade nativamente, quando aplicável.
  final int? nativeTabIndex;
}

abstract final class AtlasIntelligenceCapabilityRegistry {
  static const List<AtlasIntelligenceCapabilityDefinition> canonical = [
    AtlasIntelligenceCapabilityDefinition(
      family: AtlasIntelligenceCapabilityFamily.conversation,
      title: 'Conversação Atlas',
      description:
          'Pergunte em linguagem natural e use o contexto oficial da fazenda.',
      legacyImplementations: ['Atlas IA', 'Atlas AI 2', 'Atlas AI Enterprise'],
      implementationRoots: [
        'atlas_ai',
        'atlas_ai_2',
        'atlas_ai_enterprise',
        'atlas_advanced_ai',
        'copilot',
      ],
    ),
    AtlasIntelligenceCapabilityDefinition(
      family: AtlasIntelligenceCapabilityFamily.diagnosis,
      title: 'Diagnóstico e risco',
      description:
          'Identifique riscos, prioridades e pontos críticos com evidências.',
      legacyImplementations: ['Diagnóstico Inteligente', 'Diagnostics'],
      implementationRoots: ['diagnostics'],
      nativeTabIndex: 1,
    ),
    AtlasIntelligenceCapabilityDefinition(
      family: AtlasIntelligenceCapabilityFamily.prediction,
      title: 'Predição e simulação',
      description:
          'Compare cenários e projeções antes de executar uma decisão.',
      legacyImplementations: [
        'Inteligência Preditiva',
        'Predictive',
        'Predictive AI',
        'Predictive Analytics',
        'Atlas Predictive AI Suite',
      ],
      implementationRoots: [
        'predictive',
        'predictive_ai',
        'predictive_analytics',
        'atlas_predictive_ai_suite',
        'scenario_simulator',
        'strategic_scenario_planning',
        'optimization_engine',
      ],
      nativeTabIndex: 3,
    ),
    AtlasIntelligenceCapabilityDefinition(
      family: AtlasIntelligenceCapabilityFamily.decision,
      title: 'Decisão e recomendação',
      description: 'Transforme sinais em prioridades e ações supervisionadas.',
      legacyImplementations: [
        'Decision Engine',
        'Decision Engine V2',
        'Recommendation Intelligence',
      ],
      implementationRoots: [
        'decision_intelligence_lab',
        'recommendation_intelligence',
        'command_center',
        'atlas_autonomous_enterprise',
        'autonomous_consultant',
      ],
      nativeTabIndex: 4,
    ),
    AtlasIntelligenceCapabilityDefinition(
      family: AtlasIntelligenceCapabilityFamily.executive,
      title: 'Inteligência executiva',
      description: 'Consolide indicadores e leitura gerencial da propriedade.',
      legacyImplementations: [
        'Inteligência da Fazenda',
        'Executive AI Advisor',
        'Executive Brain',
      ],
      implementationRoots: [
        'atlas_intelligence',
        'atlas_intelligence_reports_experience',
        'atlas_executive_intelligence',
        'executive_intelligence',
        'executive_brain',
        'executive_ai_advisor',
        'data_intelligence',
        'performance_intelligence',
      ],
      nativeTabIndex: 0,
    ),
  ];

  static AtlasIntelligenceCapabilityDefinition byFamily(
    AtlasIntelligenceCapabilityFamily family,
  ) {
    return canonical.firstWhere((item) => item.family == family);
  }

  /// Capacidades de análise que pertencem ao módulo dono do dado, não à
  /// Central de Inteligência. A Central pode apontar para elas, mas não deve
  /// duplicar suas telas nem colocá-las como itens de menu próprios.
  static const Map<String, String> domainOwnedImplementationRoots = {
    'animal_intelligence_360': 'Rebanho',
    'animal_weight_intelligence': 'Rebanho',
    'atlas_reproductive_ai': 'Reprodução',
    'atlas_veterinary_ai': 'Sanidade',
    'atlas_supply_chain': 'Estoque',
    'atlas_land_intelligence': 'Campo',
    'atlas_environmental_ai': 'Campo',
    'atlas_sustainability_ecosystem': 'Campo',
    'atlas_sustainability_enterprise': 'Campo',
  };

  static Set<String> get centralImplementationRoots =>
      canonical.expand((definition) => definition.implementationRoots).toSet();

  static Set<String> get auditedImplementationRoots => {
    ...centralImplementationRoots,
    ...domainOwnedImplementationRoots.keys,
  };
}
