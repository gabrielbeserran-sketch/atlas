import 'package:projeto_atlas/core/operational_intelligence/action_plan/atlas_execution_meeting_decision.dart';

class AtlasExecutionMeeting {
  const AtlasExecutionMeeting({
    required this.id,
    required this.farmName,
    required this.createdAt,
    required this.meetingAt,
    required this.title,
    required this.participants,
    required this.summary,
    required this.agendaItems,
    required this.decisions,
    required this.closed,
  });

  final String id;
  final String? farmName;
  final DateTime createdAt;
  final DateTime meetingAt;
  final String title;
  final List<String> participants;
  final String summary;
  final List<String> agendaItems;
  final List<AtlasExecutionMeetingDecision> decisions;
  final bool closed;

  AtlasExecutionMeeting copyWith({
    DateTime? meetingAt,
    String? title,
    List<String>? participants,
    String? summary,
    List<String>? agendaItems,
    List<AtlasExecutionMeetingDecision>? decisions,
    bool? closed,
  }) {
    return AtlasExecutionMeeting(
      id: id,
      farmName: farmName,
      createdAt: createdAt,
      meetingAt: meetingAt ?? this.meetingAt,
      title: title ?? this.title,
      participants: participants ?? this.participants,
      summary: summary ?? this.summary,
      agendaItems: agendaItems ?? this.agendaItems,
      decisions: decisions ?? this.decisions,
      closed: closed ?? this.closed,
    );
  }

  int get pendingDecisionCount =>
      decisions.where((item) => !item.completed).length;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'farmName': farmName,
      'createdAt': createdAt.toIso8601String(),
      'meetingAt': meetingAt.toIso8601String(),
      'title': title,
      'participants': participants,
      'summary': summary,
      'agendaItems': agendaItems,
      'decisions': decisions.map((item) => item.toMap()).toList(),
      'closed': closed,
    };
  }

  factory AtlasExecutionMeeting.fromMap(Map<String, dynamic> map) {
    final decisionValues = map['decisions'];

    return AtlasExecutionMeeting(
      id: map['id']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      meetingAt:
          DateTime.tryParse(map['meetingAt']?.toString() ?? '') ??
          DateTime.now(),
      title: map['title']?.toString() ?? 'Reunião de execução',
      participants: _readStrings(map['participants']),
      summary: map['summary']?.toString() ?? '',
      agendaItems: _readStrings(map['agendaItems']),
      decisions: decisionValues is List
          ? decisionValues
                .map(
                  (item) => AtlasExecutionMeetingDecision.fromMap(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList(growable: false)
          : <AtlasExecutionMeetingDecision>[],
      closed: map['closed'] == true,
    );
  }

  static List<String> _readStrings(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value.map((item) => item.toString()).toList(growable: false);
  }
}
