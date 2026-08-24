import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/consultancy_client/domain/models/atlas_client_onboarding_progress.dart';

void main() {
  test('somente treinamento permanece manual', () {
    final automatic = AtlasClientOnboardingProgress.canonicalSteps
        .where((step) => step.automatic)
        .map((step) => step.id)
        .toSet();
    expect(automatic, {
      'farm_context',
      'herd_baseline',
      'technical_contact',
      'agenda_routine',
    });
    expect(
      AtlasClientOnboardingProgress.canonicalSteps
          .singleWhere((step) => step.id == 'initial_training')
          .automatic,
      isFalse,
    );
  });

  test('modelo preserva evidências remotas', () {
    final progress = AtlasClientOnboardingProgress.fromMap({
      'farm_id': 'farm-1',
      'steps': {'farm_context': true},
      'evidence': {
        'farm_context': {
          'automatic': true,
          'verified': true,
          'detail': 'Fazenda conferida',
        },
      },
      'completion_percent': 20,
    });
    expect(progress.farmId, 'farm-1');
    expect(progress.evidenceFor('farm_context')?.automatic, isTrue);
    expect(progress.evidenceFor('farm_context')?.detail, 'Fazenda conferida');
  });

  test('serviço escopa leitura e gravação por fazenda', () {
    final service = File(
      'lib/features/consultancy_client/data/services/'
      'atlas_client_onboarding_service.dart',
    ).readAsStringSync();
    expect(service.contains("queryParameters: {'farm_id': farmId}"), isTrue);
    expect(service.contains('saveManualStep'), isTrue);
  });

  test('backend deriva evidências dos domínios oficiais', () {
    final router = File('backend/app/routers/saas_growth.py').readAsStringSync();
    for (final marker in [
      'LivestockAnimal',
      'HerdLot',
      'ConsultancyContact',
      'OperationalTask',
      'ONBOARDING_AUTOMATIC_STEPS',
      "'manual_step_restricted': True",
    ]) {
      expect(router.contains(marker), isTrue, reason: marker);
    }
  });
}
