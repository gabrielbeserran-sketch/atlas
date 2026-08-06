import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:projeto_atlas/core/network/atlas_environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/atlas_enterprise_remote_session.dart';

class AtlasEnterpriseRemoteAuthStore {
  AtlasEnterpriseRemoteAuthStore._();

  static final AtlasEnterpriseRemoteAuthStore instance =
      AtlasEnterpriseRemoteAuthStore._();

  static const _sessionKey =
      'atlas_enterprise_secure_remote_session';
  static const _baseUrlKey =
      'atlas_enterprise_base_url';
  static const _activeFarmKey =
      'atlas_enterprise_active_farm';

  final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<String> baseUrl() async {
    return await _preferences.getString(_baseUrlKey) ??
        AtlasEnvironmentConfig.current.apiBaseUrl;
  }

  Future<void> saveBaseUrl(String value) {
    final normalized =
        value.trim().replaceAll(RegExp(r'/+$'), '');
    return _preferences.setString(
      _baseUrlKey,
      normalized,
    );
  }

  Future<AtlasRemoteSession?> loadSession() async {
    final raw = await _secureStorage.read(key: _sessionKey);

    if (raw == null || raw.trim().isEmpty) return null;

    try {
      return AtlasRemoteSession.fromMap(
        Map<String, dynamic>.from(
          jsonDecode(raw) as Map,
        ),
      );
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> saveSession(
    AtlasRemoteSession session,
  ) {
    return _secureStorage.write(
      key: _sessionKey,
      value: jsonEncode(session.toMap()),
    );
  }

  Future<void> clearSession() async {
    await _secureStorage.delete(key: _sessionKey);
    await _preferences.remove(_activeFarmKey);
  }

  Future<void> saveActiveFarm(String farmId) {
    return _preferences.setString(
      _activeFarmKey,
      farmId,
    );
  }

  Future<String?> loadActiveFarm() {
    return _preferences.getString(_activeFarmKey);
  }
}
