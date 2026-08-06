import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_version.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_invalidation.dart';

class AtlasCommandCenterVersionService {
  AtlasCommandCenterVersionService();

  final Map<String, AtlasCommandCenterVersion> _versions =
      <String, AtlasCommandCenterVersion>{};

  AtlasCommandCenterVersion current(String? farmName) {
    final key = _key(farmName);

    return _versions[key] ??
        AtlasCommandCenterVersion(
          number: 0,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
          reason: 'Versão inicial',
          eventId: null,
          farmName: farmName,
        );
  }

  AtlasCommandCenterVersion advance(
    AtlasOperationalInvalidation invalidation,
  ) {
    final keys = <String>{
      _key(invalidation.farmName),
      _key(null),
    };

    AtlasCommandCenterVersion? latest;

    for (final key in keys) {
      final currentVersion = _versions[key]?.number ?? 0;
      final farmName = key == _key(null)
          ? null
          : invalidation.farmName;

      final next = AtlasCommandCenterVersion(
        number: currentVersion + 1,
        updatedAt: DateTime.now(),
        reason: invalidation.reason,
        eventId: invalidation.eventId,
        farmName: farmName,
      );

      _versions[key] = next;
      latest = next;
    }

    return latest!;
  }

  void reset() {
    _versions.clear();
  }

  String _key(String? farmName) {
    final normalized = farmName?.trim().toLowerCase();

    if (normalized == null || normalized.isEmpty) {
      return 'global';
    }

    return normalized;
  }
}
