import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/features/farm_operations/data/services/atlas_operations_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'abrir central vazia não cria operações nem grava preferências',
    () async {
      final repository = AtlasOperationsRepository();
      expect(await repository.load(farmId: 'fazenda-a'), isEmpty);
      expect(await repository.load(farmId: 'fazenda-b'), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('atlas_farm_operations_v1'), isFalse);
    },
  );

  test('lista vazia salva permanece vazia sem exemplos automáticos', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('atlas_farm_operations_v1', '[]');
    expect(await AtlasOperationsRepository().load(farmId: 'a'), isEmpty);
    expect(prefs.getString('atlas_farm_operations_v1'), '[]');
  });

  test('consulta preserva integralmente registros existentes', () async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode([
      {
        'id': 'real-1',
        'farmId': 'a',
        'title': 'Conferir bebedouro',
        'description': '',
        'type': 'pasture',
        'status': 'planned',
        'priority': 'medium',
        'responsible': 'Equipe',
        'team': [],
        'equipment': [],
        'scheduledAt': '2026-09-26T10:00:00',
        'estimatedHours': 1,
        'actualHours': 0,
        'plannedCost': 50,
        'actualCost': 0,
        'progress': 0,
        'notes': '',
      },
    ]);
    await prefs.setString('atlas_farm_operations_v1', raw);
    final items = await AtlasOperationsRepository().load(farmId: 'a');
    expect(items.single.id, 'real-1');
    expect(items.single.plannedCost, 50);
    expect(prefs.getString('atlas_farm_operations_v1'), raw);
  });
}
