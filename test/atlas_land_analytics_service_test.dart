import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_land_intelligence/domain/models/atlas_land_record.dart';
import 'package:projeto_atlas/features/atlas_land_intelligence/domain/services/atlas_land_analytics_service.dart';

void main() {
  const service = AtlasLandAnalyticsService();

  test('calculates feature coverage and alerts', () {
    final records = [
      AtlasLandRecord(
        id: '1',
        module: AtlasLandModule.genetics,
        feature: 'Cadastro genético completo',
        title: 'Índice genético',
        date: '04/08/2026',
        status: 'Concluído',
        primaryValue: 80,
        secondaryValue: 0,
        unit: 'índice',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasLandRecord(
        id: '2',
        module: AtlasLandModule.genetics,
        feature: 'Acasalamento inteligente',
        title: 'Risco de consanguinidade',
        date: '04/08/2026',
        status: 'Atenção',
        primaryValue: 6,
        secondaryValue: 0,
        unit: '%',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module: AtlasLandModule.genetics,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.completedCount, 1);
    expect(result.alertCount, 1);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
