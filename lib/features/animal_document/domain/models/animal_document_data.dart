class AnimalDocumentData {
  const AnimalDocumentData({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.date,
    required this.expirationDate,
    required this.reference,
    required this.issuer,
    required this.notes,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final String category;
  final String title;
  final String date;
  final String expirationDate;
  final String reference;
  final String issuer;
  final String notes;
  final bool isFavorite;
  final String createdAt;
  final String updatedAt;

  bool get hasAttachment => reference.trim().isNotEmpty;
  bool get hasExpiration => expirationDate.trim().isNotEmpty;

  DateTime? get expiration {
    return parseDocumentDate(expirationDate);
  }

  bool get isExpired {
    final value = expiration;
    if (value == null) return false;

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    return value.isBefore(normalizedToday);
  }

  int? get daysUntilExpiration {
    final value = expiration;
    if (value == null) return null;

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    return value.difference(normalizedToday).inDays;
  }

  bool get expiresSoon {
    final days = daysUntilExpiration;
    return days != null && days >= 0 && days <= 30;
  }

  String get expirationStatus {
    if (!hasExpiration) return 'Sem vencimento';

    final days = daysUntilExpiration;
    if (days == null) return 'Data inválida';
    if (days < 0) return 'Vencido há ${days.abs()} dias';
    if (days == 0) return 'Vence hoje';
    if (days <= 30) return 'Vence em $days dias';
    return 'Válido';
  }

  AnimalDocumentData copyWith({
    String? id,
    String? type,
    String? category,
    String? title,
    String? date,
    String? expirationDate,
    String? reference,
    String? issuer,
    String? notes,
    bool? isFavorite,
    String? createdAt,
    String? updatedAt,
  }) {
    return AnimalDocumentData(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      date: date ?? this.date,
      expirationDate: expirationDate ?? this.expirationDate,
      reference: reference ?? this.reference,
      issuer: issuer ?? this.issuer,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'category': category,
      'title': title,
      'date': date,
      'expirationDate': expirationDate,
      'reference': reference,
      'issuer': issuer,
      'notes': notes,
      'isFavorite': isFavorite,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AnimalDocumentData.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now().toIso8601String();

    return AnimalDocumentData(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'Outro',
      category:
          map['category']?.toString() ??
          inferDocumentCategory(map['type']?.toString() ?? ''),
      title: map['title']?.toString() ?? 'Documento',
      date: map['date']?.toString() ?? '',
      expirationDate: map['expirationDate']?.toString() ?? '',
      reference: map['reference']?.toString() ?? '',
      issuer: map['issuer']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      isFavorite: map['isFavorite'] == true,
      createdAt: map['createdAt']?.toString() ?? now,
      updatedAt: map['updatedAt']?.toString() ?? now,
    );
  }
}

DateTime? parseDocumentDate(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return null;

  final iso = DateTime.tryParse(normalized);
  if (iso != null) {
    return DateTime(iso.year, iso.month, iso.day);
  }

  final parts = normalized.split('/');
  if (parts.length != 3) return null;

  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);

  if (day == null || month == null || year == null) return null;

  try {
    return DateTime(year, month, day);
  } catch (_) {
    return null;
  }
}

String inferDocumentCategory(String type) {
  switch (type) {
    case 'GTA':
    case 'Documento de transporte':
    case 'Atestado':
    case 'Exame':
    case 'Receituário':
    case 'Laudo':
      return 'Sanitário';
    case 'IATF':
    case 'IA':
    case 'Diagnóstico de gestação':
    case 'Protocolo hormonal':
    case 'Parto':
      return 'Reprodutivo';
    case 'Nota fiscal':
    case 'Compra':
    case 'Venda':
    case 'Contrato':
      return 'Comercial';
    case 'SISBOV':
    case 'Registro genealógico':
    case 'Certificado':
      return 'Oficial';
    default:
      return 'Outro';
  }
}
