import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_sustainability_ecosystem/domain/models/atlas_ecosystem_record.dart';
import 'package:projeto_atlas/features/atlas_sustainability_ecosystem/domain/services/atlas_ecosystem_analytics_service.dart';

void main() {
  const service = AtlasEcosystemAnalyticsService();

  test('calculates ecosystem coverage and alerts', () {
    final records = [
      AtlasEcosystemRecord(
        id: '1',
        module: AtlasEcosystemModule.sustainability,
        feature: 'Pegada de carbono',
        title: 'Inventário anual',
        date: '04/08/2026',
        status: 'Concluído',
        primaryValue: 12,
        secondaryValue: 0,
        unit: 'kg CO2e',
        responsible: '',
        reference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasEcosystemRecord(
        id: '2',
        module: AtlasEcosystemModule.sustainability,
        feature: 'Uso da água',
        title: 'Medição pendente',
        date: '04/08/2026',
        status: 'Atenção',
        primaryValue: 30,
        secondaryValue: 0,
        unit: 'm3',
        responsible: '',
        reference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module: AtlasEcosystemModule.sustainability,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.completedCount, 1);
    expect(result.alertCount, 1);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
