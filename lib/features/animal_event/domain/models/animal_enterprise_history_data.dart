class AnimalEnterpriseHistoryData {
  const AnimalEnterpriseHistoryData({
    required this.version,
    required this.payload,
    required this.deleted,
    required this.changedAt,
  });

  final int version;
  final Map<String, dynamic> payload;
  final bool deleted;
  final DateTime changedAt;

  factory AnimalEnterpriseHistoryData.fromMap(Map<String, dynamic> map) {
    return AnimalEnterpriseHistoryData(
      version: (map['version'] as num?)?.toInt() ?? 0,
      payload: Map<String, dynamic>.from(
        map['payload'] as Map? ?? const <String, dynamic>{},
      ),
      deleted: map['deleted'] == true,
      changedAt:
          DateTime.tryParse(map['changed_at']?.toString() ?? '') ??
          DateTime(1900),
    );
  }
}
