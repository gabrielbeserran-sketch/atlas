import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/features/consultancy_client/domain/models/atlas_client_onboarding_progress.dart';

void main() {
  test('onboarding preserva cálculo de progresso do contrato 9C', () {
    final progress = AtlasClientOnboardingProgress.fromMap({
      'steps': {
        'farm_context': true,
        'herd_baseline': true,
      },
    });

    expect(progress.completionPercent, 40);
    expect(progress.complete, isFalse);
  });

  test('serviço mantém leitura e gravação remotas oficiais', () {
    final service = File(
      'lib/features/consultancy_client/data/services/'
      'atlas_client_onboarding_service.dart',
    ).readAsStringSync();

    final compactService = service.replaceAll(RegExp(r'\s+'), ' ');
    expect(
      RegExp(r"request\s*\(\s*'GET'\s*,\s*'/saas-growth/onboarding'")
          .hasMatch(compactService),
      isTrue,
    );
    expect(
      RegExp(r"request\s*\(\s*'POST'\s*,\s*'/saas-growth/onboarding'")
          .hasMatch(compactService),
      isTrue,
    );
    expect(service.contains('saveManualStep'), isTrue);
  });

  test('central de consultoria mantém implantação integrada', () {
    final screen = File(
      'lib/features/consultancy_client/presentation/screens/'
      'atlas_client_consultancy_center_screen.dart',
    ).readAsStringSync();

    expect(screen.contains('AtlasClientOnboardingCard('), isTrue);
    expect(screen.contains('updateOnboardingStep'), isTrue);
    expect(screen.contains('onboardingService.saveManualStep'), isTrue);
  });

  test('gate 9B continua tolerante ao estado pós-commit', () {
    final script = File(
      'scripts/quality/check_post_v21_package9b_staged_release.ps1',
    ).readAsStringSync();

    expect(script.contains('RELEASE STATE: JA COMMITADO'), isTrue);
    expect(script.contains('git cat-file -e'), isTrue);
    expect(script.contains('working tree'), isTrue);
  });
}
