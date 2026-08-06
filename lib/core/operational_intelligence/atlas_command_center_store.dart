import 'package:flutter/foundation.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_snapshot.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_state.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_version.dart';

class AtlasCommandCenterStore extends ChangeNotifier {
  AtlasCommandCenterStore();

  final Map<String, AtlasCommandCenterState> _states =
      <String, AtlasCommandCenterState>{};

  AtlasCommandCenterState stateFor(String? farmName) {
    final key = _key(farmName);

    return _states[key] ??
        AtlasCommandCenterState.initial(
          farmName: farmName,
        );
  }

  AtlasCommandCenterState get globalState => stateFor(null);

  void markLoading(String? farmName) {
    final key = _key(farmName);
    final current = stateFor(farmName);

    _states[key] = current.copyWith(
      isLoading: true,
      clearError: true,
    );

    notifyListeners();
  }

  void publish({
    required String? farmName,
    required AtlasCommandCenterSnapshot snapshot,
    required AtlasCommandCenterVersion version,
  }) {
    final key = _key(farmName);
    final current = stateFor(farmName);

    _states[key] = current.copyWith(
      farmName: farmName,
      replaceFarmName: true,
      snapshot: snapshot,
      version: version,
      isLoading: false,
      updatedAt: DateTime.now(),
      clearError: true,
    );

    notifyListeners();
  }

  void publishError({
    required String? farmName,
    required Object error,
  }) {
    final key = _key(farmName);
    final current = stateFor(farmName);

    _states[key] = current.copyWith(
      isLoading: false,
      errorMessage: error.toString(),
    );

    notifyListeners();
  }

  void clearFarm(String? farmName) {
    final removed = _states.remove(_key(farmName));

    if (removed != null) {
      notifyListeners();
    }
  }

  void clearAll() {
    if (_states.isEmpty) {
      return;
    }

    _states.clear();
    notifyListeners();
  }

  String _key(String? farmName) {
    final normalized = farmName?.trim().toLowerCase();

    if (normalized == null || normalized.isEmpty) {
      return 'global';
    }

    return normalized;
  }
}
