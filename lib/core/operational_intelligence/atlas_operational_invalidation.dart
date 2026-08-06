import 'package:projeto_atlas/core/operational_intelligence/atlas_operational_domain.dart';

class AtlasOperationalInvalidation {
  const AtlasOperationalInvalidation({
    required this.farmName,
    required this.domains,
    required this.reason,
    required this.occurredAt,
    required this.eventId,
  });

  final String? farmName;
  final Set<AtlasOperationalDomain> domains;
  final String reason;
  final DateTime occurredAt;
  final String eventId;

  bool affectsFarm(String? candidateFarmName) {
    final normalizedEventFarm = farmName?.trim();
    final normalizedCandidate = candidateFarmName?.trim();

    if (normalizedEventFarm == null || normalizedEventFarm.isEmpty) {
      return true;
    }

    if (normalizedCandidate == null || normalizedCandidate.isEmpty) {
      return true;
    }

    return normalizedEventFarm == normalizedCandidate;
  }

  bool affectsDomain(AtlasOperationalDomain domain) {
    return domains.contains(domain) ||
        domains.contains(AtlasOperationalDomain.unknown);
  }
}
