enum AtlasSaasPlatformModule {
  accessControl,
  multiCompany,
  multiFarm,
  subscriptions,
  billing,
  pixPayments,
  cardPayments,
  licensing,
  consultantMarketplace,
  producerPortal,
}

extension AtlasSaasPlatformModuleX on AtlasSaasPlatformModule {
  String get code => switch (this) {
    AtlasSaasPlatformModule.accessControl => 'access_control',
    AtlasSaasPlatformModule.multiCompany => 'multi_company',
    AtlasSaasPlatformModule.multiFarm => 'multi_farm',
    AtlasSaasPlatformModule.subscriptions => 'subscriptions',
    AtlasSaasPlatformModule.billing => 'billing',
    AtlasSaasPlatformModule.pixPayments => 'pix_payments',
    AtlasSaasPlatformModule.cardPayments => 'card_payments',
    AtlasSaasPlatformModule.licensing => 'licensing',
    AtlasSaasPlatformModule.consultantMarketplace => 'consultant_marketplace',
    AtlasSaasPlatformModule.producerPortal => 'producer_portal',
  };

  String get title => switch (this) {
    AtlasSaasPlatformModule.accessControl => 'Usuários e Perfis Enterprise',
    AtlasSaasPlatformModule.multiCompany => 'Multiempresa',
    AtlasSaasPlatformModule.multiFarm => 'Multifazenda',
    AtlasSaasPlatformModule.subscriptions => 'Planos e Assinaturas',
    AtlasSaasPlatformModule.billing => 'Cobrança e Billing',
    AtlasSaasPlatformModule.pixPayments => 'Integração Pix',
    AtlasSaasPlatformModule.cardPayments => 'Integração com Cartões',
    AtlasSaasPlatformModule.licensing => 'Gestão de Licenças',
    AtlasSaasPlatformModule.consultantMarketplace =>
      'Marketplace de Consultores',
    AtlasSaasPlatformModule.producerPortal => 'Portal do Produtor',
  };

  String get packageLabel => switch (this) {
    AtlasSaasPlatformModule.accessControl => 'Pacote 101',
    AtlasSaasPlatformModule.multiCompany => 'Pacote 102',
    AtlasSaasPlatformModule.multiFarm => 'Pacote 103',
    AtlasSaasPlatformModule.subscriptions => 'Pacote 104',
    AtlasSaasPlatformModule.billing => 'Pacote 105',
    AtlasSaasPlatformModule.pixPayments => 'Pacote 106',
    AtlasSaasPlatformModule.cardPayments => 'Pacote 107',
    AtlasSaasPlatformModule.licensing => 'Pacote 108',
    AtlasSaasPlatformModule.consultantMarketplace => 'Pacote 109',
    AtlasSaasPlatformModule.producerPortal => 'Pacote 110',
  };

  List<String> get features => switch (this) {
    AtlasSaasPlatformModule.accessControl => const [
      'Usuários',
      'Perfis e funções',
      'Permissões',
      'Sessões e dispositivos',
      'Auditoria de acesso',
    ],
    AtlasSaasPlatformModule.multiCompany => const [
      'Empresas',
      'Unidades de negócio',
      'Vínculos de usuários',
      'Configurações por empresa',
      'Consolidação empresarial',
    ],
    AtlasSaasPlatformModule.multiFarm => const [
      'Fazendas por empresa',
      'Acesso por propriedade',
      'Configuração operacional',
      'Consolidação de fazendas',
      'Comparativos',
    ],
    AtlasSaasPlatformModule.subscriptions => const [
      'Catálogo de planos',
      'Assinaturas',
      'Períodos e renovação',
      'Upgrade e downgrade',
      'Cancelamentos',
    ],
    AtlasSaasPlatformModule.billing => const [
      'Faturas',
      'Cobranças',
      'Recebimentos',
      'Inadimplência',
      'Conciliação',
    ],
    AtlasSaasPlatformModule.pixPayments => const [
      'Chaves Pix',
      'Cobranças Pix',
      'QR Code',
      'Recebimentos',
      'Devoluções',
    ],
    AtlasSaasPlatformModule.cardPayments => const [
      'Clientes e cartões',
      'Autorizações',
      'Parcelamentos',
      'Estornos',
      'Chargebacks',
    ],
    AtlasSaasPlatformModule.licensing => const [
      'Licenças',
      'Limites de uso',
      'Ativações',
      'Expiração',
      'Bloqueios e exceções',
    ],
    AtlasSaasPlatformModule.consultantMarketplace => const [
      'Consultores',
      'Especialidades',
      'Solicitações',
      'Propostas',
      'Avaliações',
    ],
    AtlasSaasPlatformModule.producerPortal => const [
      'Painel do produtor',
      'Solicitações e suporte',
      'Documentos',
      'Indicadores compartilhados',
      'Comunicação',
    ],
  };
}

class AtlasSaasPlatformRecord {
  const AtlasSaasPlatformRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.owner,
    required this.externalId,
    required this.companyName,
    required this.farmName,
    required this.amount,
    required this.quantity,
    required this.usagePercent,
    required this.progressPercent,
    required this.alertCount,
    required this.dueDate,
    required this.reference,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasSaasPlatformModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String owner;
  final String externalId;
  final String companyName;
  final String farmName;
  final double amount;
  final int quantity;
  final double usagePercent;
  final int progressPercent;
  final int alertCount;
  final String dueDate;
  final String reference;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Bloqueado' ||
      status == 'Falhou' ||
      status == 'Vencido' ||
      status == 'Inadimplente' ||
      status == 'Atenção';

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Aprovado' ||
      status == 'Pago' ||
      status == 'Concluído' ||
      status == 'Publicado';

  bool get isOverdue {
    final parsed = parseAtlasSaasDate(dueDate);
    if (parsed.year == 1900) return false;

    return parsed.isBefore(DateTime.now()) &&
        status != 'Pago' &&
        status != 'Concluído' &&
        status != 'Cancelado';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'owner': owner,
      'externalId': externalId,
      'companyName': companyName,
      'farmName': farmName,
      'amount': amount,
      'quantity': quantity,
      'usagePercent': usagePercent,
      'progressPercent': progressPercent,
      'alertCount': alertCount,
      'dueDate': dueDate,
      'reference': reference,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasSaasPlatformRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasSaasPlatformModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasSaasPlatformModule.accessControl,
    );

    return AtlasSaasPlatformRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      owner: map['owner']?.toString() ?? '',
      externalId: map['externalId']?.toString() ?? '',
      companyName: map['companyName']?.toString() ?? '',
      farmName: map['farmName']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      usagePercent: (map['usagePercent'] as num?)?.toDouble() ?? 0.0,
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

DateTime parseAtlasSaasDate(String value) {
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

String formatAtlasSaasDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
