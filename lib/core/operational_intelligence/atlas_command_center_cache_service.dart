import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_cache_entry.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_snapshot.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_domain.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_invalidation.dart';

class AtlasCommandCenterCacheService {
  AtlasCommandCenterCacheService({
    this.defaultTtl = const Duration(minutes: 3),
  });

  final Duration defaultTtl;

  final Map<String, AtlasCommandCenterCacheEntry> _entries =
      <String, AtlasCommandCenterCacheEntry>{};

  int _version = 0;

  int get currentVersion => _version;
  int get entryCount => _entries.length;

  AtlasCommandCenterSnapshot? get({
    required String? farmName,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final key = createKey(farmName);
    final entry = _entries[key];

    if (entry == null) {
      return null;
    }

    if (entry.isExpired(currentTime)) {
      _entries.remove(key);
      return null;
    }

    return entry.snapshot;
  }

  AtlasCommandCenterCacheEntry put({
    required String? farmName,
    required AtlasCommandCenterSnapshot snapshot,
    Duration? ttl,
    Set<AtlasOperationalDomain> domains =
        const <AtlasOperationalDomain>{
      AtlasOperationalDomain.animal,
      AtlasOperationalDomain.reproduction,
      AtlasOperationalDomain.health,
      AtlasOperationalDomain.finance,
      AtlasOperationalDomain.inventory,
      AtlasOperationalDomain.goals,
      AtlasOperationalDomain.tasks,
      AtlasOperationalDomain.decisions,
      AtlasOperationalDomain.workflows,
      AtlasOperationalDomain.executive,
      AtlasOperationalDomain.system,
    },
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final key = createKey(farmName);
    _version += 1;

    final entry = AtlasCommandCenterCacheEntry(
      key: key,
      snapshot: snapshot,
      createdAt: currentTime,
      expiresAt: currentTime.add(ttl ?? defaultTtl),
      version: _version,
      domains: Set<AtlasOperationalDomain>.unmodifiable(domains),
    );

    _entries[key] = entry;
    return entry;
  }

  int invalidate(
    AtlasOperationalInvalidation invalidation,
  ) {
    final keysToRemove = <String>[];

    for (final entry in _entries.entries) {
      final farmName = farmNameFromKey(entry.key);

      if (!invalidation.affectsFarm(farmName)) {
        continue;
      }

      if (!entry.value.affectsAny(invalidation.domains)) {
        continue;
      }

      keysToRemove.add(entry.key);
    }

    for (final key in keysToRemove) {
      _entries.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      _version += 1;
    }

    return keysToRemove.length;
  }

  bool invalidateFarm(String? farmName) {
    final removed = _entries.remove(createKey(farmName));

    if (removed != null) {
      _version += 1;
      return true;
    }

    return false;
  }

  void clear() {
    if (_entries.isEmpty) {
      return;
    }

    _entries.clear();
    _version += 1;
  }

  String createKey(String? farmName) {
    final normalized = farmName?.trim().toLowerCase();

    if (normalized == null || normalized.isEmpty) {
      return 'operation:global';
    }

    return 'operation:$normalized';
  }

  String? farmNameFromKey(String key) {
    if (key == 'operation:global') {
      return null;
    }

    return key.replaceFirst('operation:', '');
  }
}
