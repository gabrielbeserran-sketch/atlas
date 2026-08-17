import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/atlas_supply_logistics_enterprise/domain/models/atlas_supply_logistics_record.dart';
import 'package:projeto_atlas/features/atlas_supply_logistics_enterprise/domain/services/atlas_supply_logistics_analytics_service.dart';

void main() {
  const service = AtlasSupplyLogisticsAnalyticsService();

  test('calculates supply logistics analytics', () {
    final records = [
      AtlasSupplyLogisticsRecord(
        id: '1',
        module: AtlasSupplyLogisticsModule.intelligentPurchasing,
        feature: 'Pedido',
        title: 'Compra de suplemento',
        date: '04/08/2026',
        dueDate: '10/08/2026',
        status: 'Aprovado',
        priority: 'Alta',
        farmName: 'Fazenda A',
        supplierName: 'Fornecedor A',
        warehouseName: 'Depósito 1',
        itemName: 'Suplemento mineral',
        batchCode: 'L001',
        vehicleName: '',
        driverName: '',
        quantity: 100,
        unit: 'kg',
        unitCost: 5,
        freightCost: 100,
        plannedValue: 600,
        actualValue: 590,
        progressPercent: 80,
        qualityPercent: 90,
        alertCount: 0,
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
      AtlasSupplyLogisticsRecord(
        id: '2',
        module: AtlasSupplyLogisticsModule.intelligentPurchasing,
        feature: 'Recebimento',
        title: 'Entrega atrasada',
        date: '04/08/2026',
        dueDate: '01/08/2026',
        status: 'Atenção',
        priority: 'Urgente',
        farmName: 'Fazenda A',
        supplierName: 'Fornecedor B',
        warehouseName: 'Depósito 1',
        itemName: 'Medicamento',
        batchCode: 'L002',
        vehicleName: '',
        driverName: '',
        quantity: 20,
        unit: 'un',
        unitCost: 30,
        freightCost: 50,
        plannedValue: 650,
        actualValue: 700,
        progressPercent: 50,
        qualityPercent: 60,
        alertCount: 1,
        notes: '',
        createdAt: '',
        updatedAt: '',
      ),
    ];

    final result = service.analyze(
      module: AtlasSupplyLogisticsModule.intelligentPurchasing,
      records: records,
    );

    expect(result.coveragePercent, 40);
    expect(result.operationalCount, 1);
    expect(result.alertCount, greaterThan(0));
    expect(result.totalQuantity, 120);
    expect(result.totalActualValue, 1290);
    expect(result.score, inInclusiveRange(0, 100));
  });
}
