import 'dart:convert';

import 'package:projeto_atlas/core/subscription/atlas_subscription_profile.dart';
import 'package:projeto_atlas/core/subscription/atlas_subscription_service.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Organiza o menu; não substitui permissões da sessão nem autorização da API.
class AtlasWorkerMenuPolicy {
  static const primaryLabels = <String>{
    'Dashboard',
    'Rebanho',
    'Realizar manejo',
    'Agenda',
    'Campo',
    'Offline',
    'Configurações',
  };

  static bool compactFor({required String role, required bool consultancy}) =>
      role == 'operator' && consultancy;

  static bool isPrimary(String label) => primaryLabels.contains(label);
}

class AtlasWorkerMenuEntitlement {
  AtlasWorkerMenuEntitlement({
    SharedPreferencesAsync? preferences,
    Future<AtlasSubscriptionProfile> Function()? loadProfile,
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _loadProfile =
           loadProfile ?? AtlasSubscriptionService.instance.loadCurrent;

  final SharedPreferencesAsync _preferences;
  final Future<AtlasSubscriptionProfile> Function() _loadProfile;

  String? scopeKey(AtlasRemoteSession session) {
    if (session.tenantId.trim().isEmpty || session.companyId.trim().isEmpty) {
      return null;
    }
    final encoded = base64Url.encode(
      utf8.encode(jsonEncode([session.tenantId, session.companyId])),
    );
    return 'atlas_worker_menu_consultancy_v1_$encoded';
  }

  Future<bool?> loadCached(AtlasRemoteSession session) async {
    final key = scopeKey(session);
    return key == null ? null : _preferences.getBool(key);
  }

  Future<bool> fetchConfirmed() async {
    final profile = await _loadProfile();
    return profile.hasActiveConsultancy;
  }

  Future<void> saveFor(AtlasRemoteSession session, bool enabled) async {
    final key = scopeKey(session);
    if (key == null) {
      throw StateError('Empresa sem identidade verificável.');
    }
    await _preferences.setBool(key, enabled);
  }
}
