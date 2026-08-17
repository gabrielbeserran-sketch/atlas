import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/network/atlas_android_endpoint.dart';
import 'package:projeto_atlas/core/network/atlas_environment.dart';

void main() {
  test('monta URL da API para um IPv4 da rede local', () {
    expect(
      AtlasAndroidEndpoint.apiUrlForLanIp('192.168.1.25'),
      'http://192.168.1.25:8000/api/v1',
    );
  });

  test('rejeita IPv4 inválido', () {
    expect(
      () => AtlasAndroidEndpoint.apiUrlForLanIp('192.168.1.999'),
      throwsFormatException,
    );
  });

  test('normaliza uma URL sem /api/v1', () {
    expect(
      AtlasEnvironmentConfig.normalizeApiBaseUrl('http://10.0.0.8:8000'),
      'http://10.0.0.8:8000/api/v1',
    );
  });
}
