import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_precision_livestock/domain/models/atlas_precision_livestock_record.dart';
import 'package:projeto_atlas/features/atlas_precision_livestock/domain/services/atlas_precision_livestock_analytics_service.dart';

void main() {
  const service =
      AtlasPrecisionLivestockAnalyticsService();

  test('calculates precision livestock analytics', () {
    final records = [
      AtlasPrecisionLivestockRecord(
        id: '1',
        module:
            AtlasPrecisionLivestockModule.weightPrediction,
        feature: 'Peso projetado',
        title: 'Projeção 90 dias',
        date: '04/08/2026',
        status: 'Validado',
        animalReference: '003',
        groupReference: 'Matrizes',
        metricName: 'Peso',
        currentValue: 400,
        projectedValue: 460,
        targetValue: 470,
        unit: 'kg',
        confidencePercent: 90,
        riskPercent: 15,
        financialImpact: 2500,
        progressPercent: 100,
        alertCount: 0,
        horizonDays: 90,
        responsible: 'Consultor',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasPrecisionLivestockRecord(
        id: '2',
        module:
            AtlasPrecisionLivestockModule.weightPrediction,
        feature: 'Desvio e confiança',
        title: 'Revisão pendente',
        date: '04/08/2026',
        status: 'Atenção',
        animalReference: '004',
        groupReference: 'Matrizes',
        metricName: 'Peso',
        currentValue: 380,
        projectedValue: 410,
        targetValue: 450,
        unit: 'kg',
        confidencePercent: 55,
        riskPercent: 60,
        financialImpact: -1000,
        progressPercent: 50,
        alertCount: 1,
        horizonDays: 90,
        responsible: '',
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module:
          AtlasPrecisionLivestockModule.weightPrediction,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.averageCurrent, 390);
    expect(result.totalFinancialImpact, 1500);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
