enum FarmHandlingSelectionMode {
  wholeLot,
  earringRange,
  manualSelection,
  rfid,
}

enum FarmHandlingAction {
  saleOrExit,
  lotMovement,
  weighing,
  health,
  reproduction,
  categoryChange,
}

class FarmHandlingDraft {
  const FarmHandlingDraft({
    required this.farmId,
    required this.action,
    required this.selectionMode,
    this.lotIds = const <String>[],
    this.animalIds = const <String>[],
    this.earringStart = '',
    this.earringEnd = '',
  });

  final String farmId;
  final FarmHandlingAction action;
  final FarmHandlingSelectionMode selectionMode;
  final List<String> lotIds;
  final List<String> animalIds;
  final String earringStart;
  final String earringEnd;

  bool get hasSelection {
    return switch (selectionMode) {
      FarmHandlingSelectionMode.wholeLot => lotIds.isNotEmpty,
      FarmHandlingSelectionMode.earringRange =>
        earringStart.trim().isNotEmpty && earringEnd.trim().isNotEmpty,
      FarmHandlingSelectionMode.manualSelection => animalIds.isNotEmpty,
      FarmHandlingSelectionMode.rfid => animalIds.isNotEmpty,
    };
  }

  bool get isValid => farmId.trim().isNotEmpty && hasSelection;

  FarmHandlingDraft copyWith({
    String? farmId,
    FarmHandlingAction? action,
    FarmHandlingSelectionMode? selectionMode,
    List<String>? lotIds,
    List<String>? animalIds,
    String? earringStart,
    String? earringEnd,
  }) {
    return FarmHandlingDraft(
      farmId: farmId ?? this.farmId,
      action: action ?? this.action,
      selectionMode: selectionMode ?? this.selectionMode,
      lotIds: lotIds ?? this.lotIds,
      animalIds: animalIds ?? this.animalIds,
      earringStart: earringStart ?? this.earringStart,
      earringEnd: earringEnd ?? this.earringEnd,
    );
  }
}
