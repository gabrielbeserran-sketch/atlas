import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backend seleciona onboarding por empresa e fazenda', () {
    final router = File('backend/app/routers/saas_growth.py').readAsStringSync();
    expect(router.contains('OnboardingProgress.farm_id == farm_id'), isTrue);
    expect(router.contains('_onboarding_row('), isTrue);
    expect(router.contains("'farm_scoped_manual_progress': True"), isTrue);
  });

  test('migration 0046 cria isolamento company + farm', () {
    final migration = File(
      'backend/alembic/versions/'
      '20260824_0046_onboarding_progress_farm_scope.py',
    ).readAsStringSync();
    expect(migration.contains('revision = "20260824_0046"'), isTrue);
    expect(migration.contains('down_revision = "20260824_0045"'), isTrue);
    expect(migration.contains('uq_onboarding_progress_company_farm'), isTrue);
    expect(migration.contains('farm_id'), isTrue);
  });

  test('serviço continua enviando farm_id em leitura e gravação', () {
    final service = File(
      'lib/features/consultancy_client/data/services/'
      'atlas_client_onboarding_service.dart',
    ).readAsStringSync();
    final occurrences = RegExp(
      r"queryParameters:\s*\{'farm_id': farmId\}",
    ).allMatches(service).length;
    expect(occurrences, greaterThanOrEqualTo(2));
  });

  test('readiness de produção exige migration 0046', () {
    final router = File('backend/app/routers/saas_growth.py').readAsStringSync();
    expect(router.contains("'migration': '0046'"), isTrue);
    expect(router.contains('OnboardingProgress.farm_id.is_not(None)'), isTrue);
  });
}
