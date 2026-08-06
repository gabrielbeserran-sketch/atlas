import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_geospatial_platform/domain/models/atlas_geospatial_record.dart';
import 'package:projeto_atlas/features/atlas_geospatial_platform/domain/services/atlas_geospatial_analytics_service.dart';

void main() {
  const service = AtlasGeospatialAnalyticsService();

  test('calculates geospatial analytics', () {
    final records = [
      AtlasGeospatialRecord(
        id: '1',
        module: AtlasGeospatialModule.gisMaps,
        feature: 'Limites e áreas',
        title: 'Área principal',
        date: '04/08/2026',
        status: 'Validado',
        areaName: 'Fazenda A',
        areaHectares: 100,
        latitude: -15.0,
        longitude: -47.0,
        metricName: 'Área',
        metricValue: 100,
        unit: 'ha',
        qualityPercent: 95,
        progressPercent: 100,
        alertCount: 0,
        referenceDate: '',
        source: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasGeospatialRecord(
        id: '2',
        module: AtlasGeospatialModule.gisMaps,
        feature: 'Medições',
        title: 'Medição pendente',
        date: '04/08/2026',
        status: 'Atenção',
        areaName: 'Piquete 1',
        areaHectares: 20,
        latitude: -15.1,
        longitude: -47.1,
        metricName: 'Perímetro',
        metricValue: 2500,
        unit: 'm',
        qualityPercent: 50,
        progressPercent: 40,
        alertCount: 1,
        referenceDate: '',
        source: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module: AtlasGeospatialModule.gisMaps,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.totalAreaHectares, 120);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
