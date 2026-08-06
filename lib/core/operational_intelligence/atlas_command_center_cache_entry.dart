import 'package:projeto_atlas/core/operational_intelligence/atlas_command_center_snapshot.dart';
import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_domain.dart';

class AtlasCommandCenterCacheEntry {
  const AtlasCommandCenterCacheEntry({
    required this.key,
    required this.snapshot,
    required this.createdAt,
    required this.expiresAt,
    required this.version,
    required this.domains,
  });

  final String key;
  final AtlasCommandCenterSnapshot snapshot;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int version;
  final Set<AtlasOperationalDomain> domains;

  bool isExpired(DateTime now) {
    return !expiresAt.isAfter(now);
  }

  bool affectsAny(
    Set<AtlasOperationalDomain> invalidatedDomains,
  ) {
    if (invalidatedDomains.contains(
      AtlasOperationalDomain.unknown,
    )) {
      return true;
    }

    return domains.any(invalidatedDomains.contains);
  }
}
