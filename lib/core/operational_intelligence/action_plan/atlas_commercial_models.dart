enum AtlasCommercialPartnerType {
  buyer,
  supplier,
  both,
}

String atlasCommercialPartnerTypeLabel(
  AtlasCommercialPartnerType value,
) {
  switch (value) {
    case AtlasCommercialPartnerType.buyer:
      return 'Comprador';
    case AtlasCommercialPartnerType.supplier:
      return 'Fornecedor';
    case AtlasCommercialPartnerType.both:
      return 'Comprador e fornecedor';
  }
}

enum AtlasCommercialDealType {
  sale,
  purchase,
}

String atlasCommercialDealTypeLabel(AtlasCommercialDealType value) {
  return value == AtlasCommercialDealType.sale
      ? 'Venda'
      : 'Compra';
}

enum AtlasCommercialDealStatus {
  prospecting,
  negotiating,
  contracted,
  completed,
  cancelled,
}

String atlasCommercialDealStatusLabel(
  AtlasCommercialDealStatus value,
) {
  switch (value) {
    case AtlasCommercialDealStatus.prospecting:
      return 'Prospecção';
    case AtlasCommercialDealStatus.negotiating:
      return 'Negociação';
    case AtlasCommercialDealStatus.contracted:
      return 'Contratado';
    case AtlasCommercialDealStatus.completed:
      return 'Concluído';
    case AtlasCommercialDealStatus.cancelled:
      return 'Cancelado';
  }
}

class AtlasCommercialPartner {
  const AtlasCommercialPartner({
    required this.id,
    required this.name,
    required this.type,
    required this.document,
    required this.phone,
    required this.email,
    required this.city,
    required this.state,
    required this.rating,
    required this.farmName,
    required this.notes,
  });

  final String id;
  final String name;
  final AtlasCommercialPartnerType type;
  final String document;
  final String phone;
  final String email;
  final String city;
  final String state;
  final double rating;
  final String? farmName;
  final String notes;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'type': type.name,
        'document': document,
        'phone': phone,
        'email': email,
        'city': city,
        'state': state,
        'rating': rating,
        'farmName': farmName,
        'notes': notes,
      };

  factory AtlasCommercialPartner.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasCommercialPartner(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: AtlasCommercialPartnerType.values.firstWhere(
        (item) => item.name == map['type']?.toString(),
        orElse: () => AtlasCommercialPartnerType.buyer,
      ),
      document: map['document']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      farmName: map['farmName']?.toString(),
      notes: map['notes']?.toString() ?? '',
    );
  }
}

class AtlasCommercialDeal {
  const AtlasCommercialDeal({
    required this.id,
    required this.partnerId,
    required this.type,
    required this.status,
    required this.product,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.costPerUnit,
    required this.negotiatedAt,
    required this.deliveryAt,
    required this.contractReference,
    required this.paymentTerms,
    required this.farmName,
    required this.notes,
  });

  final String id;
  final String partnerId;
  final AtlasCommercialDealType type;
  final AtlasCommercialDealStatus status;
  final String product;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double costPerUnit;
  final DateTime negotiatedAt;
  final DateTime? deliveryAt;
  final String contractReference;
  final String paymentTerms;
  final String? farmName;
  final String notes;

  double get grossValue => quantity * unitPrice;
  double get totalCost => quantity * costPerUnit;
  double get marginValue => type == AtlasCommercialDealType.sale
      ? grossValue - totalCost
      : 0;
  double get marginPercent => grossValue <= 0
      ? 0
      : marginValue / grossValue * 100;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'partnerId': partnerId,
        'type': type.name,
        'status': status.name,
        'product': product,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
        'costPerUnit': costPerUnit,
        'negotiatedAt': negotiatedAt.toIso8601String(),
        'deliveryAt': deliveryAt?.toIso8601String(),
        'contractReference': contractReference,
        'paymentTerms': paymentTerms,
        'farmName': farmName,
        'notes': notes,
      };

  factory AtlasCommercialDeal.fromMap(
    Map<String, dynamic> map,
  ) {
    double value(String key) =>
        (map[key] as num?)?.toDouble() ?? 0;

    return AtlasCommercialDeal(
      id: map['id']?.toString() ?? '',
      partnerId: map['partnerId']?.toString() ?? '',
      type: AtlasCommercialDealType.values.firstWhere(
        (item) => item.name == map['type']?.toString(),
        orElse: () => AtlasCommercialDealType.sale,
      ),
      status: AtlasCommercialDealStatus.values.firstWhere(
        (item) => item.name == map['status']?.toString(),
        orElse: () => AtlasCommercialDealStatus.prospecting,
      ),
      product: map['product']?.toString() ?? '',
      quantity: value('quantity'),
      unit: map['unit']?.toString() ?? '',
      unitPrice: value('unitPrice'),
      costPerUnit: value('costPerUnit'),
      negotiatedAt: DateTime.tryParse(
            map['negotiatedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      deliveryAt: DateTime.tryParse(
        map['deliveryAt']?.toString() ?? '',
      ),
      contractReference:
          map['contractReference']?.toString() ?? '',
      paymentTerms: map['paymentTerms']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      notes: map['notes']?.toString() ?? '',
    );
  }
}

class AtlasCommercialPriceScenario {
  const AtlasCommercialPriceScenario({
    required this.currentPrice,
    required this.projectedPrice,
    required this.quantity,
    required this.costPerUnit,
  });

  final double currentPrice;
  final double projectedPrice;
  final double quantity;
  final double costPerUnit;

  double get currentRevenue => currentPrice * quantity;
  double get projectedRevenue => projectedPrice * quantity;
  double get projectedMargin =>
      projectedRevenue - costPerUnit * quantity;
  double get opportunityValue =>
      projectedRevenue - currentRevenue;
}

class AtlasCommercialExecutiveSnapshot {
  const AtlasCommercialExecutiveSnapshot({
    required this.totalPartners,
    required this.openNegotiations,
    required this.completedSales,
    required this.completedPurchases,
    required this.salesRevenue,
    required this.purchaseValue,
    required this.commercialMargin,
    required this.averageMarginPercent,
    required this.commercialScore,
  });

  final int totalPartners;
  final int openNegotiations;
  final int completedSales;
  final int completedPurchases;
  final double salesRevenue;
  final double purchaseValue;
  final double commercialMargin;
  final double averageMarginPercent;
  final double commercialScore;
}
