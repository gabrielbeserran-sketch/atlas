class AtlasAiRecommendation {
  const AtlasAiRecommendation({
    required this.id,
    required this.area,
    required this.title,
    required this.description,
    required this.priority,
    required this.confidence,
    required this.action,
    required this.evidence,
    required this.limitations,
  });

  final String id;
  final String area;
  final String title;
  final String description;
  final String priority;
  final double confidence;
  final String action;
  final List<String> evidence;
  final List<String> limitations;

  factory AtlasAiRecommendation.fromMap(Map<String, dynamic> map) {
    List<String> strings(Object? value) => value is List
        ? value.map(_readableEvidence).toList(growable: false)
        : const [];
    return AtlasAiRecommendation(
      id: map['id']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Recomendação',
      description: map['description']?.toString() ?? '',
      priority: map['priority']?.toString() ?? 'normal',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      action: map['recommended_action']?.toString() ?? '',
      evidence: strings(map['evidence']),
      limitations: strings(map['limitations']),
    );
  }

  static String _readableEvidence(Object? value) {
    if (value is! Map) return value?.toString() ?? '';
    final data = Map<String, dynamic>.from(value);
    final parts = <String>[];

    void add(String label, Object? item) {
      if (item != null) parts.add('$label: $item');
    }

    final herd = data['herd'];
    if (herd is Map) {
      final values = Map<String, dynamic>.from(herd);
      add('Rebanho ativo', values['active_animals']);
      add('Fêmeas', values['females']);
      add('Com peso atual', values['with_current_weight']);
    }

    final reproduction = data['reproduction'];
    if (reproduction is Map) {
      final values = Map<String, dynamic>.from(reproduction);
      add('Eventos reprodutivos', values['events']);
      add('Prenhes registradas', values['pregnant']);
    }

    final health = data['health'];
    if (health is Map) add('Eventos sanitários', health['events']);
    final nutrition = data['nutrition'];
    if (nutrition is Map) add('Registros nutricionais', nutrition['events']);
    final finance = data['finance'];
    if (finance is Map) add('Lançamentos financeiros', finance['entries']);

    final quality = data['quality'] ?? data;
    if (quality is Map) {
      add(
        'Cobertura de pesagem',
        quality['weight_coverage_percent'] == null
            ? null
            : '${quality['weight_coverage_percent']}%',
      );
      add('Animais cadastrados', quality['animal_count']);
    }

    if (parts.isNotEmpty) return parts.join(' • ');
    return data.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(' • ');
  }
}

class AtlasAiSimulation {
  const AtlasAiSimulation({
    required this.projectedVariation,
    required this.confidence,
    this.roiPercent,
  });
  final double projectedVariation;
  final double? roiPercent;
  final double confidence;

  factory AtlasAiSimulation.fromMap(Map<String, dynamic> map) =>
      AtlasAiSimulation(
        projectedVariation:
            (map['projected_variation'] as num?)?.toDouble() ?? 0,
        roiPercent: (map['roi_percent'] as num?)?.toDouble(),
        confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      );
}
