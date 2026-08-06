class AtlasIntegrationEvent {
  const AtlasIntegrationEvent({
    required this.id,
    required this.sourceModule,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.processed,
  });

  final String id;
  final String sourceModule;
  final String type;
  final String message;
  final DateTime createdAt;
  final bool processed;

  AtlasIntegrationEvent copyWith({bool? processed}) {
    return AtlasIntegrationEvent(
      id: id,
      sourceModule: sourceModule,
      type: type,
      message: message,
      createdAt: createdAt,
      processed: processed ?? this.processed,
    );
  }
}
