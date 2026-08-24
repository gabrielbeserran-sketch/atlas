class AtlasClientOnboardingStep {
  const AtlasClientOnboardingStep({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;
}

class AtlasClientOnboardingProgress {
  const AtlasClientOnboardingProgress({
    required this.steps,
    required this.completionPercent,
    this.completedAt,
  });

  static const List<AtlasClientOnboardingStep> canonicalSteps = [
    AtlasClientOnboardingStep(
      id: 'farm_context',
      title: 'Fazenda e contexto configurados',
      description: 'Dados da operação e fazenda principal revisados.',
    ),
    AtlasClientOnboardingStep(
      id: 'herd_baseline',
      title: 'Rebanho inicial conferido',
      description: 'Animais, lotes e identificação inicial validados.',
    ),
    AtlasClientOnboardingStep(
      id: 'technical_contact',
      title: 'Responsável técnico definido',
      description: 'Contato oficial da consultoria disponível no Atlas.',
    ),
    AtlasClientOnboardingStep(
      id: 'agenda_routine',
      title: 'Rotina e agenda inicial organizadas',
      description: 'Primeiras tarefas, visitas e manejos estão planejados.',
    ),
    AtlasClientOnboardingStep(
      id: 'initial_training',
      title: 'Treinamento inicial concluído',
      description: 'Equipe orientada para registrar e consultar dados no Atlas.',
    ),
  ];

  final Map<String, bool> steps;
  final double completionPercent;
  final DateTime? completedAt;

  factory AtlasClientOnboardingProgress.empty() {
    return AtlasClientOnboardingProgress(
      steps: {
        for (final step in canonicalSteps) step.id: false,
      },
      completionPercent: 0,
    );
  }

  factory AtlasClientOnboardingProgress.fromMap(Map<String, dynamic> map) {
    final rawSteps = Map<String, dynamic>.from(
      (map['steps'] as Map?) ?? const <String, dynamic>{},
    );
    final normalizedSteps = {
      for (final step in canonicalSteps)
        step.id: rawSteps[step.id] == true,
    };

    final calculated = normalizedSteps.isEmpty
        ? 0.0
        : normalizedSteps.values.where((value) => value).length /
            normalizedSteps.length *
            100;
    final remotePercent = (map['completion_percent'] as num?)?.toDouble();

    return AtlasClientOnboardingProgress(
      steps: normalizedSteps,
      completionPercent: remotePercent ?? calculated,
      completedAt: DateTime.tryParse(map['completed_at']?.toString() ?? ''),
    );
  }

  bool isComplete(String stepId) => steps[stepId] == true;

  bool get complete => completionPercent >= 99.999;

  AtlasClientOnboardingProgress copyWithStep(String stepId, bool value) {
    final updated = Map<String, bool>.from(steps)..[stepId] = value;
    final percent = updated.isEmpty
        ? 0.0
        : updated.values.where((item) => item).length / updated.length * 100;
    return AtlasClientOnboardingProgress(
      steps: updated,
      completionPercent: percent,
      completedAt: percent >= 100 ? (completedAt ?? DateTime.now()) : null,
    );
  }
}
