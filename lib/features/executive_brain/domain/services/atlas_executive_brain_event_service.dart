import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/events/atlas_event_factory.dart';
import 'package:projeto_atlas/features/executive_brain/domain/models/atlas_executive_brain_data.dart';
import 'package:projeto_atlas/features/executive_brain/domain/models/atlas_executive_brain_history.dart';
import 'package:projeto_atlas/features/executive_brain/domain/services/atlas_executive_brain_history_service.dart';

class AtlasExecutiveBrainEventService {
  AtlasExecutiveBrainEventService._();

  static final AtlasExecutiveBrainEventService instance =
      AtlasExecutiveBrainEventService._();

  final AtlasEventFactory eventFactory = const AtlasEventFactory();

  AtlasExecutiveBrainData? _lastPublishedData;
  String? _lastFingerprint;
  bool _isPublishing = false;

  AtlasExecutiveBrainData? get lastPublishedData {
    return _lastPublishedData;
  }

  void publishIfChangedDetached(AtlasExecutiveBrainData current) {
    final fingerprint = _fingerprint(current);

    if (_isPublishing || fingerprint == _lastFingerprint) {
      return;
    }

    final previous = _lastPublishedData;

    _lastFingerprint = fingerprint;
    _lastPublishedData = current;

    final change = _detectChange(previous: previous, current: current);

    final historyService = AtlasExecutiveBrainHistoryService.instance;

    historyService.load().then((_) {
      historyService.add(
        _historyEntry(previous: previous, current: current, change: change),
      );
    });

    final decision = current.officialDecision;
    final strategy = current.strategy;

    final event = eventFactory.create(
      type: AtlasEventType.executiveBrainUpdated,
      sourceModule: 'executive_brain',
      title: 'Executive Brain atualizado',
      description: decision == null
          ? 'A decisão oficial foi removida ou ainda não está disponível.'
          : 'Nova visão executiva consolidada: ${decision.title}.',
      priority: _eventPriority(current),
      farmName: decision?.farmName,
      entityId: decision?.id,
      entityType: 'executive_brain_decision',
      payload: <String, dynamic>{
        'changeType': change.name,
        'brainScore': current.brainScore,
        'confidencePercent': current.confidencePercent,
        'status': current.status.name,
        'decisionId': decision?.id,
        'decisionTitle': decision?.title,
        'decisionDescription': decision?.description,
        'decisionPriority': decision?.priority.name,
        'decisionScore': decision?.score,
        'decisionConfidencePercent': decision?.confidencePercent,
        'expectedFinancialImpact': decision?.expectedFinancialImpact,
        'deadlineHours': decision?.deadlineHours,
        'expectedResult': decision?.expectedResult,
        'strategyId': strategy?.id,
        'strategyTitle': strategy?.title,
        'strategyHorizonDays': strategy?.horizonDays,
        'strategySuccessProbabilityPercent':
            strategy?.successProbabilityPercent,
        'dailyPlanCount': current.dailyPlan.length,
        'weeklyPlanCount': current.weeklyPlan.length,
        'monthlyPlanCount': current.monthlyPlan.length,
        'conflictCount': current.conflicts.length,
        'crossImpactCount': current.crossImpacts.length,
      },
      tags: <String>[
        'executive',
        'brain',
        'decision',
        change.name,
        current.status.name,
      ],
    );

    _isPublishing = true;

    AtlasEventBus.instance.publish(event).whenComplete(() {
      _isPublishing = false;
    });
  }

  void reset() {
    _lastPublishedData = null;
    _lastFingerprint = null;
    _isPublishing = false;
  }

  String _fingerprint(AtlasExecutiveBrainData data) {
    final decision = data.officialDecision;
    final strategy = data.strategy;

    final dailyIds = data.dailyPlan.map((item) => item.id).join('|');

    final weeklyIds = data.weeklyPlan.map((item) => item.id).join('|');

    final monthlyIds = data.monthlyPlan.map((item) => item.id).join('|');

    final conflicts = data.conflicts
        .map((item) => '${item.id}:${item.severity.name}')
        .join('|');

    return <Object?>[
      decision?.id,
      decision?.title,
      decision?.priority.name,
      decision?.score.toStringAsFixed(2),
      decision?.confidencePercent.toStringAsFixed(2),
      decision?.expectedFinancialImpact.toStringAsFixed(2),
      decision?.deadlineHours,
      decision?.expectedResult,
      strategy?.id,
      strategy?.title,
      strategy?.successProbabilityPercent.toStringAsFixed(2),
      data.brainScore.toStringAsFixed(2),
      data.confidencePercent.toStringAsFixed(2),
      data.status.name,
      dailyIds,
      weeklyIds,
      monthlyIds,
      conflicts,
    ].join('::');
  }

  AtlasExecutiveBrainChangeType _detectChange({
    required AtlasExecutiveBrainData? previous,
    required AtlasExecutiveBrainData current,
  }) {
    if (previous == null) {
      return AtlasExecutiveBrainChangeType.initialized;
    }

    final previousDecision = previous.officialDecision;
    final currentDecision = current.officialDecision;

    if (previousDecision != null && currentDecision == null) {
      return AtlasExecutiveBrainChangeType.decisionRemoved;
    }

    if (previousDecision?.id != currentDecision?.id ||
        previousDecision?.title != currentDecision?.title) {
      return AtlasExecutiveBrainChangeType.decisionChanged;
    }

    if (previousDecision?.priority != currentDecision?.priority) {
      return AtlasExecutiveBrainChangeType.priorityChanged;
    }

    if (previous.strategy?.id != current.strategy?.id ||
        previous.strategy?.title != current.strategy?.title) {
      return AtlasExecutiveBrainChangeType.strategyChanged;
    }

    return AtlasExecutiveBrainChangeType.scoreChanged;
  }

  AtlasExecutiveBrainHistoryEntry _historyEntry({
    required AtlasExecutiveBrainData? previous,
    required AtlasExecutiveBrainData current,
    required AtlasExecutiveBrainChangeType change,
  }) {
    final timestamp = DateTime.now();

    return AtlasExecutiveBrainHistoryEntry(
      id: 'brain_history_${timestamp.microsecondsSinceEpoch}',
      recordedAt: timestamp,
      changeType: change,
      previousDecisionId: previous?.officialDecision?.id,
      currentDecisionId: current.officialDecision?.id,
      previousDecisionTitle: previous?.officialDecision?.title,
      currentDecisionTitle: current.officialDecision?.title,
      previousScore: previous?.brainScore,
      currentScore: current.brainScore,
      previousConfidencePercent: previous?.confidencePercent,
      currentConfidencePercent: current.confidencePercent,
      currentStatus: current.status,
      reason: _changeReason(
        previous: previous,
        current: current,
        change: change,
      ),
    );
  }

  String _changeReason({
    required AtlasExecutiveBrainData? previous,
    required AtlasExecutiveBrainData current,
    required AtlasExecutiveBrainChangeType change,
  }) {
    switch (change) {
      case AtlasExecutiveBrainChangeType.initialized:
        return 'Primeira visão executiva consolidada nesta execução.';

      case AtlasExecutiveBrainChangeType.decisionChanged:
        return 'A decisão oficial passou de '
            '"${previous?.officialDecision?.title ?? 'nenhuma'}" '
            'para '
            '"${current.officialDecision?.title ?? 'nenhuma'}".';

      case AtlasExecutiveBrainChangeType.decisionRemoved:
        return 'A decisão oficial anterior deixou de estar disponível.';

      case AtlasExecutiveBrainChangeType.priorityChanged:
        return 'A prioridade da decisão oficial foi alterada.';

      case AtlasExecutiveBrainChangeType.strategyChanged:
        return 'A estratégia executiva central foi alterada.';

      case AtlasExecutiveBrainChangeType.scoreChanged:
        return 'Score, confiança, planos, conflitos ou impactos foram atualizados.';
    }
  }

  AtlasEventPriority _eventPriority(AtlasExecutiveBrainData data) {
    if (data.status == AtlasExecutiveBrainStatus.critical ||
        data.officialDecision?.priority ==
            AtlasExecutiveBrainPriority.critical) {
      return AtlasEventPriority.critical;
    }

    if (data.status == AtlasExecutiveBrainStatus.attention ||
        data.officialDecision?.priority == AtlasExecutiveBrainPriority.high) {
      return AtlasEventPriority.high;
    }

    return AtlasEventPriority.normal;
  }
}
