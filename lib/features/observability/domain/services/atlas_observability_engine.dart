import 'dart:math';

import 'package:projeto_atlas/features/observability/domain/models/atlas_observability_data.dart';

class AtlasObservabilityEngine {
  const AtlasObservabilityEngine();

  int healthScore(List<AtlasHealthCheck> checks) {
    if (checks.isEmpty) {
      return 0;
    }
    int total = 0;
    for (final AtlasHealthCheck check in checks) {
      switch (check.status) {
        case AtlasHealthStatus.healthy:
          total += 100;
        case AtlasHealthStatus.warning:
          total += 65;
        case AtlasHealthStatus.critical:
          total += 20;
      }
    }
    return (total / checks.length).round();
  }

  int averageResponseTime(List<AtlasHealthCheck> checks) {
    if (checks.isEmpty) {
      return 0;
    }
    final int total = checks.fold<int>(
      0,
      (int value, AtlasHealthCheck item) => value + item.responseTimeMs,
    );
    return (total / checks.length).round();
  }

  AtlasObservabilityData runDiagnostic(AtlasObservabilityData current) {
    final DateTime now = DateTime.now();
    final Random random = Random();
    final List<AtlasHealthCheck> updatedChecks = current.healthChecks.map((
      AtlasHealthCheck check,
    ) {
      final int response = 40 + random.nextInt(300);
      final AtlasHealthStatus status;
      if (response >= 300) {
        status = AtlasHealthStatus.critical;
      } else if (response >= 190) {
        status = AtlasHealthStatus.warning;
      } else {
        status = AtlasHealthStatus.healthy;
      }
      return check.copyWith(
        status: status,
        responseTimeMs: response,
        checkedAt: now,
      );
    }).toList();

    final int criticalCount = updatedChecks
        .where(
          (AtlasHealthCheck item) => item.status == AtlasHealthStatus.critical,
        )
        .length;
    final int warningCount = updatedChecks
        .where(
          (AtlasHealthCheck item) => item.status == AtlasHealthStatus.warning,
        )
        .length;

    final AtlasLogLevel level = criticalCount > 0
        ? AtlasLogLevel.error
        : warningCount > 0
        ? AtlasLogLevel.warning
        : AtlasLogLevel.info;
    final String message = criticalCount > 0
        ? 'Diagnóstico concluído com $criticalCount módulo(s) em estado crítico.'
        : warningCount > 0
        ? 'Diagnóstico concluído com $warningCount módulo(s) em atenção.'
        : 'Diagnóstico concluído: todos os módulos estão saudáveis.';

    final List<AtlasSystemLog> logs = <AtlasSystemLog>[
      AtlasSystemLog(
        id: 'diagnostic_${now.microsecondsSinceEpoch}',
        module: 'Observability Center',
        message: message,
        level: level,
        createdAt: now,
      ),
      ...current.logs,
    ];

    return AtlasObservabilityData(
      healthChecks: updatedChecks,
      logs: logs.take(100).toList(),
      lastDiagnosticAt: now,
    );
  }
}
