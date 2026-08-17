import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/network/atlas_environment.dart';

void main() {
  test('selects the development environment', () {
    AtlasEnvironmentConfig.select(AtlasEnvironment.development);

    expect(AtlasEnvironmentConfig.current.apiBaseUrl, contains('127.0.0.1'));
  });
}
