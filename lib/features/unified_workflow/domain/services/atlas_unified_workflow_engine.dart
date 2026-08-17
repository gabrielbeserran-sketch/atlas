import 'dart:convert';

import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/events/atlas_event_filter.dart';
import 'package:projeto_atlas/core/events/atlas_event_factory.dart';
import 'package:projeto_atlas/features/unified_workflow/domain/models/atlas_automation_execution.dart';
import 'package:projeto_atlas/features/unified_workflow/domain/models/atlas_automation_rule.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasUnifiedWorkflowEngine {
  AtlasUnifiedWorkflowEngine._();

  static final AtlasUnifiedWorkflowEngine instance =
      AtlasUnifiedWorkflowEngine._();

  static const String _rulesKey = 'atlas_unified_workflow_rules_v1';
  static const String _executionsKey = 'atlas_unified_workflow_executions_v1';

  final AtlasEventFactory _eventFactory = const AtlasEventFactory();
  final List<AtlasAutomationRule> _rules = <AtlasAutomationRule>[];
  final List<AtlasAutomationExecution> _executions =
      <AtlasAutomationExecution>[];

  String? _subscriptionId;
  bool _loaded = false;

  List<AtlasAutomationRule> get rules =>
      List<AtlasAutomationRule>.unmodifiable(_rules);

  List<AtlasAutomationExecution> get executions =>
      List<AtlasAutomationExecution>.unmodifiable(_executions.reversed);

  bool get isRunning => _subscriptionId != null;

  Future<void> start() async {
    await load();
    if (_subscriptionId != null) return;

    _subscriptionId = AtlasEventBus.instance.subscribe(
      owner: 'atlas_unified_workflow_engine',
      filter: const AtlasEventFilter(),
      listener: _handleEvent,
    );
  }

  void stop() {
    final id = _subscriptionId;
    if (id != null) {
      AtlasEventBus.instance.unsubscribe(id);
    }
    _subscriptionId = null;
  }

  Future<void> load() async {
    if (_loaded) return;
    final preferences = await SharedPreferences.getInstance();

    _rules
      ..clear()
      ..addAll(_decodeRules(preferences.getString(_rulesKey)));

    if (_rules.isEmpty) {
      _rules.addAll(_seedRules());
      await _saveRules();
    }

    _executions
      ..clear()
      ..addAll(_decodeExecutions(preferences.getString(_executionsKey)));

    _loaded = true;
  }

  Future<void> addRule(AtlasAutomationRule rule) async {
    _rules.add(rule);
    await _saveRules();
  }

  Future<void> updateRule(AtlasAutomationRule rule) async {
    final index = _rules.indexWhere((item) => item.id == rule.id);
    if (index < 0) return;
    _rules[index] = rule;
    await _saveRules();
  }

  Future<void> deleteRule(String id) async {
    _rules.removeWhere((item) => item.id == id);
    await _saveRules();
  }

  Future<void> setRuleEnabled(String id, bool enabled) async {
    final index = _rules.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _rules[index] = _rules[index].copyWith(enabled: enabled);
    await _saveRules();
  }

  Future<void> publishTestEvent(AtlasEventType type) async {
    final event = _eventFactory.create(
      type: type,
      sourceModule: 'unified_workflow_test',
      title: 'Evento de teste: ${atlasEventTypeLabel(type)}',
      description: 'Evento criado para validar as automações do Atlas.',
      priority: AtlasEventPriority.normal,
      entityType: 'automation_test',
      tags: const <String>['teste', 'automacao'],
    );
    await AtlasEventBus.instance.publish(event);
  }

  Future<void> clearExecutions() async {
    _executions.clear();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_executionsKey);
  }

  Future<void> _handleEvent(AtlasEvent event) async {
    if (event.sourceModule == 'unified_workflow_engine') return;

    final matching = _rules.where((rule) {
      if (!rule.enabled || rule.triggerType != event.type) return false;
      final source = rule.sourceModule;
      return source == null || source == event.sourceModule;
    }).toList();

    for (final rule in matching) {
      final now = DateTime.now();
      final execution = AtlasAutomationExecution(
        id: 'automation_${now.microsecondsSinceEpoch}_${rule.id}',
        ruleId: rule.id,
        ruleTitle: rule.title,
        eventId: event.id,
        eventTitle: event.title,
        actionTitle: rule.actionTitle,
        executedAt: now,
        success: true,
        message: 'Ação executada automaticamente a partir de ${event.title}.',
      );

      _executions.add(execution);
      if (_executions.length > 300) {
        _executions.removeRange(0, _executions.length - 300);
      }

      final generatedEvent = _eventFactory.create(
        type: _outputEventType(rule.actionType),
        sourceModule: 'unified_workflow_engine',
        title: rule.actionTitle,
        description: execution.message,
        priority: rule.priority,
        farmId: event.farmId,
        farmName: event.farmName,
        entityId: event.entityId,
        entityType: 'automation_execution',
        payload: <String, dynamic>{
          'ruleId': rule.id,
          'sourceEventId': event.id,
          'actionType': rule.actionType.name,
        },
        tags: <String>['automacao', rule.actionType.name],
      );

      await AtlasEventBus.instance.publish(generatedEvent);
    }

    if (matching.isNotEmpty) await _saveExecutions();
  }

  AtlasEventType _outputEventType(AtlasAutomationActionType action) {
    switch (action) {
      case AtlasAutomationActionType.createTask:
        return AtlasEventType.taskCreated;
      case AtlasAutomationActionType.createNotification:
        return AtlasEventType.executiveAlertCreated;
      case AtlasAutomationActionType.recalculateIndicators:
        return AtlasEventType.executiveKpiUpdated;
      case AtlasAutomationActionType.updateExecutiveBrain:
        return AtlasEventType.executiveBrainUpdated;
      case AtlasAutomationActionType.createLearningCase:
      case AtlasAutomationActionType.runPrediction:
        return AtlasEventType.systemUpdated;
    }
  }

  List<AtlasAutomationRule> _seedRules() => <AtlasAutomationRule>[
    const AtlasAutomationRule(
      id: 'weight_recalculate_kpis',
      title: 'Pesagem atualiza indicadores',
      description:
          'Ao registrar uma pesagem, recalcula os indicadores produtivos.',
      triggerType: AtlasEventType.animalWeightRecorded,
      actionType: AtlasAutomationActionType.recalculateIndicators,
      actionTitle: 'Indicadores produtivos recalculados',
      enabled: true,
      priority: AtlasEventPriority.normal,
    ),
    const AtlasAutomationRule(
      id: 'low_stock_alert',
      title: 'Estoque baixo gera alerta',
      description: 'Transforma eventos de estoque baixo em alerta executivo.',
      triggerType: AtlasEventType.inventoryLowStock,
      actionType: AtlasAutomationActionType.createNotification,
      actionTitle: 'Alerta executivo de estoque baixo',
      enabled: true,
      priority: AtlasEventPriority.high,
    ),
    const AtlasAutomationRule(
      id: 'decision_approved_task',
      title: 'Decisão aprovada cria tarefa',
      description: 'Converte uma decisão aprovada em tarefa de execução.',
      triggerType: AtlasEventType.decisionApproved,
      actionType: AtlasAutomationActionType.createTask,
      actionTitle: 'Tarefa criada a partir de decisão aprovada',
      enabled: true,
      priority: AtlasEventPriority.high,
    ),
    const AtlasAutomationRule(
      id: 'workflow_completed_learning',
      title: 'Workflow concluído gera aprendizado',
      description:
          'Registra o resultado de workflows concluídos na memória do Atlas.',
      triggerType: AtlasEventType.workflowCompleted,
      actionType: AtlasAutomationActionType.createLearningCase,
      actionTitle: 'Caso de aprendizado registrado',
      enabled: true,
      priority: AtlasEventPriority.normal,
    ),
    const AtlasAutomationRule(
      id: 'kpi_brain_update',
      title: 'KPI atualiza Executive Brain',
      description: 'Atualiza a inteligência executiva sempre que um KPI muda.',
      triggerType: AtlasEventType.executiveKpiUpdated,
      actionType: AtlasAutomationActionType.updateExecutiveBrain,
      actionTitle: 'Executive Brain atualizado',
      enabled: true,
      priority: AtlasEventPriority.normal,
      sourceModule: 'performance_intelligence',
    ),
  ];

  List<AtlasAutomationRule> _decodeRules(String? stored) {
    if (stored == null || stored.isEmpty) return <AtlasAutomationRule>[];
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! List) return <AtlasAutomationRule>[];
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                AtlasAutomationRule.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return <AtlasAutomationRule>[];
    }
  }

  List<AtlasAutomationExecution> _decodeExecutions(String? stored) {
    if (stored == null || stored.isEmpty) {
      return <AtlasAutomationExecution>[];
    }
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! List) return <AtlasAutomationExecution>[];
      return decoded
          .whereType<Map>()
          .map(
            (item) => AtlasAutomationExecution.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasAutomationExecution>[];
    }
  }

  Future<void> _saveRules() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _rulesKey,
      jsonEncode(_rules.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _saveExecutions() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _executionsKey,
      jsonEncode(_executions.map((item) => item.toJson()).toList()),
    );
  }
}
