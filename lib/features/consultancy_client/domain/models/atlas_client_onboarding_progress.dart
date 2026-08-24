class AtlasClientOnboardingStep {
  const AtlasClientOnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.automatic,
  });

  final String id;
  final String title;
  final String description;
  final bool automatic;
}

class AtlasClientOnboardingEvidence {
  const AtlasClientOnboardingEvidence({
    required this.automatic,
    required this.verified,
    required this.detail,
  });

  final bool automatic;
  final bool verified;
  final String detail;

  factory AtlasClientOnboardingEvidence.fromMap(Map<String, dynamic> map) {
    return AtlasClientOnboardingEvidence(
      automatic: map['automatic'] == true,
      verified: map['verified'] == true,
      detail: map['detail']?.toString() ?? '',
    );
  }
}

class AtlasClientOnboardingProgress {
  const AtlasClientOnboardingProgress({
    required this.steps,
    required this.evidence,
    required this.completionPercent,
    this.farmId,
    this.completedAt,
  });

  static const List<AtlasClientOnboardingStep> canonicalSteps = [
    AtlasClientOnboardingStep(
      id: 'farm_context',
      title: 'Fazenda e contexto configurados',
      description: 'Dados da operação e fazenda principal revisados.',
      automatic: true,
    ),
    AtlasClientOnboardingStep(
      id: 'herd_baseline',
      title: 'Rebanho inicial conferido',
      description: 'Animais, lotes e identificação inicial validados.',
      automatic: true,
    ),
    AtlasClientOnboardingStep(
      id: 'technical_contact',
      title: 'Responsável técnico definido',
      description: 'Contato oficial da consultoria disponível no Atlas.',
      automatic: true,
    ),
    AtlasClientOnboardingStep(
      id: 'agenda_routine',
      title: 'Rotina e agenda inicial organizadas',
      description: 'Primeiras tarefas, visitas e manejos estão planejados.',
      automatic: true,
    ),
    AtlasClientOnboardingStep(
      id: 'initial_training',
      title: 'Treinamento inicial concluído',
      description: 'Equipe orientada para registrar e consultar dados no Atlas.',
      automatic: false,
    ),
  ];

  final String? farmId;
  final Map<String, bool> steps;
  final Map<String, AtlasClientOnboardingEvidence> evidence;
  final double completionPercent;
  final DateTime? completedAt;

  factory AtlasClientOnboardingProgress.empty() {
    return AtlasClientOnboardingProgress(
      steps: {for (final step in canonicalSteps) step.id: false},
      evidence: const {},
      completionPercent: 0,
    );
  }

  factory AtlasClientOnboardingProgress.fromMap(Map<String, dynamic> map) {
    final rawSteps = Map<String, dynamic>.from(
      (map['steps'] as Map?) ?? const <String, dynamic>{},
    );
    final rawEvidence = Map<String, dynamic>.from(
      (map['evidence'] as Map?) ?? const <String, dynamic>{},
    );
    final normalizedSteps = {
      for (final step in canonicalSteps) step.id: rawSteps[step.id] == true,
    };
    final normalizedEvidence = <String, AtlasClientOnboardingEvidence>{};
    for (final step in canonicalSteps) {
      final raw = rawEvidence[step.id];
      if (raw is Map) {
        normalizedEvidence[step.id] = AtlasClientOnboardingEvidence.fromMap(
          Map<String, dynamic>.from(raw),
        );
      }
    }

    final calculated = normalizedSteps.values.where((value) => value).length /
        normalizedSteps.length *
        100;
    final remotePercent = (map['completion_percent'] as num?)?.toDouble();

    return AtlasClientOnboardingProgress(
      farmId: map['farm_id']?.toString(),
      steps: normalizedSteps,
      evidence: normalizedEvidence,
      completionPercent: remotePercent ?? calculated,
      completedAt: DateTime.tryParse(map['completed_at']?.toString() ?? ''),
    );
  }

  bool isComplete(String stepId) => steps[stepId] == true;

  bool get complete => completionPercent >= 99.999;

  AtlasClientOnboardingEvidence? evidenceFor(String stepId) => evidence[stepId];

  AtlasClientOnboardingProgress copyWithManualStep(String stepId, bool value) {
    final step = canonicalSteps.where((item) => item.id == stepId).firstOrNull;
    if (step == null || step.automatic) return this;
    final updated = Map<String, bool>.from(steps)..[stepId] = value;
    final percent = updated.values.where((item) => item).length / updated.length * 100;
    return AtlasClientOnboardingProgress(
      farmId: farmId,
      steps: updated,
      evidence: evidence,
      completionPercent: percent,
      completedAt: percent >= 100 ? (completedAt ?? DateTime.now()) : null,
    );
  }
}
