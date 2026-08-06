import 'dart:io';

import 'package:projeto_atlas/core/network/atlas_http_client.dart';

import '../../data/services/atlas_enterprise_remote_auth_store.dart';
import '../models/atlas_enterprise_remote_session.dart';

class AtlasEnterpriseApiException implements Exception {
  const AtlasEnterpriseApiException(
    this.message, {
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class AtlasEnterpriseApiClient {
  AtlasEnterpriseApiClient._();

  static final AtlasEnterpriseApiClient instance =
      AtlasEnterpriseApiClient._();

  final AtlasEnterpriseRemoteAuthStore _store =
      AtlasEnterpriseRemoteAuthStore.instance;

  final AtlasHttpClient _http = AtlasHttpClient();

  Future<AtlasRemoteSession> login({
    required String email,
    required String password,
    String? companyId,
  }) async {
    try {
      final response = await _http.send(
        'POST',
        '/auth/login',
        authenticated: false,
        body: {
          'email': email.trim(),
          'password': password,
          'company_id': companyId,
          'device_name': Platform.localHostname,
        },
      );

      final session = AtlasRemoteSession.fromMap(
        response.asMap(),
      );

      if (session.mfaRequired) {
        return session;
      }

      await _store.saveSession(session);
      return session;
    } on AtlasHttpException catch (error) {
      throw AtlasEnterpriseApiException(
        error.message,
        statusCode: error.statusCode,
        code: error.code,
      );
    }
  }

  Future<AtlasRemoteSession> completeMfa({
    required String challengeToken,
    required String code,
  }) async {
    try {
      final response = await _http.send(
        'POST',
        '/auth/mfa/challenge',
        authenticated: false,
        body: {
          'challenge_token': challengeToken,
          'code': code.trim(),
        },
      );

      final session = AtlasRemoteSession.fromMap(
        response.asMap(),
      );

      await _store.saveSession(session);
      return session;
    } on AtlasHttpException catch (error) {
      throw AtlasEnterpriseApiException(
        error.message,
        statusCode: error.statusCode,
        code: error.code,
      );
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String companyName,
    String companyDocument = '',
  }) async {
    return request(
      'POST',
      '/auth/register',
      authenticated: false,
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'company_name': companyName.trim(),
        'company_document': companyDocument.trim(),
        'accept_terms': true,
      },
    );
  }

  Future<void> confirmEmail(String token) async {
    await request(
      'POST',
      '/auth/confirm-email',
      authenticated: false,
      body: {'token': token.trim()},
    );
  }

  Future<void> requestPasswordReset(String email) async {
    await request(
      'POST',
      '/auth/password/request',
      authenticated: false,
      body: {'email': email.trim()},
    );
  }

  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    await request(
      'POST',
      '/auth/password/confirm',
      authenticated: false,
      body: {
        'token': token.trim(),
        'new_password': newPassword,
      },
    );
  }

  Future<AtlasRemoteSession> me() async {
    final response = await request('GET', '/auth/me');
    final current = await _store.loadSession();

    final session = AtlasRemoteSession.fromMap({
      ...response,
      'access_token': current?.accessToken ?? '',
      'refresh_token': current?.refreshToken ?? '',
      'expires_in_seconds':
          current?.expiresInSeconds ?? 3600,
      'savedAt':
          current?.savedAt.toIso8601String(),
    });

    await _store.saveSession(session);
    return session;
  }

  Future<AtlasRemoteSession> switchCompany(
    String companyId,
  ) async {
    final response = await request(
      'POST',
      '/auth/switch-company',
      body: {'company_id': companyId},
    );

    final session = AtlasRemoteSession.fromMap(response);
    await _store.saveSession(session);
    return session;
  }

  Future<void> logout() async {
    final session = await _store.loadSession();

    if (session?.refreshToken.isNotEmpty == true) {
      try {
        await request(
          'POST',
          '/auth/logout',
          authenticated: false,
          body: {
            'refresh_token': session!.refreshToken,
          },
        );
      } catch (_) {
        // O encerramento local continua mesmo sem rede.
      }
    }

    await _store.clearSession();
  }

  Future<Map<String, dynamic>> health() {
    return request(
      'GET',
      '/health',
      authenticated: false,
    );
  }

  Future<List<Map<String, dynamic>>> backups() {
    return requestList(
      'GET',
      '/backups',
    );
  }

  Future<Map<String, dynamic>> runBackup() {
    return request(
      'POST',
      '/backups/run',
    );
  }

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool authenticated = true,
  }) async {
    try {
      final response = await _http.send(
        method,
        path,
        body: body,
        queryParameters: queryParameters,
        authenticated: authenticated,
      );

      return response.asMap();
    } on AtlasHttpException catch (error) {
      throw AtlasEnterpriseApiException(
        error.message,
        statusCode: error.statusCode,
        code: error.code,
      );
    }
  }

  Future<List<Map<String, dynamic>>> requestList(
    String method,
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final response = await _http.send(
        method,
        path,
        queryParameters: queryParameters,
      );

      return response.asMapList();
    } on AtlasHttpException catch (error) {
      throw AtlasEnterpriseApiException(
        error.message,
        statusCode: error.statusCode,
        code: error.code,
      );
    }
  }
}
