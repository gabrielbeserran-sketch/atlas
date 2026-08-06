import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:projeto_atlas/core/network/atlas_environment.dart';
import 'package:projeto_atlas/features/enterprise_platform/data/services/atlas_enterprise_remote_auth_store.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';

class AtlasHttpException implements Exception {
  const AtlasHttpException(
    this.message, {
    this.statusCode,
    this.code,
    this.retryable = false,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final bool retryable;

  @override
  String toString() => message;
}

class AtlasHttpResponse {
  const AtlasHttpResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  final int statusCode;
  final dynamic body;
  final Map<String, String> headers;

  Map<String, dynamic> asMap() =>
      Map<String, dynamic>.from(body as Map);

  List<Map<String, dynamic>> asMapList() =>
      (body as List<dynamic>)
          .map(
            (item) => Map<String, dynamic>.from(
              item as Map,
            ),
          )
          .toList();
}

class AtlasHttpClient {
  AtlasHttpClient({
    http.Client? client,
    AtlasEnterpriseRemoteAuthStore? authStore,
  })  : _client = client ?? http.Client(),
        _authStore =
            authStore ?? AtlasEnterpriseRemoteAuthStore.instance;

  final http.Client _client;
  final AtlasEnterpriseRemoteAuthStore _authStore;

  Future<AtlasHttpResponse> send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool authenticated = true,
    bool retryOnUnauthorized = true,
    int transientRetries = 1,
  }) async {
    final baseUrl = await _authStore.baseUrl();
    final normalizedPath =
        path.startsWith('/') ? path : '/$path';

    var uri = Uri.parse('$baseUrl$normalizedPath');
    if (queryParameters != null) {
      uri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          ...queryParameters,
        },
      );
    }

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Atlas-Client': 'flutter',
    };

    if (authenticated) {
      final session = await _validSession();
      headers['Authorization'] =
          'Bearer ${session.accessToken}';
      if (session.companyId.isNotEmpty) {
        headers['X-Atlas-Company-Id'] =
            session.companyId;
      }
    }

    http.Response response;

    try {
      response = await _execute(
        method,
        uri,
        headers,
        body,
      ).timeout(
        AtlasEnvironmentConfig.current.receiveTimeout,
      );
    } on TimeoutException {
      if (transientRetries > 0) {
        return send(
          method,
          path,
          body: body,
          queryParameters: queryParameters,
          authenticated: authenticated,
          retryOnUnauthorized: retryOnUnauthorized,
          transientRetries: transientRetries - 1,
        );
      }

      throw const AtlasHttpException(
        'O servidor demorou para responder.',
        code: 'timeout',
        retryable: true,
      );
    } on SocketException {
      throw const AtlasHttpException(
        'Sem conexão com o servidor Atlas.',
        code: 'network_unavailable',
        retryable: true,
      );
    } on http.ClientException {
      throw const AtlasHttpException(
        'Falha de comunicação com o servidor Atlas.',
        code: 'client_error',
        retryable: true,
      );
    }

    if (response.statusCode == 401 &&
        authenticated &&
        retryOnUnauthorized) {
      final refreshed = await _refreshSession();

      if (refreshed) {
        return send(
          method,
          path,
          body: body,
          queryParameters: queryParameters,
          authenticated: true,
          retryOnUnauthorized: false,
          transientRetries: transientRetries,
        );
      }
    }

    final decoded = _decodeBody(response.body);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final message = decoded is Map
          ? decoded['detail']?.toString() ??
              decoded['message']?.toString() ??
              decoded['error']?.toString() ??
              'Erro HTTP ${response.statusCode}.'
          : 'Erro HTTP ${response.statusCode}.';

      throw AtlasHttpException(
        message,
        statusCode: response.statusCode,
        code: decoded is Map
            ? decoded['code']?.toString()
            : null,
        retryable:
            response.statusCode == 408 ||
                response.statusCode == 429 ||
                response.statusCode >= 500,
      );
    }

    return AtlasHttpResponse(
      statusCode: response.statusCode,
      body: decoded,
      headers: response.headers,
    );
  }

  Future<AtlasRemoteSession> _validSession() async {
    final session = await _authStore.loadSession();

    if (session == null) {
      throw const AtlasHttpException(
        'Faça login para continuar.',
        statusCode: 401,
        code: 'missing_session',
      );
    }

    if (session.hasUsableAccessToken) {
      return session;
    }

    final refreshed = await _refreshSession();
    final newSession = await _authStore.loadSession();

    if (!refreshed || newSession == null) {
      throw const AtlasHttpException(
        'Sua sessão expirou. Entre novamente.',
        statusCode: 401,
        code: 'expired_session',
      );
    }

    return newSession;
  }

  Future<bool> _refreshSession() async {
    final session = await _authStore.loadSession();

    if (session == null || session.refreshToken.isEmpty) {
      await _authStore.clearSession();
      return false;
    }

    try {
      final response = await send(
        'POST',
        '/auth/refresh',
        authenticated: false,
        retryOnUnauthorized: false,
        transientRetries: 0,
        body: {
          'refresh_token': session.refreshToken,
          'device_name': Platform.localHostname,
        },
      );

      final refreshed = AtlasRemoteSession.fromMap(
        response.asMap(),
      );

      await _authStore.saveSession(refreshed);
      return refreshed.accessToken.isNotEmpty;
    } catch (_) {
      await _authStore.clearSession();
      return false;
    }
  }

  Future<http.Response> _execute(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) {
    final encodedBody =
        body == null ? null : jsonEncode(body);

    return switch (method.toUpperCase()) {
      'GET' => _client.get(uri, headers: headers),
      'POST' => _client.post(
          uri,
          headers: headers,
          body: encodedBody,
        ),
      'PUT' => _client.put(
          uri,
          headers: headers,
          body: encodedBody,
        ),
      'PATCH' => _client.patch(
          uri,
          headers: headers,
          body: encodedBody,
        ),
      'DELETE' => _client.delete(
          uri,
          headers: headers,
          body: encodedBody,
        ),
      _ => throw AtlasHttpException(
          'Método HTTP não suportado: $method',
          code: 'unsupported_method',
        ),
    };
  }

  dynamic _decodeBody(String rawBody) {
    final text = rawBody.trim();

    if (text.isEmpty) return <String, dynamic>{};

    try {
      return jsonDecode(text);
    } catch (_) {
      return text;
    }
  }

  void close() {
    _client.close();
  }
}
