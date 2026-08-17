import 'package:projeto_atlas/features/enterprise_platform/data/services/atlas_enterprise_remote_auth_store.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';

class AtlasActiveContext {
  AtlasActiveContext._();

  static final AtlasActiveContext instance = AtlasActiveContext._();

  final AtlasEnterpriseRemoteAuthStore _store =
      AtlasEnterpriseRemoteAuthStore.instance;

  AtlasRemoteSession? _session;
  String? _farmId;

  AtlasRemoteSession? get session => _session;
  String? get companyId => _session?.companyId;
  String? get tenantId => _session?.tenantId;
  String? get farmId => _farmId;

  Future<void> restore() async {
    _session = await _store.loadSession();
    _farmId = await _store.loadActiveFarm();
  }

  Future<void> selectFarm(String farmId) async {
    // Sempre consulta a sessão mais recente persistida. O backend pode alterar
    // a carteira de fazendas após um CRUD e o token/contexto local anterior não
    // deve causar um falso "Fazenda não autorizada".
    final session = await _store.loadSession() ?? _session;
    _session = session;

    if (session == null) {
      throw StateError('Sessão não encontrada.');
    }

    if (!session.hasUnrestrictedFarmAccess &&
        session.farmIds.isNotEmpty &&
        !session.farmIds.contains(farmId)) {
      throw StateError('Fazenda não autorizada.');
    }

    _farmId = farmId;
    await _store.saveActiveFarm(farmId);
  }

  Future<void> clearFarm() async {
    _farmId = null;
    await _store.clearActiveFarm();
  }

  Future<void> clear() async {
    _session = null;
    _farmId = null;
    await _store.clearSession();
  }
}
