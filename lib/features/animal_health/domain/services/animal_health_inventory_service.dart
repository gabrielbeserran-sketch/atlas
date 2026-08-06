import 'package:projeto_atlas/features/animal_health/domain/models/animal_health_data.dart';
import 'package:projeto_atlas/features/farm_inventory/data/services/farm_inventory_storage_service.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';

class AnimalHealthInventoryResult {
  const AnimalHealthInventoryResult({
    required this.record,
    required this.message,
    required this.success,
  });

  final AnimalHealthData record;
  final String message;
  final bool success;
}

class AnimalHealthInventoryService {
  AnimalHealthInventoryService({FarmInventoryStorageService? storage})
      : storage = storage ?? FarmInventoryStorageService();

  final FarmInventoryStorageService storage;

  Future<AnimalHealthInventoryResult> deductForHealthRecord({
    required String farmName,
    required String animalName,
    required AnimalHealthData record,
  }) async {
    if (record.inventoryItemId.isEmpty || record.inventoryQuantity <= 0) {
      return AnimalHealthInventoryResult(
        record: record,
        message: 'Registro salvo sem movimentação de estoque.',
        success: true,
      );
    }

    final items = await storage.loadItems(farmName);
    final index = items.indexWhere((item) => item.id == record.inventoryItemId);
    if (index < 0) {
      return AnimalHealthInventoryResult(
        record: record,
        message: 'Registro salvo, mas o produto selecionado não foi encontrado no estoque.',
        success: false,
      );
    }

    final item = items[index];
    if (item.quantity < record.inventoryQuantity) {
      return AnimalHealthInventoryResult(
        record: record,
        message: 'Registro salvo, mas não há saldo suficiente de ${item.name}.',
        success: false,
      );
    }

    final movement = FarmInventoryMovement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: 'Saída',
      quantity: record.inventoryQuantity,
      date: record.date,
      responsible: record.responsible.isEmpty ? 'Usuário Atlas' : record.responsible,
      reason: 'Uso sanitário em $animalName — ${record.type}',
      document: 'SAN-${record.id}',
      unitValue: item.unitValue,
    );

    final cost = record.inventoryQuantity * item.unitValue;
    items[index] = item.copyWith(
      quantity: item.quantity - record.inventoryQuantity,
      movements: <FarmInventoryMovement>[movement, ...item.movements],
    );
    await storage.saveItems(farmName: farmName, items: items);

    final updatedRecord = AnimalHealthData(
      id: record.id,
      type: record.type,
      date: record.date,
      product: record.product,
      dose: record.dose,
      responsible: record.responsible,
      notes: record.notes,
      protocol: record.protocol,
      productBatch: record.productBatch,
      applicationRoute: record.applicationRoute,
      frequency: record.frequency,
      diagnosis: record.diagnosis,
      severity: record.severity,
      nextDate: record.nextDate,
      withdrawalEndDate: record.withdrawalEndDate,
      status: record.status,
      isQuarantine: record.isQuarantine,
      isMortality: record.isMortality,
      necropsyResult: record.necropsyResult,
      inventoryItemId: record.inventoryItemId,
      inventoryQuantity: record.inventoryQuantity,
      inventoryDeducted: true,
      treatmentCost: cost,
    );

    return AnimalHealthInventoryResult(
      record: updatedRecord,
      message: 'Saída de ${record.inventoryQuantity.toStringAsFixed(2)} ${item.unit} registrada no estoque.',
      success: true,
    );
  }
}
