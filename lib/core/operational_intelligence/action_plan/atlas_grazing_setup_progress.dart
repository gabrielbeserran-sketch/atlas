enum AtlasGrazingSetupStep { basis, animals, weights, ready }

/// Progresso de configuração, não porcentagem de homologação do produto.
class AtlasGrazingSetupProgress {
  const AtlasGrazingSetupProgress({
    required this.basisValid,
    required this.selectionValid,
    required this.weightsComplete,
  });

  final bool basisValid;
  final bool selectionValid;
  final bool weightsComplete;

  AtlasGrazingSetupStep get step => !basisValid
      ? AtlasGrazingSetupStep.basis
      : !selectionValid
      ? AtlasGrazingSetupStep.animals
      : !weightsComplete
      ? AtlasGrazingSetupStep.weights
      : AtlasGrazingSetupStep.ready;

  int get completedSteps => switch (step) {
    AtlasGrazingSetupStep.basis => 0,
    AtlasGrazingSetupStep.animals => 1,
    AtlasGrazingSetupStep.weights => 2,
    AtlasGrazingSetupStep.ready => 3,
  };
}
