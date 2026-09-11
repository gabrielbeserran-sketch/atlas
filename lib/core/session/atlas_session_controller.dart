import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:projeto_atlas/core/auth/atlas_active_context.dart';
import 'package:projeto_atlas/features/enterprise_platform/data/services/atlas_enterprise_remote_auth_store.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/farm/domain/models/atlas_remote_farm.dart';

const _sessionValidationTimeout = Duration(seconds: 12);

enum AtlasSessionStatus {
  restoring,
  unauthenticated,
  selectingCompany,
  loadingContext,
  authenticated,
  failure,
}

class AtlasSessionController extends ChangeNotifier {
  AtlasSessionController({
    AtlasEnterpriseApiClient? api,
    AtlasEnterpriseRemoteAuthStore? store,
  }) : _api = api ?? AtlasEnterpriseApiClient.instance,
       _store = store ?? AtlasEnterpriseRemoteAuthStore.instance;

  final AtlasEnterpriseApiClient _api;
  final AtlasEnterpriseRemoteAuthStore _store;

  AtlasSessionStatus _status = AtlasSessionStatus.restoring;
  AtlasRemoteSession? _session;
  List<AtlasRemoteFarm> _farms = const [];
  AtlasRemoteFarm? _activeFarm;
  String? _error;
  bool _offlineMode = false;

  AtlasSessionStatus get status => _status;
  AtlasRemoteSession? get session => _session;
  List<AtlasRemoteFarm> get farms => List.unmodifiable(_farms);
  AtlasRemoteFarm? get activeFarm => _activeFarm;
  String? get error => _error;
  bool get offlineMode => _offlineMode;

  bool get isAuthenticated =>
      _status == AtlasSessionStatus.authenticated && _session != null;

  bool allows(String permission) {
    final current = _session;
    if (current == null) return false;
    if (current.role == 'owner' ||
        current.role == 'admin' ||
        current.role == 'companyAdministrator' ||
        current.role == 'superAdministrator') {
      return true;
    }
    if (current.effectivePermissions.isEmpty) return false;
    if (current.effectivePermissions.contains(permission)) return true;
    final namespace = permission.split('.').first;
    return current.effectivePermissions.contains('$namespace.*');
  }

  Future<void> restore() async {
    _setStatus(AtlasSessionStatus.restoring);
    final stored = await _store.loadSession();
    if (stored == null) {
      _session = null;
      _setStatus(AtlasSessionStatus.unauthenticated);
      return;
    }

    // A abertura não depende da rede: usa imediatamente a sessão protegida e
    // o contexto salvo. A atualização remota acontece depois, sem bloquear a
    // interface nem transformar uma demora do servidor em falha de login.
    _session = stored;
    _farms = await _store.loadFarmPortfolio();
    await AtlasActiveContext.instance.restore();
    final savedFarmId = await _store.loadActiveFarm();
    _activeFarm =
        _findFarm(savedFarmId) ?? (_farms.isNotEmpty ? _farms.first : null);
    _offlineMode = false;
    _error = null;
    _setStatus(AtlasSessionStatus.authenticated);
    unawaited(_refreshContextAfterStartup());
  }

  Future<void> _refreshContextAfterStartup() async {
    try {
      final restored = await _api.me().timeout(_sessionValidationTimeout);
      _session = restored;
      await _store.saveSession(restored);
      await _reloadFarmPortfolio();
      _offlineMode = false;
      _error = null;
      notifyListeners();
    } catch (_) {
      // Dados locais continuam disponíveis. O aviso visual é discreto e não
      // troca de tela nem bloqueia ações locais.
      _offlineMode = true;
      notifyListeners();
    }
  }

  Future<void> acceptSession(AtlasRemoteSession session) async {
    _session = session;
    _error = null;
    _offlineMode = false;
    await _store.saveSession(session);
    await AtlasActiveContext.instance.restore();

    if (session.companyId.isEmpty && session.companies.length > 1) {
      _setStatus(AtlasSessionStatus.selectingCompany);
      return;
    }

    await loadContext();
  }

  Future<void> switchCompany(String companyId) async {
    _setStatus(AtlasSessionStatus.loadingContext);
    try {
      final switched = await _api.switchCompany(companyId);
      _session = switched;
      await _store.saveSession(switched);
      await _store.clearActiveFarm();
      await AtlasActiveContext.instance.restore();
      await loadContext();
    } catch (error) {
      _error = error.toString();
      _setStatus(AtlasSessionStatus.failure);
      rethrow;
    }
  }

  Future<void> loadContext() async {
    _setStatus(AtlasSessionStatus.loadingContext);
    try {
      await _reloadFarmPortfolio();
      _error = null;
      _offlineMode = false;
      _setStatus(AtlasSessionStatus.authenticated);
    } catch (error) {
      _error = error.toString();
      _setStatus(AtlasSessionStatus.failure);
    }
  }

  /// Sincroniza a sess├úo e a carteira de fazendas depois de criar, editar ou
  /// desativar uma propriedade. Diferente de [loadContext], n├úo desmonta o
  /// AtlasHomeShell nem troca a tela inteira por um estado de loading/failure.
  Future<void> refreshAfterFarmMutation() async {
    final refreshedSession = await _api.me();
    _session = refreshedSession;
    await _store.saveSession(refreshedSession);
    await _reloadFarmPortfolio();
    _error = null;
    notifyListeners();
  }

  Future<void> refreshFarms() async {
    await _reloadFarmPortfolio();
    _error = null;
    notifyListeners();
  }

  Future<void> _reloadFarmPortfolio() async {
    final previousActiveId = _activeFarm?.id;
    final savedFarmId = await _store.loadActiveFarm();
    final items = await _api.requestList('GET', '/farms');

    _farms =
        items
            .map(AtlasRemoteFarm.fromMap)
            .where((farm) => farm.id.isNotEmpty && farm.active)
            .toList(growable: false)
          ..sort((a, b) => a.name.compareTo(b.name));
    await _store.saveFarmPortfolio(_farms);

    _activeFarm = _findFarm(previousActiveId) ?? _findFarm(savedFarmId);

    if (_activeFarm == null && _farms.length == 1) {
      _activeFarm = _farms.first;
    }

    if (_activeFarm != null) {
      await _store.saveActiveFarm(_activeFarm!.id);
      await AtlasActiveContext.instance.selectFarm(_activeFarm!.id);
    } else {
      await _store.clearActiveFarm();
      await AtlasActiveContext.instance.clearFarm();
    }
  }

  Future<void> selectFarm(AtlasRemoteFarm farm) async {
    await selectFarmById(farm.id);
  }

  /// Seleciona a fazenda validando-a contra o backend quando o contexto local
  /// estiver desatualizado. Evita falsos "Fazenda n├úo autorizada" ap├│s CRUD.
  Future<void> selectFarmById(String farmId) async {
    var target = _findFarm(farmId);
    if (target == null) {
      final remote = await _api.request('GET', '/farms/$farmId');
      target = AtlasRemoteFarm.fromMap(remote);
      if (target.id.isEmpty || !target.active) {
        throw StateError('Fazenda indispon├¡vel para a sess├úo atual.');
      }
      _farms = [..._farms.where((item) => item.id != target!.id), target]
        ..sort((a, b) => a.name.compareTo(b.name));
    }
    await AtlasActiveContext.instance.selectFarm(target.id);
    await _store.saveActiveFarm(target.id);
    _activeFarm = target;
    _error = null;
    if (_status != AtlasSessionStatus.authenticated) {
      _setStatus(AtlasSessionStatus.authenticated);
    } else {
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      await _store.clearActiveFarm();
      await AtlasActiveContext.instance.clear();
      _session = null;
      _farms = const [];
      _activeFarm = null;
      _error = null;
      _offlineMode = false;
      _setStatus(AtlasSessionStatus.unauthenticated);
    }
  }

  AtlasRemoteFarm? _findFarm(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final farm in _farms) {
      if (farm.id == id) return farm;
    }
    return null;
  }

  void _setStatus(AtlasSessionStatus value) {
    _status = value;
    notifyListeners();
  }
}
