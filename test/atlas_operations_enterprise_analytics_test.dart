import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_operations_enterprise/domain/models/atlas_operations_enterprise_record.dart';
import 'package:projeto_atlas/features/atlas_operations_enterprise/domain/services/atlas_operations_enterprise_analytics_service.dart';

void main() {
  const service = AtlasOperationsEnterpriseAnalyticsService();

  test('calculates operations enterprise analytics', () {
    final records = [
      AtlasOperationsEnterpriseRecord(
        id: '1',
        module:
            AtlasOperationsEnterpriseModule.farmOperationalPlanning,
        feature: 'Plano semanal',
        title: 'Plano da semana',
        date: '04/08/2026',
        dueDate: '10/08/2026',
        status: 'Em execução',
        priority: 'Alta',
        farmName: 'Fazenda A',
        areaName: 'Curral',
        responsible: 'Gestor',
        teamName: 'Equipe 1',
        assetName: '',
        plannedHours: 20,
        actualHours: 12,
        plannedCost: 2000,
        actualCost: 1200,
        progressPercent: 60,
        qualityPercent: 90,
        alertCount: 0,
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasOperationsEnterpriseRecord(
        id: '2',
        module:
            AtlasOperationsEnterpriseModule.farmOperationalPlanning,
        feature: 'Metas e responsáveis',
        title: 'Meta atrasada',
        date: '04/08/2026',
        dueDate: '01/08/2026',
        status: 'Atenção',
        priority: 'Urgente',
        farmName: 'Fazenda A',
        areaName: 'Pastagem',
        responsible: '',
        teamName: '',
        assetName: '',
        plannedHours: 10,
        actualHours: 5,
        plannedCost: 1000,
        actualCost: 900,
        progressPercent: 50,
        qualityPercent: 60,
        alertCount: 1,
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module:
          AtlasOperationsEnterpriseModule.farmOperationalPlanning,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.totalPlannedHours, 30);
    expect(result.totalActualCost, 2100);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
