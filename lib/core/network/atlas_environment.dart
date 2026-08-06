enum AtlasEnvironment {
  development,
  staging,
  production,
}

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

  static AtlasEnvironmentConfig current = development;

  static const development = AtlasEnvironmentConfig(
    environment: AtlasEnvironment.development,
    apiBaseUrl: 'http://127.0.0.1:8000/api/v1',
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 25),
    enableNetworkLogs: true,
  );

  static const staging = AtlasEnvironmentConfig(
    environment: AtlasEnvironment.staging,
    apiBaseUrl: 'https://homologacao-api.atlas.example/api/v1',
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 30),
    enableNetworkLogs: true,
  );

  static const production = AtlasEnvironmentConfig(
    environment: AtlasEnvironment.production,
    apiBaseUrl: 'https://api.atlas.example/api/v1',
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 30),
    enableNetworkLogs: false,
  );

  static void select(AtlasEnvironment environment) {
    current = switch (environment) {
      AtlasEnvironment.development => development,
      AtlasEnvironment.staging => staging,
      AtlasEnvironment.production => production,
    };
  }
}
