class AtlasEvent {
  AtlasEvent({
    required this.id,
    required this.type,
    required this.sourceModule,
    required this.title,
    required this.description,
    required this.occurredAt,
    required this.priority,
    this.farmId,
    this.farmName,
    this.entityId,
    this.entityType,
    this.payload = const <String, dynamic>{},
    this.tags = const <String>[],
  });

  final String id;
  final AtlasEventType type;

  final String sourceModule;
  final String title;
  final String description;

  final DateTime occurredAt;
  final AtlasEventPriority priority;

  final String? farmId;
  final String? farmName;

  final String? entityId;
  final String? entityType;

  final Map<String, dynamic> payload;
  final List<String> tags;

  bool get isCritical {
    return priority == AtlasEventPriority.critical;
  }

  bool get hasFarm {
    return farmId != null || farmName != null;
  }

  AtlasEvent copyWith({
    String? id,
    AtlasEventType? type,
    String? sourceModule,
    String? title,
    String? description,
    DateTime? occurredAt,
    AtlasEventPriority? priority,
    String? farmId,
    String? farmName,
    String? entityId,
    String? entityType,
    Map<String, dynamic>? payload,
    List<String>? tags,
  }) {
    return AtlasEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      sourceModule: sourceModule ?? this.sourceModule,
      title: title ?? this.title,
      description: description ?? this.description,
      occurredAt: occurredAt ?? this.occurredAt,
      priority: priority ?? this.priority,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      payload: payload ?? this.payload,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'sourceModule': sourceModule,
      'title': title,
      'description': description,
      'occurredAt': occurredAt.toIso8601String(),
      'priority': priority.name,
      'farmId': farmId,
      'farmName': farmName,
      'entityId': entityId,
      'entityType': entityType,
      'payload': payload,
      'tags': tags,
    };
  }

  factory AtlasEvent.fromJson(
    Map<String, dynamic> json,
  ) {
    return AtlasEvent(
      id: json['id'] as String,
      type: AtlasEventType.values.firstWhere(
        (item) => item.name == json['type'],
        orElse: () => AtlasEventType.systemUpdated,
      ),
      sourceModule: json['sourceModule'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      occurredAt: DateTime.parse(
        json['occurredAt'] as String,
      ),
      priority: AtlasEventPriority.values.firstWhere(
        (item) => item.name == json['priority'],
        orElse: () => AtlasEventPriority.normal,
      ),
      farmId: json['farmId'] as String?,
      farmName: json['farmName'] as String?,
      entityId: json['entityId'] as String?,
      entityType: json['entityType'] as String?,
      payload: Map<String, dynamic>.from(
        json['payload'] as Map? ??
            const <String, dynamic>{},
      ),
      tags: List<String>.from(
        json['tags'] as List? ??
            const <String>[],
      ),
    );
  }
}

enum AtlasEventType {
  animalCreated,
  animalUpdated,
  animalDeleted,
  animalWeightRecorded,

  reproductionEventCreated,
  pregnancyConfirmed,
  calvingRecorded,
  inseminationRecorded,

  healthEventCreated,
  vaccinationRecorded,
  treatmentRecorded,
  diseaseAlertCreated,

  financialEntryCreated,
  financialEntryUpdated,
  cashFlowUpdated,
  expenseLimitReached,

  inventoryItemCreated,
  inventoryItemUpdated,
  inventoryLowStock,
  inventoryOutOfStock,

  goalCreated,
  goalUpdated,
  goalCompleted,
  goalDelayed,

  taskCreated,
  taskUpdated,
  taskCompleted,
  taskDelayed,

  decisionCreated,
  decisionUpdated,
  decisionApproved,
  decisionCompleted,

  workflowCreated,
  workflowUpdated,
  workflowCompleted,
  workflowDelayed,

  executiveAlertCreated,
  executiveKpiUpdated,
  executiveBrainUpdated,
  missionControlUpdated,
  atlasOsUpdated,

  systemStarted,
  systemUpdated,
  systemError,
}

enum AtlasEventPriority {
  low,
  normal,
  high,
  critical,
}

String atlasEventTypeLabel(
  AtlasEventType type,
) {
  switch (type) {
    case AtlasEventType.animalCreated:
      return 'Animal criado';

    case AtlasEventType.animalUpdated:
      return 'Animal atualizado';

    case AtlasEventType.animalDeleted:
      return 'Animal removido';

    case AtlasEventType.animalWeightRecorded:
      return 'Pesagem registrada';

    case AtlasEventType.reproductionEventCreated:
      return 'Evento reprodutivo criado';

    case AtlasEventType.pregnancyConfirmed:
      return 'Prenhez confirmada';

    case AtlasEventType.calvingRecorded:
      return 'Parto registrado';

    case AtlasEventType.inseminationRecorded:
      return 'Inseminação registrada';

    case AtlasEventType.healthEventCreated:
      return 'Evento sanitário criado';

    case AtlasEventType.vaccinationRecorded:
      return 'Vacinação registrada';

    case AtlasEventType.treatmentRecorded:
      return 'Tratamento registrado';

    case AtlasEventType.diseaseAlertCreated:
      return 'Alerta sanitário criado';

    case AtlasEventType.financialEntryCreated:
      return 'Lançamento financeiro criado';

    case AtlasEventType.financialEntryUpdated:
      return 'Lançamento financeiro atualizado';

    case AtlasEventType.cashFlowUpdated:
      return 'Fluxo de caixa atualizado';

    case AtlasEventType.expenseLimitReached:
      return 'Limite de despesa atingido';

    case AtlasEventType.inventoryItemCreated:
      return 'Item de estoque criado';

    case AtlasEventType.inventoryItemUpdated:
      return 'Item de estoque atualizado';

    case AtlasEventType.inventoryLowStock:
      return 'Estoque baixo';

    case AtlasEventType.inventoryOutOfStock:
      return 'Estoque esgotado';

    case AtlasEventType.goalCreated:
      return 'Meta criada';

    case AtlasEventType.goalUpdated:
      return 'Meta atualizada';

    case AtlasEventType.goalCompleted:
      return 'Meta concluída';

    case AtlasEventType.goalDelayed:
      return 'Meta atrasada';

    case AtlasEventType.taskCreated:
      return 'Tarefa criada';

    case AtlasEventType.taskUpdated:
      return 'Tarefa atualizada';

    case AtlasEventType.taskCompleted:
      return 'Tarefa concluída';

    case AtlasEventType.taskDelayed:
      return 'Tarefa atrasada';

    case AtlasEventType.decisionCreated:
      return 'Decisão criada';

    case AtlasEventType.decisionUpdated:
      return 'Decisão atualizada';

    case AtlasEventType.decisionApproved:
      return 'Decisão aprovada';

    case AtlasEventType.decisionCompleted:
      return 'Decisão concluída';

    case AtlasEventType.workflowCreated:
      return 'Workflow criado';

    case AtlasEventType.workflowUpdated:
      return 'Workflow atualizado';

    case AtlasEventType.workflowCompleted:
      return 'Workflow concluído';

    case AtlasEventType.workflowDelayed:
      return 'Workflow atrasado';

    case AtlasEventType.executiveAlertCreated:
      return 'Alerta executivo criado';

    case AtlasEventType.executiveKpiUpdated:
      return 'KPI executivo atualizado';

    case AtlasEventType.executiveBrainUpdated:
      return 'Executive Brain atualizado';

    case AtlasEventType.missionControlUpdated:
      return 'Mission Control atualizado';

    case AtlasEventType.atlasOsUpdated:
      return 'Atlas OS atualizado';

    case AtlasEventType.systemStarted:
      return 'Sistema iniciado';

    case AtlasEventType.systemUpdated:
      return 'Sistema atualizado';

    case AtlasEventType.systemError:
      return 'Erro do sistema';
  }
}

String atlasEventPriorityLabel(
  AtlasEventPriority priority,
) {
  switch (priority) {
    case AtlasEventPriority.low:
      return 'Baixa';

    case AtlasEventPriority.normal:
      return 'Normal';

    case AtlasEventPriority.high:
      return 'Alta';

    case AtlasEventPriority.critical:
      return 'Crítica';
  }
}
