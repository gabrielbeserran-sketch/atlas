class AtlasMeetingDecisionActionLink {
  const AtlasMeetingDecisionActionLink({
    required this.meetingId,
    required this.decisionId,
    required this.actionId,
    required this.createdAt,
  });

  final String meetingId;
  final String decisionId;
  final String actionId;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'meetingId': meetingId,
      'decisionId': decisionId,
      'actionId': actionId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AtlasMeetingDecisionActionLink.fromMap(Map<String, dynamic> map) {
    return AtlasMeetingDecisionActionLink(
      meetingId: map['meetingId']?.toString() ?? '',
      decisionId: map['decisionId']?.toString() ?? '',
      actionId: map['actionId']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
