class AtlasIntegrationModule {
  const AtlasIntegrationModule({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.isEnabled,
    required this.isHealthy,
    required this.pendingEvents,
    required this.lastActivity,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final bool isEnabled;
  final bool isHealthy;
  final int pendingEvents;
  final DateTime? lastActivity;

  AtlasIntegrationModule copyWith({
    bool? isEnabled,
    bool? isHealthy,
    int? pendingEvents,
    DateTime? lastActivity,
  }) {
    return AtlasIntegrationModule(
      id: id,
      name: name,
      category: category,
      description: description,
      isEnabled: isEnabled ?? this.isEnabled,
      isHealthy: isHealthy ?? this.isHealthy,
      pendingEvents: pendingEvents ?? this.pendingEvents,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }
}
