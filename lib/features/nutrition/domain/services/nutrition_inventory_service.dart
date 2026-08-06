import 'package:projeto_atlas/features/farm_inventory/data/services/farm_inventory_storage_service.dart';
import 'package:projeto_atlas/features/farm_inventory/domain/models/farm_inventory_data.dart';
import 'package:projeto_atlas/features/nutrition/domain/models/nutrition_plan_data.dart';

class NutritionInventoryResult {
  const NutritionInventoryResult({required this.plan, required this.message, required this.success});
  final NutritionPlanData plan;
  final String message;
  final bool success;
}

class NutritionInventoryService {
  NutritionInventoryService({FarmInventoryStorageService? storage}) : storage = storage ?? FarmInventoryStorageService();
  final FarmInventoryStorageService storage;

  Future<NutritionInventoryResult> deductDailyConsumption(NutritionPlanData plan) async {
    if (!plan.stockIntegrationEnabled || plan.inventoryDeducted || plan.ingredients.isEmpty) {
      return NutritionInventoryResult(plan: plan, message: 'Dieta salva sem nova movimentação de estoque.', success: true);
    }
    final items = await storage.loadItems(plan.farmName);
    final matches = <int, double>{};
    final missing = <String>[];
    for (final ingredient in plan.ingredients) {
      final index = items.indexWhere((item) => item.name.trim().toLowerCase() == ingredient.name.trim().toLowerCase());
      if (index < 0) { missing.add(ingredient.name); continue; }
      final quantity = ingredient.inclusionKg * plan.animalCount;
      if (quantity <= 0) continue;
      matches[index] = (matches[index] ?? 0) + quantity;
    }
    if (missing.isNotEmpty) {
      return NutritionInventoryResult(plan: plan, message: 'Dieta salva, mas estes ingredientes não foram encontrados no estoque: ${missing.join(', ')}.', success: false);
    }
    for (final entry in matches.entries) {
      if (items[entry.key].quantity < entry.value) {
        return NutritionInventoryResult(plan: plan, message: 'Dieta salva, mas não há saldo suficiente de ${items[entry.key].name}.', success: false);
      }
    }
    var totalCost = 0.0;
    for (final entry in matches.entries) {
      final item = items[entry.key];
      final movement = FarmInventoryMovement(
        id: DateTime.now().microsecondsSinceEpoch.toString(), type: 'Saída',
        quantity: entry.value, date: plan.startDate, responsible: 'Usuário Atlas',
        reason: 'Consumo nutricional diário — ${plan.dietName} / ${plan.groupName}',
        document: 'NUT-${plan.id}', unitValue: item.unitValue,
      );
      totalCost += entry.value * item.unitValue;
      items[entry.key] = item.copyWith(quantity: item.quantity - entry.value, movements: [movement, ...item.movements]);
    }
    await storage.saveItems(farmName: plan.farmName, items: items);
    final updated = plan.copyWith(inventoryDeducted: true, inventoryDeductionCost: totalCost);
    return NutritionInventoryResult(plan: updated, message: 'Consumo diário baixado do estoque. Custo: R\$ ${totalCost.toStringAsFixed(2).replaceAll('.', ',')}.', success: true);
  }
}
