import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/operational_readiness/domain/models/atlas_operational_readiness_report.dart';

void main() {
  test('relatório padrão está aprovado', () {
    final report = AtlasOperationalReadinessReport.standard();
    expect(report.checks, isNotEmpty);
    expect(report.blockedCount, 0);
    expect(report.warningCount, 0);
    expect(report.progress, 1);
    expect(report.readyForProduction, isTrue);
  });

  test('bloqueio impede prontidão', () {
    const report = AtlasOperationalReadinessReport(
      checks: [
        AtlasReadinessCheck(
          id: 'x',
          title: 'X',
          category: 'Teste',
          status: AtlasReadinessStatus.blocked,
          detail: 'Falhou',
        ),
      ],
    );
    expect(report.readyForProduction, isFalse);
  });
}
