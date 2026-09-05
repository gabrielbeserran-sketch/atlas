class FarmQuoteRequest {
  const FarmQuoteRequest({
    required this.id,
    required this.title,
    required this.itemsDescription,
    required this.suppliers,
    required this.createdAt,
    this.status = 'Em preparação',
    this.proposals = const [],
  });

  final String id;
  final String title;
  final String itemsDescription;
  final List<String> suppliers;
  final String createdAt;
  final String status;
  final List<FarmSupplierProposal> proposals;

  String get displayStatus {
    if (proposals.length >= 2) return 'Em comparação';
    if (proposals.length == 1) return 'Proposta recebida';
    return status;
  }

  FarmQuoteRequest copyWith({
    String? title,
    String? itemsDescription,
    List<String>? suppliers,
    String? status,
    List<FarmSupplierProposal>? proposals,
  }) => FarmQuoteRequest(
    id: id,
    title: title ?? this.title,
    itemsDescription: itemsDescription ?? this.itemsDescription,
    suppliers: suppliers ?? this.suppliers,
    createdAt: createdAt,
    status: status ?? this.status,
    proposals: proposals ?? this.proposals,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'itemsDescription': itemsDescription,
    'suppliers': suppliers,
    'createdAt': createdAt,
    'status': status,
    'proposals': proposals.map((proposal) => proposal.toMap()).toList(),
  };

  factory FarmQuoteRequest.fromMap(Map<String, dynamic> map) =>
      FarmQuoteRequest(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? 'Solicitação de cotação',
        itemsDescription: map['itemsDescription']?.toString() ?? '',
        suppliers: (map['suppliers'] as List? ?? const [])
            .map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .take(4)
            .toList(growable: false),
        createdAt: map['createdAt']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Em preparação',
        proposals: (map['proposals'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (item) =>
                  FarmSupplierProposal.fromMap(Map<String, dynamic>.from(item)),
            )
            .take(4)
            .toList(growable: false),
      );
}

class FarmSupplierProposal {
  const FarmSupplierProposal({
    required this.supplierName,
    required this.totalAmount,
    required this.receivedAt,
    this.notes = '',
  });

  final String supplierName;
  final double totalAmount;
  final String receivedAt;
  final String notes;

  Map<String, dynamic> toMap() => {
    'supplierName': supplierName,
    'totalAmount': totalAmount,
    'receivedAt': receivedAt,
    'notes': notes,
  };

  factory FarmSupplierProposal.fromMap(Map<String, dynamic> map) =>
      FarmSupplierProposal(
        supplierName: map['supplierName']?.toString() ?? 'Fornecedor',
        totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
        receivedAt: map['receivedAt']?.toString() ?? '',
        notes: map['notes']?.toString() ?? '',
      );
}
