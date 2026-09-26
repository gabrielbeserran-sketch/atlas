import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_grazing_setup_progress.dart';

void main() {
  test('ordem exige base antes de vínculos e pesos', () {
    for (final selection in [true, false]) {
      for (final weights in [true, false]) {
        final progress = AtlasGrazingSetupProgress(
          basisValid: false,
          selectionValid: selection,
          weightsComplete: weights,
        );
        expect(progress.step, AtlasGrazingSetupStep.basis);
        expect(progress.completedSteps, 0);
      }
    }
  });
  test('pesos não substituem identificação da base atual', () {
    const progress = AtlasGrazingSetupProgress(
      basisValid: true,
      selectionValid: false,
      weightsComplete: true,
    );
    expect(progress.step, AtlasGrazingSetupStep.animals);
    expect(progress.completedSteps, 1);
  });
  test('amostra incompleta mantém etapa de conferência', () {
    const progress = AtlasGrazingSetupProgress(
      basisValid: true,
      selectionValid: true,
      weightsComplete: false,
    );
    expect(progress.step, AtlasGrazingSetupStep.weights);
    expect(progress.completedSteps, 2);
  });
  test('completo exige os três pré-requisitos', () {
    const progress = AtlasGrazingSetupProgress(
      basisValid: true,
      selectionValid: true,
      weightsComplete: true,
    );
    expect(progress.step, AtlasGrazingSetupStep.ready);
    expect(progress.completedSteps, 3);
  });
  test('continuação exige gravação e mesma base, cancelamento não prossegue', () {
    final source = File(
      'lib/core/operational_intelligence/action_plan/atlas_pasture_management_screen.dart',
    ).readAsStringSync();
    expect(source, contains('if (result == null) return;'));
    expect(source, contains('await grazingBasisService.save(result'));
    expect(source, contains('grazingBasis?.hasSameData(result) == true'));
    expect(source, contains('continueToAnimals: true'));
    expect(source, contains('_setupCard(currentBasis, canEditGrazingBasis)'));
    expect(source, isNot(contains('ainda não calcula UA/ha')));
  });
}
