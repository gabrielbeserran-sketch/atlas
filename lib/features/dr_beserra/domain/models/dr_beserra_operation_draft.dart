enum DrBeserraOperationKind {
  health,
  reproduction,
  handlingLotMovement,
}

class DrBeserraOperationDraft {
  const DrBeserraOperationDraft({
    required this.kind,
    required this.summary,
    this.animalTag = '',
    this.eventType = '',
    this.product = '',
    this.dose = '',
    this.responsible = '',
    this.result = '',
    this.protocol = '',
    this.sireReference = '',
    this.earringStart = '',
    this.earringEnd = '',
    this.destinationLotName = '',
  });

  final DrBeserraOperationKind kind;
  final String summary;
  final String animalTag;
  final String eventType;
  final String product;
  final String dose;
  final String responsible;
  final String result;
  final String protocol;
  final String sireReference;
  final String earringStart;
  final String earringEnd;
  final String destinationLotName;

  List<String> get missingFields {
    switch (kind) {
      case DrBeserraOperationKind.health:
        return <String>[
          if (animalTag.trim().isEmpty) 'brinco',
          if (eventType.trim().isEmpty) 'tipo do manejo sanitário',
          if (product.trim().isEmpty) 'produto',
          if (dose.trim().isEmpty) 'dose',
          if (responsible.trim().isEmpty) 'responsável',
        ];
      case DrBeserraOperationKind.reproduction:
        return <String>[
          if (animalTag.trim().isEmpty) 'brinco',
          if (eventType.trim().isEmpty) 'tipo do evento reprodutivo',
          if (eventType == 'Diagnóstico de gestação' && result.trim().isEmpty)
            'resultado do diagnóstico',
          if (responsible.trim().isEmpty) 'responsável',
        ];
      case DrBeserraOperationKind.handlingLotMovement:
        return <String>[
          if (earringStart.trim().isEmpty) 'primeiro brinco',
          if (earringEnd.trim().isEmpty) 'último brinco',
          if (destinationLotName.trim().isEmpty) 'lote de destino',
          if (responsible.trim().isEmpty) 'responsável',
        ];
    }
  }

  bool get isComplete => missingFields.isEmpty;
}
