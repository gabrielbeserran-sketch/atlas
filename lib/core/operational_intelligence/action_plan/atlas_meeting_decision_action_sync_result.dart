class AtlasMeetingDecisionActionSyncResult {
  const AtlasMeetingDecisionActionSyncResult({
    required this.checkedLinks,
    required this.updatedDecisions,
    required this.updatedActions,
    required this.missingActions,
    required this.repairedLinks,
    required this.syncedAt,
  });

  final int checkedLinks;
  final int updatedDecisions;
  final int updatedActions;
  final int missingActions;
  final int repairedLinks;
  final DateTime syncedAt;

  bool get hasChanges => updatedDecisions > 0 || updatedActions > 0;
}
