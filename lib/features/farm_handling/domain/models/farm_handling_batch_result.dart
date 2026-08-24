class FarmHandlingBatchResult {
  const FarmHandlingBatchResult({
    required this.handlingId,
    required this.action,
    required this.affectedCount,
    required this.summary,
    required this.repeated,
    this.financeEntryId = '',
  });

  final String handlingId;
  final String action;
  final int affectedCount;
  final String summary;
  final bool repeated;
  final String financeEntryId;

  factory FarmHandlingBatchResult.fromMap(Map<String, dynamic> map) {
    return FarmHandlingBatchResult(
      handlingId: map['handling_id']?.toString() ?? '',
      action: map['action']?.toString() ?? '',
      affectedCount: (map['affected_count'] as num?)?.toInt() ?? 0,
      summary: map['summary']?.toString() ?? '',
      repeated: map['repeated'] == true,
      financeEntryId: map['finance_entry_id']?.toString() ?? '',
    );
  }
}

class FarmHandlingHistoryItem {
  const FarmHandlingHistoryItem({
    required this.id,
    required this.action,
    required this.status,
    required this.affectedCount,
    required this.summary,
    required this.responsible,
    required this.occurredAt,
    required this.financeEntryId,
  });

  final String id;
  final String action;
  final String status;
  final int affectedCount;
  final String summary;
  final String responsible;
  final DateTime? occurredAt;
  final String financeEntryId;

  factory FarmHandlingHistoryItem.fromMap(Map<String, dynamic> map) {
    return FarmHandlingHistoryItem(
      id: map['id']?.toString() ?? '',
      action: map['action']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      affectedCount: (map['affected_count'] as num?)?.toInt() ?? 0,
      summary: map['summary']?.toString() ?? '',
      responsible: map['responsible']?.toString() ?? '',
      occurredAt: DateTime.tryParse(
        map['occurred_at']?.toString() ?? '',
      )?.toLocal(),
      financeEntryId: map['finance_entry_id']?.toString() ?? '',
    );
  }
}
