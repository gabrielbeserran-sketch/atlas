enum AtlasEnterpriseOperationModule {
  procurement,
  supplierPortal,
  inventoryIntelligence,
  maintenance,
  fieldService,
}

extension AtlasEnterpriseOperationModuleX on AtlasEnterpriseOperationModule {
  String get code => switch (this) {
    AtlasEnterpriseOperationModule.procurement => 'procurement',
    AtlasEnterpriseOperationModule.supplierPortal => 'supplier_portal',
    AtlasEnterpriseOperationModule.inventoryIntelligence =>
      'inventory_intelligence',
    AtlasEnterpriseOperationModule.maintenance => 'maintenance',
    AtlasEnterpriseOperationModule.fieldService => 'field_service',
  };

  String get title => switch (this) {
    AtlasEnterpriseOperationModule.procurement => 'Compras Enterprise',
    AtlasEnterpriseOperationModule.supplierPortal => 'Portal do Fornecedor',
    AtlasEnterpriseOperationModule.inventoryIntelligence =>
      'Estoque Inteligente',
    AtlasEnterpriseOperationModule.maintenance => 'Manutenção de Ativos',
    AtlasEnterpriseOperationModule.fieldService => 'Serviços de Campo',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasEnterpriseOperationModule.procurement => const [
      'Requisições de compra',
      'Cotações e comparativos',
      'Pedidos de compra',
      'Aprovações e alçadas',
      'Recebimento e conferência',
    ],
    AtlasEnterpriseOperationModule.supplierPortal => const [
      'Cadastro de fornecedores',
      'Documentos e homologação',
      'Propostas e negociações',
      'Entregas e desempenho',
      'Pendências e comunicação',
    ],
    AtlasEnterpriseOperationModule.inventoryIntelligence => const [
      'Saldo e disponibilidade',
      'Ponto de reposição',
      'Lotes e validade',
      'Inventário e divergências',
      'Previsão de consumo',
    ],
    AtlasEnterpriseOperationModule.maintenance => const [
      'Cadastro de ativos',
      'Planos preventivos',
      'Ordens de serviço',
      'Peças e custos',
      'Falhas e disponibilidade',
    ],
    AtlasEnterpriseOperationModule.fieldService => const [
      'Chamados de campo',
      'Agenda e deslocamento',
      'Checklist técnico',
      'Evidências e assinatura',
      'Fechamento e satisfação',
    ],
  };
}

class AtlasEnterpriseOperationRecord {
  const AtlasEnterpriseOperationRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.counterparty,
    required this.externalId,
    required this.amount,
    required this.costAmount,
    required this.quantity,
    required this.stockLevel,
    required this.progressPercent,
    required this.alertCount,
    required this.dueDate,
    required this.reference,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasEnterpriseOperationModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String counterparty;
  final String externalId;
  final double amount;
  final double costAmount;
  final int quantity;
  final double stockLevel;
  final int progressPercent;
  final int alertCount;
  final String dueDate;
  final String reference;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Rejeitado' ||
      status == 'Vencido' ||
      status == 'Cancelado' ||
      status == 'Atenção' ||
      status == 'Falhou' ||
      status == 'Indisponível';

  bool get isOperational =>
      status == 'Aprovado' ||
      status == 'Recebido' ||
      status == 'Homologado' ||
      status == 'Disponível' ||
      status == 'Concluído';

  bool get isOverdue {
    final parsed = parseAtlasEnterpriseOperationDate(dueDate);
    if (parsed.year == 1900) return false;

    return parsed.isBefore(DateTime.now()) &&
        status != 'Concluído' &&
        status != 'Cancelado';
  }

  double get netAmount => amount - costAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'counterparty': counterparty,
      'externalId': externalId,
      'amount': amount,
      'costAmount': costAmount,
      'quantity': quantity,
      'stockLevel': stockLevel,
      'progressPercent': progressPercent,
      'alertCount': alertCount,
      'dueDate': dueDate,
      'reference': reference,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasEnterpriseOperationRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasEnterpriseOperationModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasEnterpriseOperationModule.procurement,
    );

    return AtlasEnterpriseOperationRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      counterparty: map['counterparty']?.toString() ?? '',
      externalId: map['externalId']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      costAmount: (map['costAmount'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      stockLevel: (map['stockLevel'] as num?)?.toDouble() ?? 0.0,
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      dueDate: map['dueDate']?.toString() ?? '',
      reference: map['reference']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasEnterpriseOperationDate(String value) {
  final text = value.trim();
  if (text.isEmpty) return DateTime(1900);

  final iso = DateTime.tryParse(text);
  if (iso != null) return iso;

  final parts = text.split('/');
  if (parts.length != 3) return DateTime(1900);

  return DateTime(
    int.tryParse(parts[2]) ?? 1900,
    int.tryParse(parts[1]) ?? 1,
    int.tryParse(parts[0]) ?? 1,
  );
}

String formatAtlasEnterpriseOperationDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
