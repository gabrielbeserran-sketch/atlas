class AtlasCommandCenterActionUpdate {
  const AtlasCommandCenterActionUpdate({
    required this.id,
    required this.actionId,
    required this.createdAt,
    required this.progressPercent,
    required this.responsibleName,
    required this.note,
  });

  final String id;
  final String actionId;
  final DateTime createdAt;
  final int progressPercent;
  final String responsibleName;
  final String note;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'actionId': actionId,
      'createdAt': createdAt.toIso8601String(),
      'progressPercent': progressPercent,
      'responsibleName': responsibleName,
      'note': note,
    };
  }

  factory AtlasCommandCenterActionUpdate.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasCommandCenterActionUpdate(
      id: map['id']?.toString() ?? '',
      actionId: map['actionId']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      progressPercent: _readInt(
        map['progressPercent'],
      ).clamp(0, 100),
      responsibleName:
          map['responsibleName']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
    );
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
