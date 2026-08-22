enum AtlasEnvironment { development, staging, production }

class AtlasEnvironmentConfig {
  const AtlasEnvironmentConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.enableNetworkLogs,
  });

  final AtlasEnvironment environment;
  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableNetworkLogs;

  static const String _definedEnvironment = String.fromEnvironment(
    'ATLAS_ENV',
    defaultValue: 'development',
  );
  static const String _definedApiBaseUrl = String.fromEnvironment(
    'ATLAS_API_BASE_URL',
    defaultValue: '',
  );

  static AtlasEnvironmentConfig current = _fromDefines();

  static const development = AtlasEnvironmentConfig(
    environment: AtlasEnvironment.development,
    apiBaseUrl: 'http://127.0.0.1:8000/api/v1',
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 25),
    enableNetworkLogs: true,
  );

  static const staging = AtlasEnvironmentConfig(
    environment: AtlasEnvironment.staging,
    apiBaseUrl: '',
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 30),
    enableNetworkLogs: true,
  );

  static const production = AtlasEnvironmentConfig(
    environment: AtlasEnvironment.production,
    apiBaseUrl: '',
    connectTimeout: Duration(seconds: 15),
    // Render/Supabase podem ter cold start; o cliente aplica retries apenas
    // a operações idempotentes, portanto este limite maior não causa
    // duplicação de POST/PATCH/DELETE.
    receiveTimeout: Duration(seconds: 60),
    enableNetworkLogs: false,
  );

  static AtlasEnvironmentConfig _fromDefines() {
    final selected = switch (_definedEnvironment.trim().toLowerCase()) {
      'production' => production,
      'staging' => staging,
      _ => development,
    };

    final definedUrl = normalizeApiBaseUrl(_definedApiBaseUrl);

    if (selected.environment == AtlasEnvironment.production) {
      if (definedUrl.isEmpty) {
        throw const FormatException(
          'Build de produção exige ATLAS_API_BASE_URL explícita.',
        );
      }
      validateProductionApiBaseUrl(definedUrl);
    }

    if (selected.environment == AtlasEnvironment.staging &&
        definedUrl.isEmpty) {
      throw const FormatException(
        'Build de staging exige ATLAS_API_BASE_URL explícita.',
      );
    }

    if (definedUrl.isEmpty) return selected;

    return AtlasEnvironmentConfig(
      environment: selected.environment,
      apiBaseUrl: definedUrl,
      connectTimeout: selected.connectTimeout,
      receiveTimeout: selected.receiveTimeout,
      enableNetworkLogs: selected.enableNetworkLogs,
    );
  }

  static String normalizeApiBaseUrl(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.isEmpty) return '';

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const FormatException(
        'A URL da API deve começar com http:// ou https://.',
      );
    }

    if (uri.path.isEmpty || uri.path == '/') {
      return '$trimmed/api/v1';
    }
    return trimmed;
  }

  static void validateProductionApiBaseUrl(String value) {
    final normalized = normalizeApiBaseUrl(value);
    final uri = Uri.parse(normalized);
    final host = uri.host.toLowerCase();

    if (uri.scheme != 'https') {
      throw const FormatException('Produção exige API HTTPS.');
    }

    if (host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1' ||
        host.endsWith('.local')) {
      throw const FormatException('Produção não pode usar endereço local.');
    }

    if (host == 'example.com' ||
        host.endsWith('.example') ||
        host.endsWith('.example.com')) {
      throw const FormatException(
        'Produção não pode usar domínio placeholder.',
      );
    }
  }

  static bool get isProduction =>
      current.environment == AtlasEnvironment.production;

  static void select(AtlasEnvironment environment) {
    if (isProduction) {
      throw StateError(
        'O ambiente não pode ser alterado em runtime em build de produção.',
      );
    }

    current = switch (environment) {
      AtlasEnvironment.development => development,
      AtlasEnvironment.staging => staging,
      AtlasEnvironment.production => throw StateError(
        'Produção só pode ser selecionada por --dart-define.',
      ),
    };
  }
}
