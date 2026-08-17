import 'package:flutter/foundation.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_action_attention.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_action_attention_preferences.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_action_attention_service.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_command_center_action.dart';

class AtlasActionAttentionController extends ChangeNotifier {
  AtlasActionAttentionController({
    AtlasActionAttentionService service = const AtlasActionAttentionService(),
    AtlasActionAttentionPreferences? preferences,
  }) : _service = service,
       _preferences = preferences ?? AtlasActionAttentionPreferences.instance;

  final AtlasActionAttentionService _service;
  final AtlasActionAttentionPreferences _preferences;

  List<AtlasActionAttention> _items = <AtlasActionAttention>[];
  bool _isLoading = false;

  List<AtlasActionAttention> get items =>
      List<AtlasActionAttention>.unmodifiable(_items);

  bool get isLoading => _isLoading;

  int get criticalCount => _items
      .where((item) => item.severity == AtlasActionAttentionSeverity.critical)
      .length;

  int get warningCount => _items
      .where((item) => item.severity == AtlasActionAttentionSeverity.warning)
      .length;

  Future<void> rebuild({
    required List<AtlasCommandCenterAction> actions,
    required Map<String, DateTime> latestUpdateDates,
  }) async {
    _isLoading = true;
    notifyListeners();

    await _preferences.clearExpired();
    final snoozed = await _preferences.loadSnoozedUntil();
    final now = DateTime.now();

    _items = _service
        .build(actions: actions, latestUpdateDates: latestUpdateDates)
        .where((attention) {
          final until = snoozed[attention.id];
          return until == null || !until.isAfter(now);
        })
        .toList(growable: false);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> snooze(AtlasActionAttention attention) async {
    await _preferences.snooze(
      attentionId: attention.id,
      duration: const Duration(days: 1),
    );

    _items = _items
        .where((item) => item.id != attention.id)
        .toList(growable: false);
    notifyListeners();
  }
}
