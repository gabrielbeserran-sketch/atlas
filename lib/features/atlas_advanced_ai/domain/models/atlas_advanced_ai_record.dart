enum AtlasAdvancedAiModule {
  conversationalAssistant,
  farmContextChat,
  healthDecisionSupport,
  reproductiveIntelligence,
  nutritionalIntelligence,
  geneticIntelligence,
  financialIntelligence,
  strategicIntelligence,
  climateIntelligence,
  explainableAi,
}

extension AtlasAdvancedAiModuleX on AtlasAdvancedAiModule {
  String get code => switch (this) {
    AtlasAdvancedAiModule.conversationalAssistant => 'conversational_assistant',
    AtlasAdvancedAiModule.farmContextChat => 'farm_context_chat',
    AtlasAdvancedAiModule.healthDecisionSupport => 'health_decision_support',
    AtlasAdvancedAiModule.reproductiveIntelligence =>
      'reproductive_intelligence',
    AtlasAdvancedAiModule.nutritionalIntelligence => 'nutritional_intelligence',
    AtlasAdvancedAiModule.geneticIntelligence => 'genetic_intelligence',
    AtlasAdvancedAiModule.financialIntelligence => 'financial_intelligence',
    AtlasAdvancedAiModule.strategicIntelligence => 'strategic_intelligence',
    AtlasAdvancedAiModule.climateIntelligence => 'climate_intelligence',
    AtlasAdvancedAiModule.explainableAi => 'explainable_ai',
  };

  String get title => switch (this) {
    AtlasAdvancedAiModule.conversationalAssistant => 'Assistente Atlas IA',
    AtlasAdvancedAiModule.farmContextChat => 'Chat Contextual da Fazenda',
    AtlasAdvancedAiModule.healthDecisionSupport => 'IA de Apoio Sanitário',
    AtlasAdvancedAiModule.reproductiveIntelligence => 'IA Reprodutiva',
    AtlasAdvancedAiModule.nutritionalIntelligence => 'IA Nutricional',
    AtlasAdvancedAiModule.geneticIntelligence => 'IA Genética',
    AtlasAdvancedAiModule.financialIntelligence => 'IA Financeira',
    AtlasAdvancedAiModule.strategicIntelligence => 'IA Estratégica',
    AtlasAdvancedAiModule.climateIntelligence => 'IA Climática Integrada',
    AtlasAdvancedAiModule.explainableAi => 'IA Explicável',
  };

  String get packageLabel => switch (this) {
    AtlasAdvancedAiModule.conversationalAssistant => 'Pacote 111',
    AtlasAdvancedAiModule.farmContextChat => 'Pacote 112',
    AtlasAdvancedAiModule.healthDecisionSupport => 'Pacote 113',
    AtlasAdvancedAiModule.reproductiveIntelligence => 'Pacote 114',
    AtlasAdvancedAiModule.nutritionalIntelligence => 'Pacote 115',
    AtlasAdvancedAiModule.geneticIntelligence => 'Pacote 116',
    AtlasAdvancedAiModule.financialIntelligence => 'Pacote 117',
    AtlasAdvancedAiModule.strategicIntelligence => 'Pacote 118',
    AtlasAdvancedAiModule.climateIntelligence => 'Pacote 119',
    AtlasAdvancedAiModule.explainableAi => 'Pacote 120',
  };

  List<String> get features => switch (this) {
    AtlasAdvancedAiModule.conversationalAssistant => const [
      'Perguntas e respostas',
      'Comandos assistidos',
      'Resumos automáticos',
      'Sugestões de ação',
      'Histórico de conversas',
    ],
    AtlasAdvancedAiModule.farmContextChat => const [
      'Contexto da propriedade',
      'Contexto do rebanho',
      'Contexto do animal',
      'Memória operacional',
      'Fontes e referências',
    ],
    AtlasAdvancedAiModule.healthDecisionSupport => const [
      'Sinais clínicos',
      'Hipóteses de triagem',
      'Prioridade sanitária',
      'Evidências e exames',
      'Encaminhamento veterinário',
    ],
    AtlasAdvancedAiModule.reproductiveIntelligence => const [
      'Indicadores reprodutivos',
      'Elegibilidade de protocolo',
      'Risco reprodutivo',
      'Agenda e oportunidades',
      'Recomendações assistidas',
    ],
    AtlasAdvancedAiModule.nutritionalIntelligence => const [
      'Demanda nutricional',
      'Consumo estimado',
      'Disponibilidade de alimento',
      'Custo da dieta',
      'Ajustes recomendados',
    ],
    AtlasAdvancedAiModule.geneticIntelligence => const [
      'Objetivos de seleção',
      'Informações genealógicas',
      'Indicadores genéticos',
      'Acasalamentos assistidos',
      'Risco de consanguinidade',
    ],
    AtlasAdvancedAiModule.financialIntelligence => const [
      'Análise de resultado',
      'Desvios financeiros',
      'Projeções e cenários',
      'Riscos econômicos',
      'Recomendações financeiras',
    ],
    AtlasAdvancedAiModule.strategicIntelligence => const [
      'Objetivos estratégicos',
      'Priorização',
      'Cenários futuros',
      'Riscos e dependências',
      'Plano de ação',
    ],
    AtlasAdvancedAiModule.climateIntelligence => const [
      'Dados meteorológicos',
      'Risco térmico',
      'Janela operacional',
      'Impacto em pastagens',
      'Alertas climáticos',
    ],
    AtlasAdvancedAiModule.explainableAi => const [
      'Motivos da recomendação',
      'Evidências utilizadas',
      'Limitações do modelo',
      'Confiança e incerteza',
      'Revisão humana',
    ],
  };
}

class AtlasAdvancedAiRecord {
  const AtlasAdvancedAiRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.responsible,
    required this.contextScope,
    required this.promptSummary,
    required this.recommendation,
    required this.evidence,
    required this.confidencePercent,
    required this.riskPercent,
    required this.estimatedImpact,
    required this.priority,
    required this.progressPercent,
    required this.alertCount,
    required this.reviewDate,
    required this.reference,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasAdvancedAiModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String responsible;
  final String contextScope;
  final String promptSummary;
  final String recommendation;
  final String evidence;
  final double confidencePercent;
  final double riskPercent;
  final double estimatedImpact;
  final int priority;
  final int progressPercent;
  final int alertCount;
  final String reviewDate;
  final String reference;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Bloqueado' ||
      status == 'Baixa confiança' ||
      status == 'Revisão obrigatória' ||
      status == 'Atenção';

  bool get isOperational =>
      status == 'Validado' ||
      status == 'Aprovado' ||
      status == 'Em acompanhamento' ||
      status == 'Concluído';

  bool get isReviewOverdue {
    final parsed = parseAtlasAdvancedAiDate(reviewDate);
    if (parsed.year == 1900) return false;

    return parsed.isBefore(DateTime.now()) && status != 'Concluído';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'responsible': responsible,
      'contextScope': contextScope,
      'promptSummary': promptSummary,
      'recommendation': recommendation,
      'evidence': evidence,
      'confidencePercent': confidencePercent,
      'riskPercent': riskPercent,
      'estimatedImpact': estimatedImpact,
      'priority': priority,
      'progressPercent': progressPercent,
      'alertCount': alertCount,
      'reviewDate': reviewDate,
      'reference': reference,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasAdvancedAiRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasAdvancedAiModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasAdvancedAiModule.conversationalAssistant,
    );

    return AtlasAdvancedAiRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Rascunho',
      responsible: map['responsible']?.toString() ?? '',
      contextScope: map['contextScope']?.toString() ?? '',
      promptSummary: map['promptSummary']?.toString() ?? '',
      recommendation: map['recommendation']?.toString() ?? '',
      evidence: map['evidence']?.toString() ?? '',
      confidencePercent: (map['confidencePercent'] as num?)?.toDouble() ?? 0.0,
      riskPercent: (map['riskPercent'] as num?)?.toDouble() ?? 0.0,
      estimatedImpact: (map['estimatedImpact'] as num?)?.toDouble() ?? 0.0,
      priority: (map['priority'] as num?)?.toInt() ?? 0,
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      reviewDate: map['reviewDate']?.toString() ?? '',
      reference: map['reference']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasAdvancedAiDate(String value) {
  final text = value.trim();
  if (text.isEmpty) return DateTime(1900);

  final iso = DateTime.tryParse(text);
  if (iso != null) return iso;

  final parts = text.split('/');
  if (parts.length != 3) return DateTime(1900);

  return DateTime(
    int.tryParse(parts[2]) ?? 1900,
    int.tryParse(parts[1]) ?? 1,
    int.tryParse(parts[0]) ?? 1,
  );
}

String formatAtlasAdvancedAiDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
