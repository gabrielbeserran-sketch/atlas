import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/atlas_farm_operation.dart';

class AtlasOperationsRepository {
  static const _key = 'atlas_farm_operations_v1';

  Future<List<AtlasFarmOperation>> load({String? farmId}) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    List<AtlasFarmOperation> items;
    if (raw == null || raw.isEmpty) {
      items = _seed(farmId);
      await save(items);
    } else {
      final decoded = jsonDecode(raw) as List<dynamic>;
      items = decoded
          .map(
            (e) => AtlasFarmOperation.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }
    return items
        .where((e) => farmId == null || e.farmId == null || e.farmId == farmId)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  Future<void> save(List<AtlasFarmOperation> items) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  List<AtlasFarmOperation> _seed(String? farmId) => [
    AtlasFarmOperation(
      id: 'op_iatf',
      farmId: farmId,
      title: 'Protocolo de IATF',
      description: 'Aplicação do protocolo e conferência do lote.',
      type: AtlasOperationType.reproduction,
      status: AtlasOperationStatus.planned,
      priority: AtlasOperationPriority.high,
      responsible: 'Equipe reprodutiva',
      team: const ['Veterinário', 'Vaqueiro'],
      equipment: const ['Brete', 'Aplicador'],
      scheduledAt: DateTime.now().add(const Duration(days: 2)),
      estimatedHours: 6,
      actualHours: 0,
      plannedCost: 2800,
      actualCost: 0,
      progress: 0,
      notes: 'Confirmar estoque de hormônios.',
    ),
    AtlasFarmOperation(
      id: 'op_vacina',
      farmId: farmId,
      title: 'Vacinação do rebanho',
      description: 'Vacinação e registro dos animais manejados.',
      type: AtlasOperationType.health,
      status: AtlasOperationStatus.inProgress,
      priority: AtlasOperationPriority.critical,
      responsible: 'Responsável sanitário',
      team: const ['Vaqueiro 1', 'Vaqueiro 2'],
      equipment: const ['Brete', 'Seringas'],
      scheduledAt: DateTime.now(),
      estimatedHours: 8,
      actualHours: 3,
      plannedCost: 1900,
      actualCost: 720,
      progress: 42,
      notes: 'Manter cadeia de frio.',
    ),
  ];
}
