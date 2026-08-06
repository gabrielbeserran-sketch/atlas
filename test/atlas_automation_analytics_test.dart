import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_automation_operations/domain/models/atlas_automation_record.dart';
import 'package:projeto_atlas/features/atlas_automation_operations/domain/services/atlas_automation_analytics_service.dart';

void main() {
  const service = AtlasAutomationAnalyticsService();

  test('calculates automation coverage and alerts', () {
    final records = [
      AtlasAutomationRecord(
        id: '1',
        module: AtlasAutomationModule.drone,
        feature: 'Planejamento de voos',
        title: 'Voo 01',
        date: '04/08/2026',
        status: 'Concluído',
        deviceOrResponsible: 'Operador',
        reference: 'Rota A',
        primaryValue: 100,
        secondaryValue: 0,
        unit: 'ha',
        progressPercent: 100,
        alertCount: 0,
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasAutomationRecord(
        id: '2',
        module: AtlasAutomationModule.drone,
        feature: 'Inspeção de cercas',
        title: 'Cerca norte',
        date: '04/08/2026',
        status: 'Atenção',
        deviceOrResponsible: 'Drone A',
        reference: '',
        primaryValue: 5,
        secondaryValue: 0,
        unit: 'km',
        progressPercent: 60,
        alertCount: 2,
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module: AtlasAutomationModule.drone,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.score, inInclusiveRange(0, 100));
  });
}
