import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'atlas_foundation_models.dart';

class AtlasFoundationRepository {
  static const String _checksKey = 'atlas_foundation_checks_v1';
  static const String _lastReviewKey = 'atlas_foundation_last_review_v1';

  Future<AtlasFoundationSnapshot> load() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? raw = preferences.getString(_checksKey);
    final List<AtlasFoundationCheck> checks;

    if (raw == null || raw.isEmpty) {
      checks = _defaultChecks();
      await save(checks);
    } else {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      checks = decoded
          .whereType<Map<String, dynamic>>()
          .map(AtlasFoundationCheck.fromMap)
          .toList();
    }

    final String? lastReviewRaw = preferences.getString(_lastReviewKey);
    return AtlasFoundationSnapshot(
      checks: checks,
      lastReviewAt: lastReviewRaw == null
          ? null
          : DateTime.tryParse(lastReviewRaw),
    );
  }

  Future<void> save(List<AtlasFoundationCheck> checks) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _checksKey,
      jsonEncode(
        checks.map((AtlasFoundationCheck item) => item.toMap()).toList(),
      ),
    );
    await preferences.setString(
      _lastReviewKey,
      DateTime.now().toIso8601String(),
    );
  }

  List<AtlasFoundationCheck> _defaultChecks() {
    return const <AtlasFoundationCheck>[
      AtlasFoundationCheck(
        id: 'repository_contract',
        title: 'Contrato único de repositórios',
        description:
            'Padronizar leitura, gravação, exclusão e tratamento de falhas.',
        area: 'Persistência',
        isCompleted: true,
        isCritical: true,
      ),
      AtlasFoundationCheck(
        id: 'shared_preferences_inventory',
        title: 'Inventário do SharedPreferences',
        description:
            'Mapear chaves e responsáveis antes da migração para banco local.',
        area: 'Persistência',
        isCompleted: false,
        isCritical: true,
      ),
      AtlasFoundationCheck(
        id: 'navigation_registry',
        title: 'Registro central de rotas',
        description:
            'Centralizar nomes, permissões e destinos das principais telas.',
        area: 'Navegação',
        isCompleted: false,
        isCritical: true,
      ),
      AtlasFoundationCheck(
        id: 'shared_components',
        title: 'Componentes visuais reutilizáveis',
        description:
            'Padronizar cartões, estados vazios, indicadores e diálogos.',
        area: 'Interface',
        isCompleted: false,
        isCritical: false,
      ),
      AtlasFoundationCheck(
        id: 'state_strategy',
        title: 'Estratégia única de estado',
        description:
            'Definir a migração progressiva para Riverpod sem quebrar telas atuais.',
        area: 'Estado',
        isCompleted: false,
        isCritical: true,
      ),
      AtlasFoundationCheck(
        id: 'core_tests',
        title: 'Testes dos motores centrais',
        description: 'Cobrir Orchestrator, Sync, Workflow e Executive Brain.',
        area: 'Testes',
        isCompleted: false,
        isCritical: true,
      ),
      AtlasFoundationCheck(
        id: 'error_contract',
        title: 'Contrato de erros e logs',
        description:
            'Unificar falhas técnicas com Observability e Integration Core.',
        area: 'Observabilidade',
        isCompleted: true,
        isCritical: false,
      ),
    ];
  }
}
