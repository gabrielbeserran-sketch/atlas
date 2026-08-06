import 'dart:convert';

import 'package:projeto_atlas/features/knowledge_learning/domain/models/atlas_knowledge_case.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasKnowledgeRepository {
  AtlasKnowledgeRepository._();

  static final AtlasKnowledgeRepository instance = AtlasKnowledgeRepository._();
  static const String _storageKey = 'atlas_knowledge_cases_v2';
  static const String _legacyStorageKey = 'atlas_knowledge_cases_v1';

  Future<List<AtlasKnowledgeCase>> loadCases() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey) ?? preferences.getString(_legacyStorageKey);
    if (raw == null || raw.isEmpty) return <AtlasKnowledgeCase>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <AtlasKnowledgeCase>[];
      final result = decoded
          .whereType<Map>()
          .map((item) => AtlasKnowledgeCase.fromJson(Map<String, dynamic>.from(item)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return result;
    } catch (_) {
      return <AtlasKnowledgeCase>[];
    }
  }

  Future<void> saveAll(List<AtlasKnowledgeCase> cases) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(cases.take(500).map((item) => item.toJson()).toList()),
    );
  }

  Future<void> save(AtlasKnowledgeCase item) async {
    final current = await loadCases();
    final index = current.indexWhere((value) => value.id == item.id);
    if (index < 0) {
      current.insert(0, item);
    } else {
      current[index] = item;
    }
    await saveAll(current);
  }

  Future<void> addCases(List<AtlasKnowledgeCase> newCases) async {
    final current = await loadCases();
    final byId = <String, AtlasKnowledgeCase>{
      for (final item in current) item.id: item,
      for (final item in newCases) item.id: item,
    };
    await saveAll(byId.values.toList());
  }

  Future<void> delete(String id) async {
    final current = await loadCases();
    await saveAll(current.where((item) => item.id != id).toList());
  }
}
