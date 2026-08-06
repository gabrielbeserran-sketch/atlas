class AnimalData {
  const AnimalData({
    required this.id,
    this.lotId = '',
    required this.tag,
    required this.name,
    required this.sex,
    required this.breed,
    required this.birthDate,
    required this.weight,
    required this.status,
    this.sisbov = '',
    this.category = 'Não informada',
    this.bodyConditionScore = 0,
    this.motherTag = '',
    this.fatherTag = '',
    this.origin = '',
    this.photoReference = '',
    this.notes = '',
    this.acquisitionType = 'Nascido na fazenda',
    this.acquisitionDate = '',
    this.acquisitionValue = 0,
    this.acquisitionCounterparty = '',
    this.acquisitionDocument = '',
    this.saleDate = '',
    this.saleValue = 0,
    this.saleCounterparty = '',
    this.saleDocument = '',
    this.version = 0,
    this.updatedAt = '',
  });

  final String id;
  final String lotId;
  final String tag;
  final String name;
  final String sex;
  final String breed;
  final String birthDate;
  final double weight;
  final String status;
  final String sisbov;
  final String category;
  final double bodyConditionScore;
  final String motherTag;
  final String fatherTag;
  final String origin;
  final String photoReference;
  final String notes;
  final String acquisitionType;
  final String acquisitionDate;
  final double acquisitionValue;
  final String acquisitionCounterparty;
  final String acquisitionDocument;
  final String saleDate;
  final double saleValue;
  final String saleCounterparty;
  final String saleDocument;
  final int version;
  final String updatedAt;

  String get displayName => name.trim().isNotEmpty ? name : 'Animal $tag';

  bool get hasGenealogy =>
      motherTag.trim().isNotEmpty || fatherTag.trim().isNotEmpty;

  bool get wasPurchased =>
      acquisitionType == 'Compra' && acquisitionValue > 0;

  bool get wasSold => status == 'Vendido' && saleValue > 0;

  AnimalData copyWith({
    String? id,
    String? lotId,
    String? tag,
    String? name,
    String? sex,
    String? breed,
    String? birthDate,
    double? weight,
    String? status,
    String? sisbov,
    String? category,
    double? bodyConditionScore,
    String? motherTag,
    String? fatherTag,
    String? origin,
    String? photoReference,
    String? notes,
    String? acquisitionType,
    String? acquisitionDate,
    double? acquisitionValue,
    String? acquisitionCounterparty,
    String? acquisitionDocument,
    String? saleDate,
    double? saleValue,
    String? saleCounterparty,
    String? saleDocument,
    int? version,
    String? updatedAt,
  }) {
    return AnimalData(
      id: id ?? this.id,
      lotId: lotId ?? this.lotId,
      tag: tag ?? this.tag,
      name: name ?? this.name,
      sex: sex ?? this.sex,
      breed: breed ?? this.breed,
      birthDate: birthDate ?? this.birthDate,
      weight: weight ?? this.weight,
      status: status ?? this.status,
      sisbov: sisbov ?? this.sisbov,
      category: category ?? this.category,
      bodyConditionScore: bodyConditionScore ?? this.bodyConditionScore,
      motherTag: motherTag ?? this.motherTag,
      fatherTag: fatherTag ?? this.fatherTag,
      origin: origin ?? this.origin,
      photoReference: photoReference ?? this.photoReference,
      notes: notes ?? this.notes,
      acquisitionType: acquisitionType ?? this.acquisitionType,
      acquisitionDate: acquisitionDate ?? this.acquisitionDate,
      acquisitionValue: acquisitionValue ?? this.acquisitionValue,
      acquisitionCounterparty:
          acquisitionCounterparty ?? this.acquisitionCounterparty,
      acquisitionDocument: acquisitionDocument ?? this.acquisitionDocument,
      saleDate: saleDate ?? this.saleDate,
      saleValue: saleValue ?? this.saleValue,
      saleCounterparty: saleCounterparty ?? this.saleCounterparty,
      saleDocument: saleDocument ?? this.saleDocument,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lotId': lotId,
      'tag': tag,
      'name': name,
      'sex': sex,
      'breed': breed,
      'birthDate': birthDate,
      'weight': weight,
      'status': status,
      'sisbov': sisbov,
      'category': category,
      'bodyConditionScore': bodyConditionScore,
      'motherTag': motherTag,
      'fatherTag': fatherTag,
      'origin': origin,
      'photoReference': photoReference,
      'notes': notes,
      'acquisitionType': acquisitionType,
      'acquisitionDate': acquisitionDate,
      'acquisitionValue': acquisitionValue,
      'acquisitionCounterparty': acquisitionCounterparty,
      'acquisitionDocument': acquisitionDocument,
      'saleDate': saleDate,
      'saleValue': saleValue,
      'saleCounterparty': saleCounterparty,
      'saleDocument': saleDocument,
      'version': version,
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toLivestockCreateBody({
    required String farmId,
    required String lotId,
  }) {
    return {
      'farm_id': farmId,
      'lot_id': lotId,
      'tag': tag,
      'sisbov': sisbov,
      'name': name,
      'sex': sex,
      'breed': breed,
      'category': category,
      'birth_date': birthDate,
      'status': status,
      'current_weight': weight,
      'body_condition_score': bodyConditionScore,
      'metadata_json': _metadataJson(),
    };
  }

  Map<String, dynamic> toLivestockUpdateBody({required String lotId}) {
    final body = toLivestockCreateBody(farmId: '', lotId: lotId);
    body.remove('farm_id');
    return body;
  }

  Map<String, dynamic> _metadataJson() {
    return {
      'mother_tag': motherTag,
      'father_tag': fatherTag,
      'origin': origin,
      'photo_reference': photoReference,
      'notes': notes,
      'acquisition_type': acquisitionType,
      'acquisition_date': acquisitionDate,
      'acquisition_value': acquisitionValue,
      'acquisition_counterparty': acquisitionCounterparty,
      'acquisition_document': acquisitionDocument,
      'sale_date': saleDate,
      'sale_value': saleValue,
      'sale_counterparty': saleCounterparty,
      'sale_document': saleDocument,
    };
  }

  factory AnimalData.fromMap(Map<String, dynamic> map) {
    return AnimalData(
      id: map['id']?.toString() ?? '',
      lotId: map['lotId']?.toString() ?? map['lot_id']?.toString() ?? '',
      tag: map['tag']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      sex: map['sex']?.toString() ?? 'Fêmea',
      breed: map['breed']?.toString() ?? 'Não informada',
      birthDate: map['birthDate']?.toString() ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
      status: map['status']?.toString() ?? 'Ativo',
      sisbov: map['sisbov']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Não informada',
      bodyConditionScore:
          (map['bodyConditionScore'] as num?)?.toDouble() ?? 0,
      motherTag: map['motherTag']?.toString() ?? '',
      fatherTag: map['fatherTag']?.toString() ?? '',
      origin: map['origin']?.toString() ?? '',
      photoReference: map['photoReference']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      acquisitionType:
          map['acquisitionType']?.toString() ?? 'Nascido na fazenda',
      acquisitionDate: map['acquisitionDate']?.toString() ?? '',
      acquisitionValue: (map['acquisitionValue'] as num?)?.toDouble() ?? 0,
      acquisitionCounterparty:
          map['acquisitionCounterparty']?.toString() ?? '',
      acquisitionDocument: map['acquisitionDocument']?.toString() ?? '',
      saleDate: map['saleDate']?.toString() ?? '',
      saleValue: (map['saleValue'] as num?)?.toDouble() ?? 0,
      saleCounterparty: map['saleCounterparty']?.toString() ?? '',
      saleDocument: map['saleDocument']?.toString() ?? '',
      version: (map['version'] as num?)?.toInt() ?? 0,
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }

  factory AnimalData.fromLivestockMap(Map<String, dynamic> map) {
    final metadata = Map<String, dynamic>.from(
      map['metadata_json'] is Map ? map['metadata_json'] as Map : const {},
    );

    return AnimalData(
      id: map['id']?.toString() ?? '',
      lotId: map['lot_id']?.toString() ?? '',
      tag: map['tag']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      sex: map['sex']?.toString() ?? 'Fêmea',
      breed: map['breed']?.toString() ?? 'Não informada',
      birthDate: map['birth_date']?.toString() ?? '',
      weight: (map['current_weight'] as num?)?.toDouble() ?? 0,
      status: map['status']?.toString() ?? 'Ativo',
      sisbov: map['sisbov']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Não informada',
      bodyConditionScore:
          (map['body_condition_score'] as num?)?.toDouble() ?? 0,
      motherTag: metadata['mother_tag']?.toString() ?? '',
      fatherTag: metadata['father_tag']?.toString() ?? '',
      origin: metadata['origin']?.toString() ?? '',
      photoReference: metadata['photo_reference']?.toString() ?? '',
      notes: metadata['notes']?.toString() ?? '',
      acquisitionType:
          metadata['acquisition_type']?.toString() ?? 'Nascido na fazenda',
      acquisitionDate: metadata['acquisition_date']?.toString() ?? '',
      acquisitionValue:
          (metadata['acquisition_value'] as num?)?.toDouble() ?? 0,
      acquisitionCounterparty:
          metadata['acquisition_counterparty']?.toString() ?? '',
      acquisitionDocument:
          metadata['acquisition_document']?.toString() ?? '',
      saleDate: metadata['sale_date']?.toString() ?? '',
      saleValue: (metadata['sale_value'] as num?)?.toDouble() ?? 0,
      saleCounterparty:
          metadata['sale_counterparty']?.toString() ?? '',
      saleDocument: metadata['sale_document']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString() ?? '',
    );
  }
}
