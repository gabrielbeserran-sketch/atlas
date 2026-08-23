enum AtlasSupplyChainModule { purchases, commercialization, logistics }

extension AtlasSupplyChainModuleX on AtlasSupplyChainModule {
  String get code => switch (this) {
    AtlasSupplyChainModule.purchases => 'purchases',
    AtlasSupplyChainModule.commercialization => 'commercialization',
    AtlasSupplyChainModule.logistics => 'logistics',
  };

  String get title => switch (this) {
    AtlasSupplyChainModule.purchases => 'Compras Enterprise',
    AtlasSupplyChainModule.commercialization => 'Comercialização Enterprise',
    AtlasSupplyChainModule.logistics => 'Logística Enterprise',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasSupplyChainModule.purchases => const [
      'Solicitações de compra',
      'Cotação entre fornecedores',
      'Aprovação de compras',
      'Recebimento de materiais',
      'Histórico de preços',
    ],
    AtlasSupplyChainModule.commercialization => const [
      'Venda de animais',
      'Contratos',
      'Romaneios',
      'Rentabilidade por venda',
      'Inteligência de mercado',
    ],
    AtlasSupplyChainModule.logistics => const [
      'Transporte de animais',
      'GTA',
      'Roteirização',
      'Custos logísticos',
      'Histórico de movimentações',
    ],
  };
}

class AtlasSupplyChainRecord {
  const AtlasSupplyChainRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.quantity,
    required this.unitValue,
    required this.counterparty,
    required this.document,
    required this.origin,
    required this.destination,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasSupplyChainModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final double quantity;
  final double unitValue;
  final String counterparty;
  final String document;
  final String origin;
  final String destination;
  final String notes;
  final String createdAt;
  final String updatedAt;

  double get totalValue => quantity * unitValue;

  bool get isCritical => status == 'Crítico' || status == 'Atenção';

  bool get isCompleted => status == 'Concluído' || status == 'Recebido';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'quantity': quantity,
      'unitValue': unitValue,
      'counterparty': counterparty,
      'document': document,
      'origin': origin,
      'destination': destination,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasSupplyChainRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasSupplyChainModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasSupplyChainModule.purchases,
    );

    return AtlasSupplyChainRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unitValue: (map['unitValue'] as num?)?.toDouble() ?? 0,
      counterparty: map['counterparty']?.toString() ?? '',
      document: map['document']?.toString() ?? '',
      origin: map['origin']?.toString() ?? '',
      destination: map['destination']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasSupplyDate(String value) {
  final iso = DateTime.tryParse(value.trim());
  if (iso != null) return iso;

  final parts = value.trim().split('/');
  if (parts.length != 3) return DateTime(1900);

  return DateTime(
    int.tryParse(parts[2]) ?? 1900,
    int.tryParse(parts[1]) ?? 1,
    int.tryParse(parts[0]) ?? 1,
  );
}

String formatAtlasSupplyDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
