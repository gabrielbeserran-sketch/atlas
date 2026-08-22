import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:projeto_atlas/core/network/atlas_environment.dart';
import 'package:projeto_atlas/core/text/atlas_text_normalizer.dart';
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

  Map<String, dynamic> asMap() {
    if (body is! Map) {
      throw const AtlasHttpException(
        'Resposta inválida: objeto JSON esperado.',
        code: 'invalid_response',
      );
    }
    return Map<String, dynamic>.from(body as Map);
  }

  List<Map<String, dynamic>> asMapList() {
    if (body is! List) {
      throw const AtlasHttpException(
        'Resposta inválida: lista JSON esperada.',
        code: 'invalid_response',
      );
    }
    return (body as List<dynamic>).map((item) {
      if (item is! Map) {
        throw const AtlasHttpException(
          'Resposta inválida: item JSON esperado.',
          code: 'invalid_response',
        );
      }
      return Map<String, dynamic>.from(item);
    }).toList();
  }
}

class AtlasHttpClient {
  AtlasHttpClient({
    http.Client? client,
    AtlasEnterpriseRemoteAuthStore? authStore,
  }) : _client = client ?? http.Client(),
       _authStore = authStore ?? AtlasEnterpriseRemoteAuthStore.instance;

  final http.Client _client;
  final AtlasEnterpriseRemoteAuthStore _authStore;
  static const Uuid _uuid = Uuid();
  static final Random _random = Random.secure();

  // Evita várias requisições 401 renovarem a mesma sessão ao mesmo tempo.
  Future<bool>? _refreshInFlight;

  bool _isIdempotentMethod(String method) {
    return switch (method.toUpperCase()) {
      'GET' || 'HEAD' || 'OPTIONS' => true,
      _ => false,
    };
  }

  bool _isTransientStatus(int statusCode) {
    return statusCode == 408 ||
        statusCode == 425 ||
        statusCode == 429 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  Duration _retryDelay(int retriesRemaining, Map<String, String>? headers) {
    final retryAfter = headers?['retry-after'];
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter.trim());
      if (seconds != null && seconds > 0) {
        return Duration(seconds: seconds.clamp(1, 30));
      }
    }

    // 700ms -> 1.4s -> 2.8s, com pequeno jitter.
    final attempt = (3 - retriesRemaining).clamp(0, 3);
    final baseMs = 700 * (1 << attempt);
    final jitterMs = _random.nextInt(250);
    return Duration(milliseconds: baseMs + jitterMs);
  }

  Future<void> _waitBeforeRetry(
    int retriesRemaining, {
    Map<String, String>? headers,
  }) {
    return Future<void>.delayed(
      _retryDelay(retriesRemaining, headers),
    );
  }

  Future<AtlasHttpResponse> send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool authenticated = true,
    bool retryOnUnauthorized = true,
    int transientRetries = 2,
  }) async {
    final baseUrl = await _authStore.baseUrl();
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    var uri = Uri.parse('$baseUrl$normalizedPath');
    if (queryParameters != null) {
      uri = uri.replace(
        queryParameters: {...uri.queryParameters, ...queryParameters},
      );
    }

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Atlas-Client': 'flutter',
      'X-Request-ID': _uuid.v4(),
    };

    if (authenticated) {
      final session = await _validSession();
      headers['Authorization'] = 'Bearer ${session.accessToken}';
      if (session.companyId.isNotEmpty) {
        headers['X-Atlas-Company-Id'] = session.companyId;
      }
      if (session.tenantId.isNotEmpty) {
        headers['X-Atlas-Tenant-Id'] = session.tenantId;
      }
      final activeFarmId = await _authStore.loadActiveFarm();
      if (activeFarmId != null && activeFarmId.isNotEmpty) {
        headers['X-Atlas-Farm-Id'] = activeFarmId;
      }
    }

    http.Response response;

    try {
      response = await _execute(
        method,
        uri,
        headers,
        body,
      ).timeout(AtlasEnvironmentConfig.current.receiveTimeout);
    } on TimeoutException {
      if (transientRetries > 0 && _isIdempotentMethod(method)) {
        await _waitBeforeRetry(transientRetries);
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
      if (transientRetries > 0 && _isIdempotentMethod(method)) {
        await _waitBeforeRetry(transientRetries);
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
        'Sem conexão com o servidor Atlas.',
        code: 'network_unavailable',
        retryable: true,
      );
    } on http.ClientException {
      if (transientRetries > 0 && _isIdempotentMethod(method)) {
        await _waitBeforeRetry(transientRetries);
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
        'Falha de comunicação com o servidor Atlas.',
        code: 'client_error',
        retryable: true,
      );
    }

    if (response.statusCode == 401 && authenticated && retryOnUnauthorized) {
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

    final decoded = _decodeBodyBytes(response.bodyBytes);

    if (_isTransientStatus(response.statusCode) &&
        transientRetries > 0 &&
        _isIdempotentMethod(method)) {
      await _waitBeforeRetry(
        transientRetries,
        headers: response.headers,
      );
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final baseMessage = decoded is Map
          ? decoded['detail']?.toString() ??
                decoded['message']?.toString() ??
                decoded['error']?.toString() ??
                'Erro HTTP ${response.statusCode}.'
          : 'Erro HTTP ${response.statusCode}.';
      final requestId = decoded is Map
          ? decoded['request_id']?.toString()
          : null;
      final message = requestId != null && requestId.isNotEmpty
          ? '$baseMessage (ID: $requestId)'
          : baseMessage;

      throw AtlasHttpException(
        message,
        statusCode: response.statusCode,
        code: decoded is Map
            ? (decoded['code'] ?? decoded['error'])?.toString()
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

  Future<bool> _refreshSession() {
    final existing = _refreshInFlight;
    if (existing != null) return existing;

    final operation = _refreshSessionOnce();
    _refreshInFlight = operation;

    return operation.whenComplete(() {
      if (identical(_refreshInFlight, operation)) {
        _refreshInFlight = null;
      }
    });
  }

  Future<bool> _refreshSessionOnce() async {
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

      final refreshed = AtlasRemoteSession.fromMap(response.asMap());
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
    final encodedBody = body == null
        ? null
        : jsonEncode(AtlasTextNormalizer.normalize(body));

    return switch (method.toUpperCase()) {
      'GET' => _client.get(uri, headers: headers),
      'POST' => _client.post(uri, headers: headers, body: encodedBody),
      'PUT' => _client.put(uri, headers: headers, body: encodedBody),
      'PATCH' => _client.patch(uri, headers: headers, body: encodedBody),
      'DELETE' => _client.delete(uri, headers: headers, body: encodedBody),
      _ => throw AtlasHttpException(
        'Método HTTP não suportado: $method',
        code: 'unsupported_method',
      ),
    };
  }

  dynamic _decodeBodyBytes(List<int> rawBytes) {
    if (rawBytes.isEmpty) return <String, dynamic>{};

    String text;
    try {
      // A API Atlas usa JSON UTF-8. Ler os bytes explicitamente evita que o
      // cliente aplique um charset inadequado quando o header não o informa.
      text = utf8.decode(rawBytes, allowMalformed: false).trim();
    } catch (_) {
      text = latin1.decode(rawBytes, allowInvalid: true).trim();
    }

    if (text.isEmpty) return <String, dynamic>{};

    try {
      return AtlasTextNormalizer.normalize(jsonDecode(text));
    } catch (_) {
      return AtlasTextNormalizer.repair(text);
    }
  }


  Future<AtlasHttpResponse> uploadFile(
    String method,
    String path, {
    required String filePath,
    required String fileField,
    Map<String, String> fields = const <String, String>{},
    bool retryOnUnauthorized = true,
  }) async {
    final baseUrl = await _authStore.baseUrl();
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$normalizedPath');
    final session = await _validSession();

    final request = http.MultipartRequest(method.toUpperCase(), uri);
    request.headers.addAll(
      await _authenticatedHeaders(session, includeJsonContentType: false),
    );
    request.fields.addAll(fields);
    request.files.add(
      await http.MultipartFile.fromPath(fileField, filePath),
    );

    http.StreamedResponse streamed;
    try {
      streamed = await _client
          .send(request)
          .timeout(AtlasEnvironmentConfig.current.receiveTimeout);
    } on TimeoutException {
      throw const AtlasHttpException(
        'O servidor demorou para receber o arquivo.',
        code: 'timeout',
        retryable: true,
      );
    } on SocketException {
      throw const AtlasHttpException(
        'Sem conexão com o servidor Atlas.',
        code: 'network_unavailable',
        retryable: true,
      );
    }

    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401 && retryOnUnauthorized) {
      final refreshed = await _refreshSession();
      if (refreshed) {
        return uploadFile(
          method,
          path,
          filePath: filePath,
          fileField: fileField,
          fields: fields,
          retryOnUnauthorized: false,
        );
      }
    }

    final decoded = _decodeBodyBytes(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AtlasHttpException(
        decoded is Map
            ? decoded['detail']?.toString() ?? 'Falha no upload.'
            : 'Falha no upload.',
        statusCode: response.statusCode,
        retryable: response.statusCode >= 500 || response.statusCode == 429,
      );
    }

    return AtlasHttpResponse(
      statusCode: response.statusCode,
      body: decoded,
      headers: response.headers,
    );
  }

  Future<List<int>> downloadBytes(
    String path, {
    bool retryOnUnauthorized = true,
  }) async {
    final baseUrl = await _authStore.baseUrl();
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$normalizedPath');
    final session = await _validSession();

    http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: await _authenticatedHeaders(
          session,
          includeJsonContentType: false,
        ),
      ).timeout(AtlasEnvironmentConfig.current.receiveTimeout);
    } on TimeoutException {
      throw const AtlasHttpException(
        'O servidor demorou para preparar o download.',
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
        'Falha de comunicação durante o download.',
        code: 'client_error',
        retryable: true,
      );
    }

    if (response.statusCode == 401 && retryOnUnauthorized) {
      final refreshed = await _refreshSession();
      if (refreshed) {
        return downloadBytes(path, retryOnUnauthorized: false);
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = _decodeBodyBytes(response.bodyBytes);
      throw AtlasHttpException(
        decoded is Map
            ? decoded['detail']?.toString() ?? 'Falha no download.'
            : 'Falha no download.',
        statusCode: response.statusCode,
        retryable: response.statusCode >= 500 || response.statusCode == 429,
      );
    }

    return response.bodyBytes;
  }

  Future<Map<String, String>> _authenticatedHeaders(
    AtlasRemoteSession session, {
    required bool includeJsonContentType,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'X-Atlas-Client': 'flutter',
      'X-Request-ID': _uuid.v4(),
      'Authorization': 'Bearer ${session.accessToken}',
    };

    if (includeJsonContentType) {
      headers['Content-Type'] = 'application/json';
    }

    if (session.companyId.isNotEmpty) {
      headers['X-Atlas-Company-Id'] = session.companyId;
    }
    if (session.tenantId.isNotEmpty) {
      headers['X-Atlas-Tenant-Id'] = session.tenantId;
    }

    final activeFarmId = await _authStore.loadActiveFarm();
    if (activeFarmId != null && activeFarmId.isNotEmpty) {
      headers['X-Atlas-Farm-Id'] = activeFarmId;
    }

    return headers;
  }

  void close() {
    _client.close();
  }
}
