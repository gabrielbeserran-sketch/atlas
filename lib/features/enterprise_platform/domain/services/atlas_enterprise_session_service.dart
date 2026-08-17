import 'package:flutter/foundation.dart';

import '../../data/services/atlas_enterprise_24a_repository.dart';
import '../models/atlas_enterprise_24a_data.dart';

import 'atlas_enterprise_audit_service.dart';

class AtlasEnterpriseSessionService extends ChangeNotifier {
  AtlasEnterpriseSessionService._();

  static final AtlasEnterpriseSessionService instance =
      AtlasEnterpriseSessionService._();

  final AtlasEnterprise24ARepository _repository =
      AtlasEnterprise24ARepository.instance;

  AtlasEnterprise24ASnapshot? _snapshot;
  bool _initialized = false;

  bool get isInitialized => _initialized;
  AtlasEnterprise24ASnapshot? get snapshot => _snapshot;
  AtlasEnterpriseSession? get session => _snapshot?.session;

  String? get currentUserId => session?.userId;
  String? get currentCompanyId => session?.companyId;
  String? get currentFarmId => session?.farmId;

  AtlasEnterpriseCompany? get currentCompany {
    final id = currentCompanyId;
    final values = _snapshot?.companies;
    if (id == null || values == null) return null;
    for (final item in values) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _snapshot = await _repository.load();
    _initialized = true;
  }

  Future<void> reload() async {
    _snapshot = await _repository.load();
    _initialized = true;
    notifyListeners();
  }

  Future<List<AtlasEnterpriseCompany>> availableCompanies() async {
    await ensureInitialized();
    final userId = currentUserId;
    if (userId == null) return <AtlasEnterpriseCompany>[];
    return _repository.companiesForUser(userId);
  }

  Future<List<AtlasEnterpriseFarm>> availableFarms() async {
    await ensureInitialized();
    final userId = currentUserId;
    final companyId = currentCompanyId;
    if (userId == null || companyId == null) {
      return <AtlasEnterpriseFarm>[];
    }
    return _repository.farmsAllowedForUser(
      companyId: companyId,
      userId: userId,
    );
  }

  Future<void> switchCompany(String companyId) async {
    await ensureInitialized();
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('Nenhum usuário empresarial ativo.');
    }

    final allowed = await _repository.canUserAccessCompany(
      userId: userId,
      companyId: companyId,
    );
    if (!allowed) {
      throw StateError('O usuário atual não possui acesso a esta empresa.');
    }

    final next = AtlasEnterpriseSession(
      userId: userId,
      companyId: companyId,
      farmId: null,
      startedAt: DateTime.now(),
    );
    final previousCompanyId = currentCompanyId;
    await _repository.saveSession(next);
    await AtlasEnterpriseAuditService.instance.record(
      action: 'switch_company',
      module: 'enterprise',
      entityType: 'session',
      entityId: next.userId,
      description: 'Empresa ativa alterada.',
      companyId: companyId,
      userId: next.userId,
      before: <String, dynamic>{'companyId': previousCompanyId},
      after: <String, dynamic>{'companyId': companyId},
    );
    await reload();
  }

  Future<void> switchFarm(String? farmId) async {
    await ensureInitialized();
    final current = session;
    if (current == null) {
      throw StateError('Sessão empresarial não inicializada.');
    }

    if (farmId != null) {
      final allowed = await _repository.canUserAccessFarm(
        userId: current.userId,
        companyId: current.companyId,
        farmId: farmId,
      );
      if (!allowed) {
        throw StateError('O usuário atual não possui acesso a esta fazenda.');
      }
    }

    final previousFarmId = current.farmId;
    await _repository.saveSession(
      current.copyWith(farmId: farmId, replaceFarmId: true),
    );
    await AtlasEnterpriseAuditService.instance.record(
      action: 'switch_farm',
      module: 'enterprise',
      entityType: 'session',
      entityId: current.userId,
      description: 'Contexto de fazenda alterado.',
      companyId: current.companyId,
      farmId: farmId,
      userId: current.userId,
      before: <String, dynamic>{'farmId': previousFarmId},
      after: <String, dynamic>{'farmId': farmId},
    );
    await reload();
  }

  Future<bool> canAccessFarm(String farmId) async {
    await ensureInitialized();
    final current = session;
    if (current == null) return false;
    return _repository.canUserAccessFarm(
      userId: current.userId,
      companyId: current.companyId,
      farmId: farmId,
    );
  }
}
