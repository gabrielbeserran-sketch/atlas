import 'dart:convert';

import 'package:projeto_atlas/features/command_center/domain/models/atlas_command_center_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AtlasCommandRepository {
  static const String _itemsKey = 'atlas_command_center_items_v1';
  static const String _updatedKey = 'atlas_command_center_updated_v1';

  Future<AtlasCommandCenterState> load() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final String? rawItems = preferences.getString(_itemsKey);

    if (rawItems == null || rawItems.isEmpty) {
      final AtlasCommandCenterState initialState = _seed();
      await save(initialState);
      return initialState;
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawItems) as List<dynamic>;
      final List<AtlasCommandItem> items = decoded
          .map(
            (dynamic item) => AtlasCommandItem.fromJson(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
            ),
          )
          .toList();

      return AtlasCommandCenterState(
        items: items,
        lastUpdatedAt: DateTime.tryParse(
              preferences.getString(_updatedKey) ?? '',
            ) ??
            DateTime.now(),
      );
    } catch (_) {
      final AtlasCommandCenterState initialState = _seed();
      await save(initialState);
      return initialState;
    }
  }

  Future<void> save(AtlasCommandCenterState state) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.setString(
      _itemsKey,
      jsonEncode(
        state.items.map((AtlasCommandItem item) => item.toJson()).toList(),
      ),
    );
    await preferences.setString(
      _updatedKey,
      state.lastUpdatedAt.toIso8601String(),
    );
  }

  AtlasCommandCenterState _seed() {
    final DateTime now = DateTime.now();
    return AtlasCommandCenterState(
      lastUpdatedAt: now,
      items: <AtlasCommandItem>[
        AtlasCommandItem(
          id: 'command_health_1',
          title: 'Revisar lote com atenção sanitária',
          description:
              'Há registros que exigem conferência clínica e atualização do protocolo sanitário.',
          category: AtlasCommandCategory.sanitary,
          priority: AtlasCommandPriority.critical,
          status: AtlasCommandItemStatus.newItem,
          sourceModule: 'Saúde Animal',
          createdAt: now.subtract(const Duration(hours: 2)),
          dueAt: now.add(const Duration(hours: 6)),
          actionLabel: 'Abrir protocolo',
        ),
        AtlasCommandItem(
          id: 'command_finance_1',
          title: 'Validar despesas da semana',
          description:
              'Confirme os lançamentos pendentes para manter a projeção financeira atualizada.',
          category: AtlasCommandCategory.financial,
          priority: AtlasCommandPriority.high,
          status: AtlasCommandItemStatus.inProgress,
          sourceModule: 'Financeiro',
          createdAt: now.subtract(const Duration(days: 1)),
          dueAt: now.add(const Duration(days: 1)),
          actionLabel: 'Revisar despesas',
        ),
        AtlasCommandItem(
          id: 'command_operations_1',
          title: 'Concluir pesagens programadas',
          description:
              'A agenda operacional possui animais ainda sem pesagem registrada neste ciclo.',
          category: AtlasCommandCategory.operational,
          priority: AtlasCommandPriority.high,
          status: AtlasCommandItemStatus.newItem,
          sourceModule: 'Farm Operations',
          createdAt: now.subtract(const Duration(hours: 5)),
          dueAt: now.subtract(const Duration(hours: 1)),
          actionLabel: 'Abrir operação',
        ),
        AtlasCommandItem(
          id: 'command_strategy_1',
          title: 'Acompanhar meta de ganho de peso',
          description:
              'O indicador deve ser revisado antes da próxima reunião de acompanhamento.',
          category: AtlasCommandCategory.strategic,
          priority: AtlasCommandPriority.medium,
          status: AtlasCommandItemStatus.newItem,
          sourceModule: 'Executive KPIs',
          createdAt: now.subtract(const Duration(days: 2)),
          dueAt: now.add(const Duration(days: 3)),
          actionLabel: 'Ver indicador',
        ),
        AtlasCommandItem(
          id: 'command_agenda_1',
          title: 'Preparar visita técnica',
          description:
              'Organize checklist, histórico e recomendações para a próxima visita à propriedade.',
          category: AtlasCommandCategory.agenda,
          priority: AtlasCommandPriority.medium,
          status: AtlasCommandItemStatus.completed,
          sourceModule: 'Consultancy Hub',
          createdAt: now.subtract(const Duration(days: 3)),
          dueAt: now.subtract(const Duration(days: 1)),
          actionLabel: 'Ver visita',
        ),
      ],
    );
  }
}
