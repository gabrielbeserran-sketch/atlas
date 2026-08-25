import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('10D expõe readiness do Release Candidate sem segredos', () {
    final health = File('backend/app/routers/health.py').readAsStringSync();
    expect(health, contains('/health/v1-release-candidate'));
    expect(health, contains('"contract_version": "10D"'));
    expect(health, contains('"release_candidate": release_candidate'));
    expect(health, isNot(contains('atlas_supabase_service_role_key')));
  });

  test('10D mantém controles de segurança e continuidade', () {
    final middleware = File(
      'backend/app/services/security_middleware.py',
    ).readAsStringSync();
    final media = File(
      'backend/app/services/animal_media_storage.py',
    ).readAsStringSync();
    final backup = File('backend/app/services/backup.py').readAsStringSync();

    expect(middleware, contains('DistributedRateLimiter'));
    expect(middleware, contains('Redis.from_url'));
    expect(media, contains('atlas_attachment_backend == "supabase"'));
    expect(backup, contains('def verify_restore'));
    expect(backup, contains('_verify_postgres_restore'));
  });
}
