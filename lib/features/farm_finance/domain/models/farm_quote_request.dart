class FarmQuoteRequest {
  const FarmQuoteRequest({
    required this.id,
    required this.title,
    required this.itemsDescription,
    required this.suppliers,
    required this.createdAt,
    this.status = 'Em preparação',
  });

  final String id;
  final String title;
  final String itemsDescription;
  final List<String> suppliers;
  final String createdAt;
  final String status;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'itemsDescription': itemsDescription,
    'suppliers': suppliers,
    'createdAt': createdAt,
    'status': status,
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
      );
}
