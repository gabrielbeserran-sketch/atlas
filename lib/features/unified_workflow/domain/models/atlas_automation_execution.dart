class AtlasAutomationExecution {
  const AtlasAutomationExecution({
    required this.id,
    required this.ruleId,
    required this.ruleTitle,
    required this.eventId,
    required this.eventTitle,
    required this.actionTitle,
    required this.executedAt,
    required this.success,
    required this.message,
  });

  final String id;
  final String ruleId;
  final String ruleTitle;
  final String eventId;
  final String eventTitle;
  final String actionTitle;
  final DateTime executedAt;
  final bool success;
  final String message;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'ruleId': ruleId,
    'ruleTitle': ruleTitle,
    'eventId': eventId,
    'eventTitle': eventTitle,
    'actionTitle': actionTitle,
    'executedAt': executedAt.toIso8601String(),
    'success': success,
    'message': message,
  };

  factory AtlasAutomationExecution.fromJson(Map<String, dynamic> json) {
    return AtlasAutomationExecution(
      id: json['id'] as String,
      ruleId: json['ruleId'] as String,
      ruleTitle: json['ruleTitle'] as String,
      eventId: json['eventId'] as String,
      eventTitle: json['eventTitle'] as String,
      actionTitle: json['actionTitle'] as String,
      executedAt: DateTime.parse(json['executedAt'] as String),
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}
