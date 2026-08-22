class FarmHandlingBatchResult {
  const FarmHandlingBatchResult({
    required this.handlingId,
    required this.action,
    required this.affectedCount,
    required this.summary,
    this.financeEntryId = '',
  });

  final String handlingId;
  final String action;
  final int affectedCount;
  final String summary;
  final String financeEntryId;

  factory FarmHandlingBatchResult.fromMap(Map<String, dynamic> map) {
    return FarmHandlingBatchResult(
      handlingId: map['handling_id']?.toString() ?? '',
      action: map['action']?.toString() ?? '',
      affectedCount: (map['affected_count'] as num?)?.toInt() ?? 0,
      summary: map['summary']?.toString() ?? '',
      financeEntryId: map['finance_entry_id']?.toString() ?? '',
    );
  }
}
