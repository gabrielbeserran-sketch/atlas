import 'package:projeto_atlas/features/farm/data/services/farm_storage_service.dart';

import '../../domain/models/atlas_enterprise_24a_data.dart';
import 'atlas_enterprise_24a_repository.dart';

class AtlasEnterprise24AMigrationReport {
  const AtlasEnterprise24AMigrationReport({
    required this.fromVersion,
    required this.toVersion,
    required this.companies,
    required this.memberships,
    required this.farms,
    required this.consultantLinks,
    required this.messages,
  });

  final int fromVersion;
  final int toVersion;
  final int companies;
  final int memberships;
  final int farms;
  final int consultantLinks;
  final List<String> messages;
}

class AtlasEnterprise24AMigrationService {
  const AtlasEnterprise24AMigrationService();

  static const int targetVersion = 1;

  Future<AtlasEnterprise24AMigrationReport> migrate() async {
    final repository = AtlasEnterprise24ARepository.instance;
    var snapshot = await repository.load();

    if (snapshot.migrationVersion >= targetVersion) {
      return AtlasEnterprise24AMigrationReport(
        fromVersion: snapshot.migrationVersion,
        toVersion: snapshot.migrationVersion,
        companies: snapshot.companies.length,
        memberships: snapshot.memberships.length,
        farms: snapshot.farms.length,
        consultantLinks: snapshot.consultantLinks.length,
        messages: const <String>[
          'A migração 24A já foi aplicada.',
        ],
      );
    }

    final fromVersion = snapshot.migrationVersion;
    final messages = <String>[];

    if (snapshot.companies.isEmpty) {
      throw StateError(
        'Não foi possível determinar a empresa inicial.',
      );
    }

    final session = snapshot.session;
    final companyId =
        session?.companyId ?? snapshot.companies.first.id;
    final actorUserId =
        session?.userId ?? 'legacy_migration';

    final legacyFarms =
        await FarmStorageService().loadFarmsUnscoped();

    for (final farm in legacyFarms) {
      await repository.ensureFarm(
        companyId: companyId,
        name: farm.name,
        city: farm.city,
        state: farm.state,
        userId: actorUserId,
      );
    }

    snapshot = await repository.load();

    final consultants = snapshot.memberships.where(
      (item) =>
          item.role == AtlasEnterpriseMembershipRole.consultant &&
          item.active,
    );

    for (final consultant in consultants) {
      final alreadyLinked = snapshot.consultantLinks.any(
        (item) =>
            item.companyId == consultant.companyId &&
            item.consultantUserId == consultant.userId &&
            item.active,
      );
      if (!alreadyLinked) {
        await repository.saveConsultantLink(
          companyId: consultant.companyId,
          consultantUserId: consultant.userId,
          consultantName: consultant.userName,
          farmIds: const <String>[],
          isLeadConsultant: false,
          actorUserId: actorUserId,
        );
      }
    }

    await repository.setMigrationVersion(targetVersion);
    snapshot = await repository.load();

    messages.add(
      '${snapshot.companies.length} empresa(s) no modelo canônico.',
    );
    messages.add(
      '${snapshot.farms.length} fazenda(s) vinculada(s) por companyId/tenantId.',
    );
    messages.add(
      '${snapshot.memberships.length} vínculo(s) de usuário migrado(s).',
    );
    messages.add(
      '${snapshot.consultantLinks.length} vínculo(s) de consultoria ativo(s).',
    );

    return AtlasEnterprise24AMigrationReport(
      fromVersion: fromVersion,
      toVersion: targetVersion,
      companies: snapshot.companies.length,
      memberships: snapshot.memberships.length,
      farms: snapshot.farms.length,
      consultantLinks: snapshot.consultantLinks.length,
      messages: messages,
    );
  }
}
