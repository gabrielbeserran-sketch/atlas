import '../models/atlas_enterprise_24a_data.dart';
import 'atlas_enterprise_session_service.dart';

class AtlasEnterpriseScopeGuard {
  const AtlasEnterpriseScopeGuard();

  Future<void> requireCompany(String companyId) async {
    final session = AtlasEnterpriseSessionService.instance;
    await session.ensureInitialized();

    if (session.currentCompanyId != companyId) {
      throw StateError(
        'Acesso bloqueado: o registro pertence a outra empresa.',
      );
    }
  }

  Future<void> requireFarm(AtlasEnterpriseFarm farm) async {
    await requireCompany(farm.scope.companyId);

    final allowed = await AtlasEnterpriseSessionService.instance.canAccessFarm(
      farm.id,
    );
    if (!allowed) {
      throw StateError(
        'Acesso bloqueado: o usuário não possui vínculo com esta fazenda.',
      );
    }
  }

  Future<void> requireEntityScope(AtlasEntityScope scope) async {
    await requireCompany(scope.companyId);

    final farmId = scope.farmId;
    if (farmId != null) {
      final allowed = await AtlasEnterpriseSessionService.instance
          .canAccessFarm(farmId);
      if (!allowed) {
        throw StateError('Acesso bloqueado pelo isolamento multiempresa.');
      }
    }
  }
}
