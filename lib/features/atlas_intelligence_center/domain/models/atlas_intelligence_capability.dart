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
    this.nativeTabIndex,
  });

  final AtlasIntelligenceCapabilityFamily family;
  final String title;
  final String description;

  /// Nomes históricos preservados para auditoria e reconciliação.
  ///
  /// Não devem voltar a ser usados como portas concorrentes no menu.
  final List<String> legacyImplementations;

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
    ),
    AtlasIntelligenceCapabilityDefinition(
      family: AtlasIntelligenceCapabilityFamily.diagnosis,
      title: 'Diagnóstico e risco',
      description:
          'Identifique riscos, prioridades e pontos críticos com evidências.',
      legacyImplementations: ['Diagnóstico Inteligente', 'Diagnostics'],
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
      nativeTabIndex: 0,
    ),
  ];

  static AtlasIntelligenceCapabilityDefinition byFamily(
    AtlasIntelligenceCapabilityFamily family,
  ) {
    return canonical.firstWhere((item) => item.family == family);
  }
}
