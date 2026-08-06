class AnimalMovementData {
  const AnimalMovementData({
    required this.id,
    required this.type,
    required this.date,
    required this.origin,
    required this.destination,
    required this.reason,
    required this.responsible,
    required this.notes,
    this.fromLotId = '',
    this.toLotId = '',
    this.isRemote = false,
  });

  final String id;
  final String type;
  final String date;
  final String origin;
  final String destination;
  final String reason;
  final String responsible;
  final String notes;
  final String fromLotId;
  final String toLotId;
  final bool isRemote;

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'date': date,
        'origin': origin,
        'destination': destination,
        'reason': reason,
        'responsible': responsible,
        'notes': notes,
        'fromLotId': fromLotId,
        'toLotId': toLotId,
        'isRemote': isRemote,
      };

  Map<String, dynamic> toRemoteBody() => {
        'movement_type': _typeToCode(type),
        'to_lot_id': toLotId.trim().isEmpty ? null : toLotId.trim(),
        'occurred_at': _toIsoDate(date),
        'reason': reason,
        'document_reference': _encodeDetails(),
      };

  String _encodeDetails() {
    final values = <String>[
      'origin=${Uri.encodeComponent(origin)}',
      'destination=${Uri.encodeComponent(destination)}',
      'responsible=${Uri.encodeComponent(responsible)}',
      'notes=${Uri.encodeComponent(notes)}',
    ];
    return 'atlas-movement:${values.join('&')}';
  }

  factory AnimalMovementData.fromMap(Map<String, dynamic> map) {
    return AnimalMovementData(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'Outro',
      date: map['date']?.toString() ?? '',
      origin: map['origin']?.toString() ?? '',
      destination: map['destination']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      responsible: map['responsible']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      fromLotId: map['fromLotId']?.toString() ?? '',
      toLotId: map['toLotId']?.toString() ?? '',
      isRemote: map['isRemote'] == true,
    );
  }

  factory AnimalMovementData.fromRemoteMap(
    Map<String, dynamic> map, {
    required String originName,
    required String destinationName,
  }) {
    final details = _decodeDetails(map['document_reference']?.toString() ?? '');
    return AnimalMovementData(
      id: map['id']?.toString() ?? '',
      type: _codeToType(map['movement_type']?.toString() ?? ''),
      date: _fromIsoDate(map['occurred_at']?.toString() ?? ''),
      origin: details['origin']?.isNotEmpty == true
          ? details['origin']!
          : originName,
      destination: details['destination']?.isNotEmpty == true
          ? details['destination']!
          : destinationName,
      reason: map['reason']?.toString() ?? '',
      responsible: details['responsible'] ?? '',
      notes: details['notes'] ?? '',
      fromLotId: map['from_lot_id']?.toString() ?? '',
      toLotId: map['to_lot_id']?.toString() ?? '',
      isRemote: true,
    );
  }

  static String _typeToCode(String value) {
    switch (value) {
      case 'Mudança de lote':
        return 'lot_change';
      case 'Mudança de piquete':
        return 'paddock_change';
      case 'Entrada na propriedade':
        return 'entry';
      case 'Saída da propriedade':
        return 'exit';
      case 'Transferência':
        return 'transfer';
      case 'Curral':
        return 'corral';
      default:
        return 'other';
    }
  }

  static String _codeToType(String value) {
    switch (value) {
      case 'lot_change':
        return 'Mudança de lote';
      case 'paddock_change':
        return 'Mudança de piquete';
      case 'entry':
        return 'Entrada na propriedade';
      case 'exit':
      case 'sale':
      case 'death':
      case 'discard':
        return 'Saída da propriedade';
      case 'transfer':
        return 'Transferência';
      case 'corral':
        return 'Curral';
      default:
        return 'Outro';
    }
  }

  static String _toIsoDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return DateTime.now().toUtc().toIso8601String();
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return DateTime.now().toUtc().toIso8601String();
    }
    return DateTime(year, month, day, 12).toUtc().toIso8601String();
  }

  static String _fromIsoDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static Map<String, String> _decodeDetails(String value) {
    if (!value.startsWith('atlas-movement:')) return const {};
    final query = value.substring('atlas-movement:'.length);
    final result = <String, String>{};
    for (final pair in query.split('&')) {
      final separator = pair.indexOf('=');
      if (separator <= 0) continue;
      result[pair.substring(0, separator)] = Uri.decodeComponent(
        pair.substring(separator + 1),
      );
    }
    return result;
  }
}
