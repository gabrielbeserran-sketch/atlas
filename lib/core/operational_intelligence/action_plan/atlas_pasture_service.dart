import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_pasture_models.dart';

class AtlasPastureService {
  AtlasPastureService._();
  static final instance = AtlasPastureService._();

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  static const _paddocksKey = 'atlas_paddocks_v1';
  static const _rotationsKey = 'atlas_grazing_rotations_v1';
  static const _operationsKey = 'atlas_pasture_operations_v1';

  Future<List<AtlasPaddock>> loadPaddocks({String? farmName}) async {
    final raw = await _prefs.getString(_paddocksKey);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => AtlasPaddock.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return _farm(list, farmName, (e) => e.farmName);
  }

  Future<void> savePaddock(AtlasPaddock value) async {
    final all = await loadPaddocks();
    final index = all.indexWhere((e) => e.id == value.id);
    if (index < 0) {
      all.add(value);
    } else {
      all[index] = value;
    }
    await _prefs.setString(
      _paddocksKey,
      jsonEncode(all.map((e) => e.toMap()).toList()),
    );
  }

  Future<List<AtlasGrazingRotation>> loadRotations({String? farmName}) async {
    final raw = await _prefs.getString(_rotationsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => AtlasGrazingRotation.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return _farm(list, farmName, (e) => e.farmName);
  }

  Future<void> saveRotation(AtlasGrazingRotation value) async {
    final all = await loadRotations();
    final index = all.indexWhere((e) => e.id == value.id);
    if (index < 0) {
      all.add(value);
    } else {
      all[index] = value;
    }
    await _prefs.setString(
      _rotationsKey,
      jsonEncode(all.map((e) => e.toMap()).toList()),
    );
  }

  Future<List<AtlasPastureOperation>> loadOperations({String? farmName}) async {
    final raw = await _prefs.getString(_operationsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => AtlasPastureOperation.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return _farm(list, farmName, (e) => e.farmName);
  }

  Future<void> saveOperation(AtlasPastureOperation value) async {
    final all = await loadOperations();
    final index = all.indexWhere((e) => e.id == value.id);
    if (index < 0) {
      all.add(value);
    } else {
      all[index] = value;
    }
    await _prefs.setString(
      _operationsKey,
      jsonEncode(all.map((e) => e.toMap()).toList()),
    );
  }

  List<String> alerts(
    List<AtlasPaddock> paddocks,
    List<AtlasPastureOperation> operations,
  ) {
    final result = <String>[
      for (final item in paddocks)
        if (item.belowTargetHeight) '${item.name}: altura abaixo da meta.',
      for (final item in paddocks)
        if (item.dryMatterKgHa < 1000)
          '${item.name}: baixa disponibilidade de matéria seca.',
      for (final item in operations)
        if (item.isOverdue)
          '${atlasPastureOperationTypeLabel(item.type)} atrasada.',
    ];
    return result.isEmpty ? ['Nenhum alerta crítico de pastagem.'] : result;
  }

  List<T> _farm<T>(
    List<T> values,
    String? farmName,
    String? Function(T) readFarm,
  ) {
    final normalized = farmName?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return values;
    return values
        .where((e) => readFarm(e)?.trim().toLowerCase() == normalized)
        .toList();
  }
}
