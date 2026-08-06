import 'package:projeto_atlas/core/events/atlas_event.dart';

class AtlasAutomationRule {
  const AtlasAutomationRule({
    required this.id,
    required this.title,
    required this.description,
    required this.triggerType,
    required this.actionType,
    required this.actionTitle,
    required this.enabled,
    required this.priority,
    this.sourceModule,
  });

  final String id;
  final String title;
  final String description;
  final AtlasEventType triggerType;
  final AtlasAutomationActionType actionType;
  final String actionTitle;
  final bool enabled;
  final AtlasEventPriority priority;
  final String? sourceModule;

  AtlasAutomationRule copyWith({
    String? title,
    String? description,
    AtlasEventType? triggerType,
    AtlasAutomationActionType? actionType,
    String? actionTitle,
    bool? enabled,
    AtlasEventPriority? priority,
    String? sourceModule,
    bool clearSourceModule = false,
  }) {
    return AtlasAutomationRule(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      triggerType: triggerType ?? this.triggerType,
      actionType: actionType ?? this.actionType,
      actionTitle: actionTitle ?? this.actionTitle,
      enabled: enabled ?? this.enabled,
      priority: priority ?? this.priority,
      sourceModule: clearSourceModule ? null : sourceModule ?? this.sourceModule,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'description': description,
        'triggerType': triggerType.name,
        'actionType': actionType.name,
        'actionTitle': actionTitle,
        'enabled': enabled,
        'priority': priority.name,
        'sourceModule': sourceModule,
      };

  factory AtlasAutomationRule.fromJson(Map<String, dynamic> json) {
    return AtlasAutomationRule(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Automação',
      description: json['description'] as String? ?? '',
      triggerType: AtlasEventType.values.firstWhere(
        (item) => item.name == json['triggerType'],
        orElse: () => AtlasEventType.systemUpdated,
      ),
      actionType: AtlasAutomationActionType.values.firstWhere(
        (item) => item.name == json['actionType'],
        orElse: () => AtlasAutomationActionType.createNotification,
      ),
      actionTitle: json['actionTitle'] as String? ?? 'Ação automática',
      enabled: json['enabled'] as bool? ?? true,
      priority: AtlasEventPriority.values.firstWhere(
        (item) => item.name == json['priority'],
        orElse: () => AtlasEventPriority.normal,
      ),
      sourceModule: json['sourceModule'] as String?,
    );
  }
}

enum AtlasAutomationActionType {
  createTask,
  createNotification,
  recalculateIndicators,
  updateExecutiveBrain,
  createLearningCase,
  runPrediction,
}

String atlasAutomationActionLabel(AtlasAutomationActionType type) {
  switch (type) {
    case AtlasAutomationActionType.createTask:
      return 'Criar tarefa';
    case AtlasAutomationActionType.createNotification:
      return 'Criar notificação';
    case AtlasAutomationActionType.recalculateIndicators:
      return 'Recalcular indicadores';
    case AtlasAutomationActionType.updateExecutiveBrain:
      return 'Atualizar Executive Brain';
    case AtlasAutomationActionType.createLearningCase:
      return 'Registrar aprendizado';
    case AtlasAutomationActionType.runPrediction:
      return 'Executar previsão';
  }
}
