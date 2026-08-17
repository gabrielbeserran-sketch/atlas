import 'dart:convert';

import 'package:projeto_atlas/core/events/atlas_event.dart';
import 'package:projeto_atlas/core/events/atlas_event_bus.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_action_outcome.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_cycle_report.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasExecutionCycleReportService {
  AtlasExecutionCycleReportService._();

  static final AtlasExecutionCycleReportService instance =
      AtlasExecutionCycleReportService._();

  static const String _storageKey = 'atlas_execution_cycle_reports_v1';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<AtlasExecutionCycleReport>> load({String? farmName}) async {
    final all = await _loadAll();
    final normalizedFarm = farmName?.trim().toLowerCase();

    final filtered =
        all.where((report) {
          if (normalizedFarm == null || normalizedFarm.isEmpty) {
            return true;
          }

          return report.farmName?.trim().toLowerCase() == normalizedFarm;
        }).toList()..sort(
          (first, second) => second.generatedAt.compareTo(first.generatedAt),
        );

    return filtered;
  }

  Future<AtlasExecutionCycleReport> generate({
    required List<AtlasCommandCenterAction> actions,
    required List<AtlasActionOutcome> outcomes,
    String? farmName,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    final now = DateTime.now();
    final start = periodStart ?? now.subtract(const Duration(days: 30));
    final end = periodEnd ?? now;

    final periodActions = actions.where((action) {
      return !action.createdAt.isBefore(start) &&
          !action.createdAt.isAfter(end);
    }).toList();

    final actionIds = periodActions.map((action) => action.id).toSet();
    final periodOutcomes = outcomes
        .where((outcome) => actionIds.contains(outcome.actionId))
        .toList();

    final completed = periodActions
        .where((action) => action.isCompleted)
        .length;
    final overdue = periodActions.where((action) => action.isOverdue).length;
    final expected = periodActions.fold<double>(
      0,
      (total, action) => total + action.expectedFinancialImpact,
    );
    final realized = periodOutcomes.fold<double>(
      0,
      (total, outcome) => total + outcome.realizedFinancialImpact,
    );
    final cost = periodOutcomes.fold<double>(
      0,
      (total, outcome) => total + outcome.executionCost,
    );
    final net = periodOutcomes.fold<double>(
      0,
      (total, outcome) => total + outcome.netFinancialResult,
    );
    final averageRoi = periodOutcomes.isEmpty
        ? 0.0
        : periodOutcomes
                  .map((outcome) => outcome.roiPercent)
                  .fold<double>(0, (first, second) => first + second) /
              periodOutcomes.length;

    final highlights = <String>[
      if (completed > 0) '$completed ação(ões) concluída(s) no ciclo.',
      if (net > 0)
        'Resultado financeiro líquido positivo de '
            'R\$ ${net.toStringAsFixed(2)}.',
      if (periodOutcomes.isNotEmpty)
        '${periodOutcomes.length} ação(ões) com resultado '
            'técnico ou financeiro registrado.',
    ];

    if (highlights.isEmpty) {
      highlights.add('Nenhum destaque positivo foi consolidado no período.');
    }

    final attentionPoints = <String>[
      if (overdue > 0) '$overdue ação(ões) permanece(m) atrasada(s).',
      if (periodActions.length > periodOutcomes.length)
        '${periodActions.length - periodOutcomes.length} '
            'ação(ões) ainda não possui(em) resultado registrado.',
      if (net < 0) 'O ciclo apresenta resultado financeiro líquido negativo.',
    ];

    if (attentionPoints.isEmpty) {
      attentionPoints.add('Nenhum ponto crítico foi identificado no ciclo.');
    }

    final lessons = periodOutcomes
        .map((outcome) => outcome.lessonsLearned.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .take(8)
        .toList(growable: false);

    final summary =
        'O ciclo registrou ${periodActions.length} ação(ões), '
        '$completed conclusão(ões), $overdue atraso(s), '
        'impacto esperado de R\$ ${expected.toStringAsFixed(2)} '
        'e resultado líquido de R\$ ${net.toStringAsFixed(2)}.';

    final report = AtlasExecutionCycleReport(
      id: 'cycle_report_${now.microsecondsSinceEpoch}',
      farmName: farmName,
      generatedAt: now,
      periodStart: start,
      periodEnd: end,
      totalActions: periodActions.length,
      completedActions: completed,
      overdueActions: overdue,
      actionsWithOutcome: periodOutcomes.length,
      expectedFinancialImpact: expected,
      realizedFinancialImpact: realized,
      executionCost: cost,
      totalNetFinancialResult: net,
      averageRoiPercent: averageRoi,
      executiveSummary: summary,
      highlights: highlights,
      attentionPoints: attentionPoints,
      lessonsLearned: lessons.isEmpty
          ? const <String>['Nenhum aprendizado foi registrado no período.']
          : lessons,
    );

    final all = await _loadAll()
      ..add(report);
    await _saveAll(all);
    await _publish(report);
    return report;
  }

  Future<void> delete(String id) async {
    final all = await _loadAll()
      ..removeWhere((report) => report.id == id);

    await _saveAll(all);
  }

  Future<List<AtlasExecutionCycleReport>> _loadAll() async {
    final encoded = await _preferences.getString(_storageKey);

    if (encoded == null || encoded.trim().isEmpty) {
      return <AtlasExecutionCycleReport>[];
    }

    try {
      final decoded = jsonDecode(encoded) as List<dynamic>;

      return decoded
          .map(
            (item) => AtlasExecutionCycleReport.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AtlasExecutionCycleReport>[];
    }
  }

  Future<void> _saveAll(List<AtlasExecutionCycleReport> reports) async {
    await _preferences.setString(
      _storageKey,
      jsonEncode(reports.map((item) => item.toMap()).toList()),
    );
  }

  Future<void> _publish(AtlasExecutionCycleReport report) async {
    await AtlasEventBus.instance.publish(
      AtlasEvent(
        id: 'cycle_report_event_${report.id}',
        type: AtlasEventType.systemUpdated,
        sourceModule: 'execution_cycle_report',
        title: 'Relatório executivo do ciclo gerado',
        description: report.executiveSummary,
        occurredAt: report.generatedAt,
        priority:
            report.overdueActions > 0 || report.totalNetFinancialResult < 0
            ? AtlasEventPriority.high
            : AtlasEventPriority.normal,
        farmName: report.farmName,
        entityId: report.id,
        entityType: 'execution_cycle_report',
        payload: <String, dynamic>{
          'totalActions': report.totalActions,
          'completedActions': report.completedActions,
          'overdueActions': report.overdueActions,
          'actionsWithOutcome': report.actionsWithOutcome,
          'totalNetFinancialResult': report.totalNetFinancialResult,
          'averageRoiPercent': report.averageRoiPercent,
        },
        tags: const <String>[
          'command_center',
          'executive_report',
          'execution_cycle',
        ],
      ),
    );
  }
}
