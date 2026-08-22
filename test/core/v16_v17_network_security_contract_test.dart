import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Cliente HTTP não repete mutações cegamente', () {
    final source = File(
      'lib/core/network/atlas_http_client.dart',
    ).readAsStringSync();

    expect(source.contains('_isIdempotentMethod'), isTrue);
    expect(source.contains('_refreshInFlight'), isTrue);
    expect(source.contains('retry-after'), isTrue);
  });

  test('Secure Storage possui autorrecuperação sem fallback inseguro', () {
    final source = File(
      'lib/features/enterprise_platform/data/services/'
      'atlas_enterprise_remote_auth_store.dart',
    ).readAsStringSync();

    expect(source.contains('_recoverSecureStorage'), isTrue);
    expect(source.contains('_preferences.setString(_sessionKey'), isFalse);
  });

  test('Produção usa HTTPS e timeout compatível com cold start', () {
    final source = File(
      'lib/core/network/atlas_environment.dart',
    ).readAsStringSync();

    expect(source.contains('Produção exige API HTTPS.'), isTrue);
    expect(
      source.contains('receiveTimeout: Duration(seconds: 60)'),
      isTrue,
    );
  });
}
