import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/atlas_quality_data.dart';

class AtlasQualityRepository {
  static const String _checksKey = 'atlas_quality_checks_v1';
  static const String _incidentsKey = 'atlas_quality_incidents_v1';
  static const String _reviewKey = 'atlas_quality_review_v1';

  Future<AtlasQualityState> load() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String? checksRaw = preferences.getString(_checksKey);
    final String? incidentsRaw = preferences.getString(_incidentsKey);

    if (checksRaw == null || checksRaw.isEmpty) {
      final AtlasQualityState seeded = _seed();
      await save(seeded);
      return seeded;
    }

    final List<dynamic> checksJson = jsonDecode(checksRaw) as List<dynamic>;
    final List<dynamic> incidentsJson = incidentsRaw == null || incidentsRaw.isEmpty
        ? <dynamic>[]
        : jsonDecode(incidentsRaw) as List<dynamic>;

    return AtlasQualityState(
      checks: checksJson
          .map((dynamic item) => AtlasQualityCheck.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      incidents: incidentsJson
          .map((dynamic item) => AtlasQualityIncident.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      lastReviewAt: DateTime.tryParse(
            preferences.getString(_reviewKey) ?? '',
          ) ??
          DateTime.now(),
    );
  }

  Future<void> save(AtlasQualityState state) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _checksKey,
      jsonEncode(state.checks.map((AtlasQualityCheck item) => item.toJson()).toList()),
    );
    await preferences.setString(
      _incidentsKey,
      jsonEncode(
        state.incidents.map((AtlasQualityIncident item) => item.toJson()).toList(),
      ),
    );
    await preferences.setString(_reviewKey, state.lastReviewAt.toIso8601String());
  }

  AtlasQualityState _seed() {
    return AtlasQualityState(
      checks: const <AtlasQualityCheck>[
        AtlasQualityCheck(
          id: 'analyze',
          title: 'Executar flutter analyze',
          description: 'Confirmar que não existem erros de compilação ou avisos críticos.',
          category: 'Código',
          completed: false,
          critical: true,
        ),
        AtlasQualityCheck(
          id: 'navigation',
          title: 'Testar navegação principal',
          description: 'Abrir o dashboard e validar o acesso aos módulos essenciais.',
          category: 'Interface',
          completed: false,
          critical: true,
        ),
        AtlasQualityCheck(
          id: 'persistence',
          title: 'Validar persistência local',
          description: 'Criar, editar e reabrir registros armazenados no aparelho.',
          category: 'Dados',
          completed: false,
          critical: true,
        ),
        AtlasQualityCheck(
          id: 'offline',
          title: 'Validar modo offline',
          description: 'Registrar informações sem conexão e testar a fila de sincronização.',
          category: 'Campo',
          completed: false,
          critical: false,
        ),
        AtlasQualityCheck(
          id: 'permissions',
          title: 'Revisar perfis e permissões',
          description: 'Conferir acessos de administrador, consultor, técnico e produtor.',
          category: 'Segurança',
          completed: false,
          critical: false,
        ),
        AtlasQualityCheck(
          id: 'backup',
          title: 'Definir rotina de backup',
          description: 'Documentar a estratégia de cópia e recuperação dos dados.',
          category: 'Dados',
          completed: false,
          critical: false,
        ),
      ],
      incidents: <AtlasQualityIncident>[
        AtlasQualityIncident(
          id: 'seed_enterprise_const',
          title: 'Uso indevido de const corrigido',
          description: 'Construtor de usuário Enterprise utilizava variável em contexto constante.',
          module: 'Enterprise Platform',
          severity: 'Média',
          createdAt: DateTime.now(),
          resolved: true,
          resolvedAt: DateTime.now(),
        ),
      ],
      lastReviewAt: DateTime.now(),
    );
  }
}
