class AnimalEnterpriseTimelineData {
  const AnimalEnterpriseTimelineData({
    required this.id,
    required this.action,
    required this.category,
    required this.title,
    required this.description,
    required this.before,
    required this.after,
    required this.userId,
    required this.occurredAt,
  });

  final String id;
  final String action;
  final String category;
  final String title;
  final String description;
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  final String userId;
  final DateTime occurredAt;

  factory AnimalEnterpriseTimelineData.fromMap(Map<String, dynamic> map) {
    return AnimalEnterpriseTimelineData(
      id: map['id']?.toString() ?? '',
      action: map['action']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Auditoria',
      title: map['title']?.toString() ?? 'Evento auditado',
      description: map['description']?.toString() ?? '',
      before: Map<String, dynamic>.from(
        map['before'] as Map? ?? const <String, dynamic>{},
      ),
      after: Map<String, dynamic>.from(
        map['after'] as Map? ?? const <String, dynamic>{},
      ),
      userId: map['user_id']?.toString() ?? '',
      occurredAt:
          DateTime.tryParse(map['occurred_at']?.toString() ?? '') ??
          DateTime(1900),
    );
  }

  String get changesDescription {
    if (action != 'update') {
      return description;
    }

    final labels = <String, String>{
      'group_name': 'Lote',
      'tag': 'Brinco',
      'name': 'Nome',
      'sisbov': 'SISBOV',
      'category': 'Categoria',
      'sex': 'Sexo',
      'breed': 'Raça',
      'birth_date': 'Nascimento',
      'weight': 'Peso',
      'body_condition_score': 'Escore corporal',
      'status': 'Situação',
      'mother_tag': 'Mãe',
      'father_tag': 'Pai',
      'origin': 'Origem',
      'notes': 'Observações',
      'acquisition_type': 'Aquisição',
      'sale_value': 'Valor da venda',
    };

    final changes = <String>[];

    for (final entry in after.entries) {
      if (!before.containsKey(entry.key)) {
        continue;
      }

      final previous = before[entry.key];
      final current = entry.value;

      if (previous == current || entry.key == 'state_version') {
        continue;
      }

      final label = labels[entry.key] ?? entry.key;
      changes.add('$label: ${formatValue(previous)} → ${formatValue(current)}');
    }

    if (changes.isEmpty) {
      return description;
    }

    return changes.join('\n');
  }

  String formatValue(Object? value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'não informado';
    }

    if (value is double) {
      return value.toStringAsFixed(2).replaceAll('.', ',');
    }

    return value.toString();
  }
}
