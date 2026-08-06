class AtlasEnterpriseRecord {
  const AtlasEnterpriseRecord({
    required this.id,
    required this.packageId,
    required this.stepId,
    required this.title,
    required this.date,
    required this.quantity,
    required this.unitValue,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int packageId;
  final int stepId;
  final String title;
  final String date;
  final double quantity;
  final double unitValue;
  final String status;
  final String notes;
  final String createdAt;
  final String updatedAt;

  double get totalValue => quantity * unitValue;
  bool get isCompleted => status == 'Concluído';
  bool get isAlert => status == 'Atenção' || status == 'Crítico';

  AtlasEnterpriseRecord copyWith({
    String? id,
    int? packageId,
    int? stepId,
    String? title,
    String? date,
    double? quantity,
    double? unitValue,
    String? status,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return AtlasEnterpriseRecord(
      id: id ?? this.id,
      packageId: packageId ?? this.packageId,
      stepId: stepId ?? this.stepId,
      title: title ?? this.title,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      unitValue: unitValue ?? this.unitValue,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'packageId': packageId,
        'stepId': stepId,
        'title': title,
        'date': date,
        'quantity': quantity,
        'unitValue': unitValue,
        'status': status,
        'notes': notes,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory AtlasEnterpriseRecord.fromMap(Map<String, dynamic> map) {
    return AtlasEnterpriseRecord(
      id: map['id']?.toString() ?? '',
      packageId: int.tryParse(map['packageId']?.toString() ?? '') ?? 31,
      stepId: int.tryParse(map['stepId']?.toString() ?? '') ?? 1,
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      quantity: double.tryParse(map['quantity']?.toString() ?? '') ?? 0,
      unitValue: double.tryParse(map['unitValue']?.toString() ?? '') ?? 0,
      status: map['status']?.toString() ?? 'Planejado',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

class AtlasEnterpriseCapability {
  const AtlasEnterpriseCapability({
    required this.id,
    required this.title,
    required this.description,
  });

  final int id;
  final String title;
  final String description;
}

class AtlasEnterprisePackage {
  const AtlasEnterprisePackage({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.capabilities,
  });

  final int id;
  final String title;
  final String subtitle;
  final List<AtlasEnterpriseCapability> capabilities;
}
