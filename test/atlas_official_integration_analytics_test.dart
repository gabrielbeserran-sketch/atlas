import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_official_integrations/domain/models/atlas_official_integration_record.dart';
import 'package:projeto_atlas/features/atlas_official_integrations/domain/services/atlas_official_integration_analytics_service.dart';

void main() {
  const service =
      AtlasOfficialIntegrationAnalyticsService();

  test('calculates official integration coverage', () {
    final records = [
      AtlasOfficialIntegrationRecord(
        id: '1',
        module: AtlasOfficialIntegrationModule.sisbov,
        feature: 'Identificação individual',
        title: 'Animal 001',
        date: '04/08/2026',
        status: 'Válido',
        externalId: 'SISBOV-001',
        origin: 'Fazenda A',
        destination: '',
        responsible: 'Responsável',
        quantity: 1,
        progressPercent: 100,
        alertCount: 0,
        expirationDate: '',
        reference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasOfficialIntegrationRecord(
        id: '2',
        module: AtlasOfficialIntegrationModule.sisbov,
        feature: 'Pendências de conformidade',
        title: 'Documento pendente',
        date: '04/08/2026',
        status: 'Atenção',
        externalId: '',
        origin: '',
        destination: '',
        responsible: '',
        quantity: 1,
        progressPercent: 40,
        alertCount: 1,
        expirationDate: '',
        reference: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module: AtlasOfficialIntegrationModule.sisbov,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.score, inInclusiveRange(0, 100));
  });
}
