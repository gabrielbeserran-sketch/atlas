import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('Marco 6 fixa package e API Android 36', () {
    final gradle = read('android/app/build.gradle.kts');
    expect(gradle, contains('applicationId = "br.com.projetoatlas.app"'));
    expect(gradle, contains('compileSdk = 36'));
    expect(gradle, contains('targetSdk = 36'));
    expect(gradle, contains('minSdk = 24'));
  });

  test('release exige assinatura própria', () {
    final gradle = read('android/app/build.gradle.kts');
    expect(gradle, contains('releaseRequested'));
    expect(
      gradle,
      contains('signingConfig = signingConfigs.getByName("release")'),
    );
  });

  test('produção exige endpoint HTTPS imutável', () {
    final environment = read('lib/core/network/atlas_environment.dart');
    final store = read(
      'lib/features/enterprise_platform/data/services/'
      'atlas_enterprise_remote_auth_store.dart',
    );
    expect(environment, contains('Produção exige API HTTPS.'));
    expect(store, contains('A URL da API é imutável em build de produção.'));
  });

  test('Android evita permissão ampla de mídia', () {
    final manifest = read('android/app/src/main/AndroidManifest.xml');
    expect(
      manifest,
      isNot(contains('android.permission.READ_EXTERNAL_STORAGE')),
    );
    expect(
      manifest,
      isNot(contains('android.permission.WRITE_EXTERNAL_STORAGE')),
    );
    expect(manifest, isNot(contains('android.permission.READ_MEDIA_IMAGES')));
  });

  test('Android usa integração nativa de anexos', () {
    final pubspec = read('pubspec.yaml');
    final activity = read(
      'android/app/src/main/kotlin/br/com/projetoatlas/app/MainActivity.kt',
    );
    expect(pubspec, contains('image_picker: ^1.2.2'));
    expect(pubspec, contains('file_selector: ^1.1.0'));
    expect(pubspec, contains('url_launcher: ^6.3.2'));
    expect(activity, contains('FileProvider'));
    expect(activity, contains('"openFile"'));
  });
}
