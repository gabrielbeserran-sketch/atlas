import 'package:projeto_atlas/features/animal_health/domain/models/animal_health_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/atlas_ai/domain/models/atlas_ai_tracked_action.dart';
import 'package:projeto_atlas/features/diagnostics/domain/models/atlas_diagnostic_data.dart';
import 'package:projeto_atlas/features/executive_alerts/domain/models/atlas_executive_alert.dart';
import 'package:projeto_atlas/features/farm/domain/services/atlas_farm_intelligence_service.dart';

class AtlasExecutiveAlertService {
  const AtlasExecutiveAlertService();

  AtlasExecutiveAlertSummary build({
    required List<AtlasExecutiveFarmAlertInput> farms,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final alerts = <AtlasExecutiveAlert>[];

    for (final farm in farms) {
      alerts.addAll(_buildFarmAlerts(input: farm, now: currentTime));
    }

    alerts.sort(
      (first, second) => second.priorityScore.compareTo(first.priorityScore),
    );

    final farmSummaries = _buildFarmSummaries(alerts);

    final areaSummaries = _buildAreaSummaries(alerts);

    final informational = alerts.where((item) {
      return item.severity == AtlasExecutiveAlertSeverity.informational;
    }).length;

    final attention = alerts.where((item) {
      return item.severity == AtlasExecutiveAlertSeverity.attention;
    }).length;

    final high = alerts.where((item) {
      return item.severity == AtlasExecutiveAlertSeverity.high;
    }).length;

    final critical = alerts.where((item) {
      return item.severity == AtlasExecutiveAlertSeverity.critical;
    }).length;

    return AtlasExecutiveAlertSummary(
      generatedAt: currentTime,
      summary: _buildSummary(
        total: alerts.length,
        attention: attention,
        high: high,
        critical: critical,
        mainAlert: alerts.isEmpty ? null : alerts.first,
        mostCriticalFarm: farmSummaries.isEmpty ? null : farmSummaries.first,
      ),
      total: alerts.length,
      informational: informational,
      attention: attention,
      high: high,
      critical: critical,
      alerts: alerts,
      farms: farmSummaries,
      areas: areaSummaries,
    );
  }

  List<AtlasExecutiveAlert> _buildFarmAlerts({
    required AtlasExecutiveFarmAlertInput input,
    required DateTime now,
  }) {
    final alerts = <AtlasExecutiveAlert>[];

    alerts.addAll(_diagnosticRiskAlerts(input: input, now: now));

    alerts.addAll(_trackedActionAlerts(input: input, now: now));

    alerts.addAll(_agendaAlerts(input: input, now: now));

    alerts.addAll(_inventoryAlerts(input: input, now: now));

    alerts.addAll(_financeAlerts(input: input, now: now));

    alerts.addAll(_herdAlerts(input: input, now: now));

    alerts.addAll(_paddockAlerts(input: input, now: now));

    alerts.addAll(_healthAlerts(input: input, now: now));

    alerts.addAll(_reproductionAlerts(input: input, now: now));

    alerts.add(_mainPriorityAlert(input: input, now: now));

    return alerts;
  }

  List<AtlasExecutiveAlert> _diagnosticRiskAlerts({
    required AtlasExecutiveFarmAlertInput input,
    required DateTime now,
  }) {
    return input.diagnostic.risks
        .where((item) {
          return item.level == AtlasDiagnosticLevel.critical ||
              item.level == AtlasDiagnosticLevel.attention;
        })
        .map((item) {
          final severity = item.level == AtlasDiagnosticLevel.critical
              ? AtlasExecutiveAlertSeverity.critical
              : AtlasExecutiveAlertSeverity.high;

          return AtlasExecutiveAlert(
            id: _id(
              farmName: input.farmName,
              type: AtlasExecutiveAlertType.diagnosticRisk,
              suffix: item.title,
            ),
            generatedAt: now,
            farmName: input.farmName,
            title: item.title,
            description: item.description,
            recommendation: item.recommendation,
            type: AtlasExecutiveAlertType.diagnosticRisk,
            severity: severity,
            area: item.area,
            priorityScore: _priorityScore(
              severity: severity,
              baseImpact: item.impactScore,
              deadlineDays: severity == AtlasExecutiveAlertSeverity.critical
                  ? 1
                  : 3,
            ),
            responseDeadlineDays:
                severity == AtlasExecutiveAlertSeverity.critical ? 1 : 3,
            sourceLabel: 'Diagnóstico Inteligente',
            numericValue: item.impactScore,
            unitLabel: 'impacto',
          );
        })
        .toList();
  }

  List<AtlasExecutiveAlert> _trackedActionAlerts({
    required AtlasExecutiveFarmAlertInput input,
    required DateTime now,
  }) {
    return input.trackedActions
        .where((action) {
          return action.isOverdue;
        })
        .map((action) {
          final delay = now.difference(action.dueDate).inDays;

          final severity = delay >= 7
              ? AtlasExecutiveAlertSeverity.critical
              : AtlasExecutiveAlertSeverity.high;

          return AtlasExecutiveAlert(
            id: _id(
              farmName: input.farmName,
              type: AtlasExecutiveAlertType.trackedActionOverdue,
              suffix: action.id,
            ),
            generatedAt: now,
            farmName: input.farmName,
            title: 'Ação atrasada: ${action.title}',
            description:
                'A recomendação está atrasada há '
                '$delay '
                '${delay == 1 ? 'dia' : 'dias'}.',
            recommendation:
                'Atualize o status, registre o impedimento ou execute a ação.',
            type: AtlasExecutiveAlertType.trackedActionOverdue,
            severity: severity,
            area: action.area,
            priorityScore: _priorityScore(
              severity: severity,
              baseImpact: 75.0 + delay.clamp(0, 25).toDouble(),
              deadlineDays: 0,
            ),
            responseDeadlineDays: 0,
            sourceLabel: 'Ações da Consultoria',
            numericValue: delay.toDouble(),
            unitLabel: 'dias de atraso',
          );
        })
        .toList();
  }

  List<AtlasExecutiveAlert> _agendaAlerts({
    required AtlasExecutiveFarmAlertInput input,
    required DateTime now,
  }) {
    final alerts = <AtlasExecutiveAlert>[];
    final agenda = input.intelligence.agenda;

    if (agenda.overdueCount > 0) {
      final severity = agenda.overdueCount >= 5
          ? AtlasExecutiveAlertSeverity.critical
          : AtlasExecutiveAlertSeverity.high;

      alerts.add(
        AtlasExecutiveAlert(
          id: _id(
            farmName: input.farmName,
            type: AtlasExecutiveAlertType.agendaOverdue,
            suffix: 'overdue',
          ),
          generatedAt: now,
          farmName: input.farmName,
          title: 'Tarefas atrasadas na agenda',
          description:
              'Existem ${agenda.overdueCount} '
              '${agenda.overdueCount == 1 ? 'tarefa atrasada' : 'tarefas atrasadas'}.',
          recommendation:
              'Reorganize responsáveis e prazos, priorizando atividades de maior risco.',
          type: AtlasExecutiveAlertType.agendaOverdue,
          severity: severity,
          area: AtlasFarmAnalysisArea.agenda,
          priorityScore: _priorityScore(
            severity: severity,
            baseImpact: 60 + agenda.overdueCount * 4,
            deadlineDays: 1,
          ),
          responseDeadlineDays: 1,
          sourceLabel: 'Agenda',
          numericValue: agenda.overdueCount.toDouble(),
          unitLabel: 'tarefas',
        ),
      );
    }

    if (agenda.urgentCount > 0) {
      alerts.add(
        AtlasExecutiveAlert(
          id: _id(
            farmName: input.farmName,
            type: AtlasExecutiveAlertType.agendaUrgent,
            suffix: 'urgent',
          ),
          generatedAt: now,
          farmName: input.farmName,
          title: 'Atividades urgentes pendentes',
          description:
              'A agenda possui ${agenda.urgentCount} '
              '${agenda.urgentCount == 1 ? 'atividade urgente' : 'atividades urgentes'}.',
          recommendation: 'Confirme responsáveis e execução ainda hoje.',
          type: AtlasExecutiveAlertType.agendaUrgent,
          severity: AtlasExecutiveAlertSeverity.high,
          area: AtlasFarmAnalysisArea.agenda,
          priorityScore: _priorityScore(
            severity: AtlasExecutiveAlertSeverity.high,
            baseImpact: 65 + agenda.urgentCount * 3,
            deadlineDays: 0,
          ),
          responseDeadlineDays: 0,
          sourceLabel: 'Agenda',
          numericValue: agenda.urgentCount.toDouble(),
          unitLabel: 'atividades',
        ),
      );
    }

    return alerts;
  }

  List<AtlasExecutiveAlert> _inventoryAlerts({
    required AtlasExecutiveFarmAlertInput input,
    required DateTime now,
  }) {
    final alerts = <AtlasExecutiveAlert>[];
    final inventory = input.intelligence.inventory;

    if (inventory.expiredCount > 0) {
      alerts.add(
        AtlasExecutiveAlert(
          id: _id(
            farmName: input.farmName,
            type: AtlasExecutiveAlertType.inventoryExpired,
            suffix: 'expired',
          ),
          generatedAt: now,
          farmName: input.farmName,
          title: 'Produtos vencidos no estoque',
          description:
              'Foram encontrados ${inventory.expiredCount} '
              '${inventory.expiredCount == 1 ? 'item vencido' : 'itens vencidos'}.',
          recommendation:
              'Isole os produtos, registre o descarte e revise o processo de compras.',
          type: AtlasExecutiveAlertType.inventoryExpired,
          severity: AtlasExecutiveAlertSeverity.critical,
          area: AtlasFarmAnalysisArea.inventory,
          priorityScore: _priorityScore(
            severity: AtlasExecutiveAlertSeverity.critical,
            baseImpact: 85 + inventory.expiredCount * 2,
            deadlineDays: 0,
          ),
          responseDeadlineDays: 0,
          sourceLabel: 'Estoque',
          numericValue: inventory.expiredCount.toDouble(),
          unitLabel: 'itens',
        ),
      );
    }

    if (inventory.nearExpirationCount > 0) {
      alerts.add(
        AtlasExecutiveAlert(
          id: _id(
            farmName: input.farmName,
            type: AtlasExecutiveAlertType.inventoryNearExpiration,
            suffix: 'near_expiration',
          ),
          generatedAt: now,
          farmName: input.farmName,
          title: 'Produtos próximos do vencimento',
          description:
              'Existem ${inventory.nearExpirationCount} '
              '${inventory.nearExpirationCount == 1 ? 'item próximo do vencimento' : 'itens próximos do vencimento'}.',
          recommendation:
              'Priorize o uso, remaneje quando possível e ajuste as próximas compras.',
          type: AtlasExecutiveAlertType.inventoryNearExpiration,
          severity: AtlasExecutiveAlertSeverity.attention,
          area: AtlasFarmAnalysisArea.inventory,
          priorityScore: _priorityScore(
            severity: AtlasExecutiveAlertSeverity.attention,
            baseImpact: 50 + inventory.nearExpirationCount * 2,
            deadlineDays: 7,
          ),
          responseDeadlineDays: 7,
          sourceLabel: 'Estoque',
          numericValue: inventory.nearExpirationCount.toDouble(),
          unitLabel: 'itens',
        ),
      );
    }

    return alerts;
  }

  List<AtlasExecutiveAlert> _financeAlerts({
    required AtlasExecutiveFarmAlertInput input,
    required DateTime now,
  }) {
    final finance = input.intelligence.finance;

    if (finance.balance >= 0) {
      return const [];
    }

    final severity =
        finance.totalIncome <= 0 ||
            finance.balance.abs() > finance.totalIncome * 0.25
        ? AtlasExecutiveAlertSeverity.critical
        : AtlasExecutiveAlertSeverity.high;

    return [
      AtlasExecutiveAlert(
        id: _id(
          farmName: input.farmName,
          type: AtlasExecutiveAlertType.negativeFinancialResult,
          suffix: 'negative_balance',
        ),
        generatedAt: now,
        farmName: input.farmName,
        title: 'Resultado financeiro negativo',
        description: 'O saldo atual é ${_currency(finance.balance)}.',
        recommendation:
            'Revise despesas, receitas pendentes e custos evitáveis.',
        type: AtlasExecutiveAlertType.negativeFinancialResult,
        severity: severity,
        area: AtlasFarmAnalysisArea.finance,
        priorityScore: _priorityScore(
          severity: severity,
          baseImpact: 80,
          deadlineDays: 2,
        ),
        responseDeadlineDays: 2,
        sourceLabel: 'Financeiro',
        numericValue: finance.balance,
        unitLabel: 'R\$',
      ),
    ];
  }

  List<AtlasExecutiveAlert> _herdAlerts({
    required AtlasExecutiveFarmAlertInput input,
    required DateTime now,
  }) {
    final coverage = input.intelligence.herd.registrationCoverage;

    if (coverage >= 95) {
      return const [];
    }

    final gap = 100 - coverage;

    final severity = coverage < 70
        ? AtlasExecutiveAlertSeverity.high
        : AtlasExecutiveAlertSeverity.attention;

    return [
      AtlasExecutiveAlert(
        id: _id(
          farmName: input.farmName,
          type: AtlasExecutiveAlertType.herdRegistrationGap,
          suffix: 'registration',
        ),
        generatedAt: now,
        farmName: input.farmName,
        title: 'Cadastro do rebanho incompleto',
        description:
            'A cobertura cadastral está em '
            '${coverage.toStringAsFixed(1)}%.',
        recommendation:
            'Complete identificação, lote, peso e demais informações pendentes.',
        type: AtlasExecutiveAlertType.herdRegistrationGap,
        severity: severity,
        area: AtlasFarmAnalysisArea.herd,
        priorityScore: _priorityScore(
          severity: severity,
          baseImpact: 45 + gap * 0.7,
          deadlineDays: 15,
        ),
        responseDeadlineDays: 15,
        sourceLabel: 'Rebanho',
        numericValue: coverage,
        unitLabel: '% cadastrado',
      ),
    ];
  }

  List<AtlasExecutiveAlert> _paddockAlerts({
    required AtlasExecutiveFarmAlertInput input,
    required DateTime now,
  }) {
    final score = input.intelligence.paddocks.score;

    if (score >= 70) {
      return const [];
    }

    final severity = score < 50
        ? AtlasExecutiveAlertSeverity.high
        : AtlasExecutiveAlertSeverity.attention;

    return [
      AtlasExecutiveAlert(
        id: _id(
          farmName: input.farmName,
          type: AtlasExecutiveAlertType.paddockProblem,
          suffix: 'paddock_score',
        ),
        generatedAt: now,
        farmName: input.farmName,
        title: 'Baixo desempenho dos piquetes',
        description:
            'O score de piquetes está em '
            '${score.toStringAsFixed(0)}/100.',
        recommendation:
            'Revise ocupação, descanso, área e distribuição do rebanho.',
        type: AtlasExecutiveAlertType.paddockProblem,
        severity: severity,
        area: AtlasFarmAnalysisArea.paddock,
        priorityScore: _priorityScore(
          severity: severity,
          baseImpact: 100 - score,
          deadlineDays: 10,
        ),
        responseDeadlineDays: 10,
        sourceLabel: 'Piquetes',
        numericValue: score,
        unitLabel: 'score',
      ),
    ];
  }

  List<AtlasExecutiveAlert> _healthAlerts({
    required AtlasExecutiveFarmAlertInput input,
    required DateTime now,
  }) {
    final alerts = <AtlasExecutiveAlert>[];
    final today = DateTime(now.year, now.month, now.day);

    for (final context in input.healthRecords) {
      final record = context.record;

      if (record.isQuarantine ||
          record.status.toLowerCase().contains('quarentena')) {
        alerts.add(
          AtlasExecutiveAlert(
            id: _id(
              farmName: input.farmName,
              type: AtlasExecutiveAlertType.healthQuarantine,
              suffix: '${context.animalId}_${record.id}',
            ),
            generatedAt: now,
            farmName: input.farmName,
            title: 'Animal em quarentena: ${context.animalLabel}',
            description:
                '${context.animalLabel}, do lote ${context.groupName}, possui registro sanitário em quarentena.',
            recommendation:
                'Revisar o quadro clínico, o isolamento, o protocolo sanitário e os critérios para liberação do animal.',
            type: AtlasExecutiveAlertType.healthQuarantine,
            severity: AtlasExecutiveAlertSeverity.high,
            area: AtlasFarmAnalysisArea.herd,
            priorityScore: _priorityScore(
              severity: AtlasExecutiveAlertSeverity.high,
              baseImpact: 85,
              deadlineDays: 1,
            ),
            responseDeadlineDays: 1,
            sourceLabel: 'Sanidade animal',
          ),
        );
      }

      final nextDate = _parseOperationalDate(record.nextDate);
      if (nextDate != null) {
        final due = DateTime(nextDate.year, nextDate.month, nextDate.day);
        final days = due.difference(today).inDays;
        if (days <= 7) {
          final overdue = days < 0;
          final severity = overdue
              ? AtlasExecutiveAlertSeverity.critical
              : days <= 2
              ? AtlasExecutiveAlertSeverity.high
              : AtlasExecutiveAlertSeverity.attention;
          alerts.add(
            AtlasExecutiveAlert(
              id: _id(
                farmName: input.farmName,
                type: AtlasExecutiveAlertType.healthSchedule,
                suffix: '${context.animalId}_${record.id}_return',
              ),
              generatedAt: now,
              farmName: input.farmName,
              title: overdue
                  ? 'Manejo sanitário atrasado: ${context.animalLabel}'
                  : 'Manejo sanitário próximo: ${context.animalLabel}',
              description: overdue
                  ? 'O retorno sanitário de ${context.animalLabel} está atrasado há ${days.abs()} dia(s).'
                  : 'O retorno sanitário de ${context.animalLabel} está previsto para daqui a $days dia(s).',
              recommendation:
                  'Conferir o protocolo, separar os materiais necessários e registrar a execução no histórico sanitário.',
              type: AtlasExecutiveAlertType.healthSchedule,
              severity: severity,
              area: AtlasFarmAnalysisArea.herd,
              priorityScore: _priorityScore(
                severity: severity,
                baseImpact: overdue ? 95 : 75,
                deadlineDays: overdue ? 0 : days,
              ),
              responseDeadlineDays: overdue ? 0 : days,
              sourceLabel: 'Sanidade animal',
              numericValue: days.toDouble(),
              unitLabel: 'dias',
            ),
          );
        }
      }

      final withdrawalDate = _parseOperationalDate(record.withdrawalEndDate);
      if (withdrawalDate != null) {
        final end = DateTime(
          withdrawalDate.year,
          withdrawalDate.month,
          withdrawalDate.day,
        );
        final days = end.difference(today).inDays;
        if (days >= 0) {
          alerts.add(
            AtlasExecutiveAlert(
              id: _id(
                farmName: input.farmName,
                type: AtlasExecutiveAlertType.healthWithdrawal,
                suffix: '${context.animalId}_${record.id}_withdrawal',
              ),
              generatedAt: now,
              farmName: input.farmName,
              title: 'Carência sanitária ativa: ${context.animalLabel}',
              description:
                  '${context.animalLabel} permanece em período de carência por mais $days dia(s).',
              recommendation:
                  'Impedir venda, abate ou destinação da produção durante a carência e confirmar a liberação após o prazo.',
              type: AtlasExecutiveAlertType.healthWithdrawal,
              severity: days <= 2
                  ? AtlasExecutiveAlertSeverity.high
                  : AtlasExecutiveAlertSeverity.attention,
              area: AtlasFarmAnalysisArea.herd,
              priorityScore: _priorityScore(
                severity: days <= 2
                    ? AtlasExecutiveAlertSeverity.high
                    : AtlasExecutiveAlertSeverity.attention,
                baseImpact: 80,
                deadlineDays: days,
              ),
              responseDeadlineDays: days,
              sourceLabel: 'Sanidade animal',
              numericValue: days.toDouble(),
              unitLabel: 'dias',
            ),
          );
        }
      }
    }

    return alerts;
  }

  List<AtlasExecutiveAlert> _reproductionAlerts({
    required AtlasExecutiveFarmAlertInput input,
    required DateTime now,
  }) {
    final alerts = <AtlasExecutiveAlert>[];
    final today = DateTime(now.year, now.month, now.day);

    for (final context in input.reproductionRecords) {
      final expectedDate = _parseOperationalDate(context.record.expectedDate);
      if (expectedDate == null) continue;

      final due = DateTime(
        expectedDate.year,
        expectedDate.month,
        expectedDate.day,
      );
      final days = due.difference(today).inDays;
      if (days > 30) continue;

      final overdue = days < 0;
      final severity = overdue
          ? AtlasExecutiveAlertSeverity.critical
          : days <= 7
          ? AtlasExecutiveAlertSeverity.high
          : AtlasExecutiveAlertSeverity.attention;

      alerts.add(
        AtlasExecutiveAlert(
          id: _id(
            farmName: input.farmName,
            type: AtlasExecutiveAlertType.reproductionSchedule,
            suffix: '${context.animalId}_${context.record.id}',
          ),
          generatedAt: now,
          farmName: input.farmName,
          title: overdue
              ? 'Evento reprodutivo atrasado: ${context.animalLabel}'
              : 'Evento reprodutivo próximo: ${context.animalLabel}',
          description: overdue
              ? '${context.record.type} está atrasado há ${days.abs()} dia(s) para ${context.animalLabel}.'
              : '${context.record.type} está previsto para daqui a $days dia(s) para ${context.animalLabel}.',
          recommendation:
              'Revisar o protocolo reprodutivo, confirmar a condição do animal e programar a execução com o responsável.',
          type: AtlasExecutiveAlertType.reproductionSchedule,
          severity: severity,
          area: AtlasFarmAnalysisArea.herd,
          priorityScore: _priorityScore(
            severity: severity,
            baseImpact: overdue ? 95 : 80,
            deadlineDays: overdue ? 0 : days,
          ),
          responseDeadlineDays: overdue ? 0 : days,
          sourceLabel: 'Reprodução animal',
          numericValue: days.toDouble(),
          unitLabel: 'dias',
        ),
      );
    }

    return alerts;
  }

  AtlasExecutiveAlert _mainPriorityAlert({
    required AtlasExecutiveFarmAlertInput input,
    required DateTime now,
  }) {
    final priority = input.diagnostic.mainPriority;

    final severity = priority.level == AtlasDiagnosticLevel.critical
        ? AtlasExecutiveAlertSeverity.critical
        : priority.level == AtlasDiagnosticLevel.attention
        ? AtlasExecutiveAlertSeverity.high
        : AtlasExecutiveAlertSeverity.informational;

    return AtlasExecutiveAlert(
      id: _id(
        farmName: input.farmName,
        type: AtlasExecutiveAlertType.mainPriority,
        suffix: priority.title,
      ),
      generatedAt: now,
      farmName: input.farmName,
      title: 'Prioridade principal: ${priority.title}',
      description: priority.description,
      recommendation: priority.recommendation,
      type: AtlasExecutiveAlertType.mainPriority,
      severity: severity,
      area: priority.area,
      priorityScore: _priorityScore(
        severity: severity,
        baseImpact: priority.score,
        deadlineDays: severity == AtlasExecutiveAlertSeverity.critical ? 1 : 7,
      ),
      responseDeadlineDays: severity == AtlasExecutiveAlertSeverity.critical
          ? 1
          : 7,
      sourceLabel: 'Diagnóstico Inteligente',
      numericValue: priority.score,
      unitLabel: 'prioridade',
    );
  }

  List<AtlasExecutiveFarmAlertSummary> _buildFarmSummaries(
    List<AtlasExecutiveAlert> alerts,
  ) {
    final grouped = <String, List<AtlasExecutiveAlert>>{};

    for (final alert in alerts) {
      grouped.putIfAbsent(alert.farmName, () => []);

      grouped[alert.farmName]!.add(alert);
    }

    final result = <AtlasExecutiveFarmAlertSummary>[];

    for (final entry in grouped.entries) {
      final items = entry.value
        ..sort(
          (first, second) =>
              second.priorityScore.compareTo(first.priorityScore),
        );

      final critical = items.where((item) {
        return item.severity == AtlasExecutiveAlertSeverity.critical;
      }).length;

      final high = items.where((item) {
        return item.severity == AtlasExecutiveAlertSeverity.high;
      }).length;

      final attention = items.where((item) {
        return item.severity == AtlasExecutiveAlertSeverity.attention;
      }).length;

      final priorityScore =
          items.fold<double>(0, (sum, item) => sum + item.priorityScore) /
          items.length;

      result.add(
        AtlasExecutiveFarmAlertSummary(
          farmName: entry.key,
          total: items.length,
          critical: critical,
          high: high,
          attention: attention,
          priorityScore: priorityScore.clamp(0.0, 100.0),
          mainAlertTitle: items.first.title,
        ),
      );
    }

    result.sort((first, second) {
      if (first.critical != second.critical) {
        return second.critical.compareTo(first.critical);
      }

      return second.priorityScore.compareTo(first.priorityScore);
    });

    return result;
  }

  List<AtlasExecutiveAreaAlertSummary> _buildAreaSummaries(
    List<AtlasExecutiveAlert> alerts,
  ) {
    final grouped = <AtlasFarmAnalysisArea, List<AtlasExecutiveAlert>>{};

    for (final alert in alerts) {
      grouped.putIfAbsent(alert.area, () => []);

      grouped[alert.area]!.add(alert);
    }

    final result = <AtlasExecutiveAreaAlertSummary>[];

    for (final entry in grouped.entries) {
      result.add(
        AtlasExecutiveAreaAlertSummary(
          area: entry.key,
          label: atlasFarmAreaLabel(entry.key),
          total: entry.value.length,
          critical: entry.value.where((item) {
            return item.severity == AtlasExecutiveAlertSeverity.critical;
          }).length,
          high: entry.value.where((item) {
            return item.severity == AtlasExecutiveAlertSeverity.high;
          }).length,
        ),
      );
    }

    result.sort((first, second) {
      if (first.critical != second.critical) {
        return second.critical.compareTo(first.critical);
      }

      return second.total.compareTo(first.total);
    });

    return result;
  }

  double _priorityScore({
    required AtlasExecutiveAlertSeverity severity,
    required double baseImpact,
    required int deadlineDays,
  }) {
    final severityWeight = switch (severity) {
      AtlasExecutiveAlertSeverity.informational => 20.0,
      AtlasExecutiveAlertSeverity.attention => 45.0,
      AtlasExecutiveAlertSeverity.high => 70.0,
      AtlasExecutiveAlertSeverity.critical => 90.0,
    };

    final deadlineWeight = deadlineDays <= 0
        ? 10.0
        : deadlineDays == 1
        ? 8.0
        : deadlineDays <= 3
        ? 5.0
        : 2.0;

    return (severityWeight * 0.65 +
            baseImpact.clamp(0.0, 100.0) * 0.25 +
            deadlineWeight)
        .clamp(0.0, 100.0);
  }

  String _buildSummary({
    required int total,
    required int attention,
    required int high,
    required int critical,
    required AtlasExecutiveAlert? mainAlert,
    required AtlasExecutiveFarmAlertSummary? mostCriticalFarm,
  }) {
    if (total == 0) {
      return 'Nenhum alerta executivo foi identificado na operação.';
    }

    final buffer = StringBuffer();

    buffer.write(
      'A operação possui $total '
      '${total == 1 ? 'alerta' : 'alertas'}: '
      '$critical críticos, $high altos e '
      '$attention em atenção. ',
    );

    if (mostCriticalFarm != null) {
      buffer.write(
        'A fazenda com maior necessidade de resposta é '
        '${mostCriticalFarm.farmName}. ',
      );
    }

    if (mainAlert != null) {
      buffer.write(
        'O alerta prioritário é '
        '"${mainAlert.title}".',
      );
    }

    return buffer.toString().trim();
  }

  String _id({
    required String farmName,
    required AtlasExecutiveAlertType type,
    required String suffix,
  }) {
    return '${_normalize(farmName)}_'
        '${type.name}_'
        '${_normalize(suffix)}';
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  String _currency(double value) {
    final fixed = value.abs().toStringAsFixed(2);

    final parts = fixed.split('.');

    final integer = parts.first;
    final decimal = parts.last;

    final buffer = StringBuffer();

    for (var index = 0; index < integer.length; index++) {
      final remaining = integer.length - index;

      buffer.write(integer[index]);

      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    final sign = value < 0 ? '-' : '';

    return '${sign}R\$ ${buffer.toString()},$decimal';
  }
}

class AtlasExecutiveFarmAlertInput {
  const AtlasExecutiveFarmAlertInput({
    required this.farmName,
    required this.intelligence,
    required this.diagnostic,
    required this.trackedActions,
    this.healthRecords = const [],
    this.reproductionRecords = const [],
  });

  final String farmName;

  final AtlasFarmIntelligenceData intelligence;
  final AtlasDiagnosticData diagnostic;

  final List<AtlasAiTrackedAction> trackedActions;
  final List<AtlasExecutiveAnimalHealthContext> healthRecords;
  final List<AtlasExecutiveAnimalReproductionContext> reproductionRecords;
}

class AtlasExecutiveAnimalHealthContext {
  const AtlasExecutiveAnimalHealthContext({
    required this.groupName,
    required this.animalId,
    required this.animalLabel,
    required this.record,
  });

  final String groupName;
  final String animalId;
  final String animalLabel;
  final AnimalHealthData record;
}

class AtlasExecutiveAnimalReproductionContext {
  const AtlasExecutiveAnimalReproductionContext({
    required this.groupName,
    required this.animalId,
    required this.animalLabel,
    required this.record,
  });

  final String groupName;
  final String animalId;
  final String animalLabel;
  final AnimalReproductionData record;
}

DateTime? _parseOperationalDate(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return null;

  final iso = DateTime.tryParse(normalized);
  if (iso != null) return iso;

  final parts = normalized.split('/');
  if (parts.length != 3) return null;

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;

  try {
    return DateTime(year, month, day);
  } catch (_) {
    return null;
  }
}
