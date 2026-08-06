class AtlasExecutionWeeklyReview {
  const AtlasExecutionWeeklyReview({
    required this.id,
    required this.farmName,
    required this.generatedAt,
    required this.periodStart,
    required this.periodEnd,
    required this.totalActions,
    required this.openActions,
    required this.completedInPeriod,
    required this.overdueActions,
    required this.blockedActions,
    required this.actionsWithoutResponsible,
    required this.actionsWithoutRecentFollowUp,
    required this.averageProgressPercent,
    required this.executionHealthPercent,
    required this.expectedFinancialImpact,
    required this.achievements,
    required this.bottlenecks,
    required this.focusActions,
  });

  final String id;
  final String? farmName;
  final DateTime generatedAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalActions;
  final int openActions;
  final int completedInPeriod;
  final int overdueActions;
  final int blockedActions;
  final int actionsWithoutResponsible;
  final int actionsWithoutRecentFollowUp;
  final double averageProgressPercent;
  final double executionHealthPercent;
  final double expectedFinancialImpact;
  final List<String> achievements;
  final List<String> bottlenecks;
  final List<String> focusActions;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'farmName': farmName,
      'generatedAt': generatedAt.toIso8601String(),
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'totalActions': totalActions,
      'openActions': openActions,
      'completedInPeriod': completedInPeriod,
      'overdueActions': overdueActions,
      'blockedActions': blockedActions,
      'actionsWithoutResponsible': actionsWithoutResponsible,
      'actionsWithoutRecentFollowUp':
          actionsWithoutRecentFollowUp,
      'averageProgressPercent': averageProgressPercent,
      'executionHealthPercent': executionHealthPercent,
      'expectedFinancialImpact': expectedFinancialImpact,
      'achievements': achievements,
      'bottlenecks': bottlenecks,
      'focusActions': focusActions,
    };
  }

  factory AtlasExecutionWeeklyReview.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasExecutionWeeklyReview(
      id: map['id']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      generatedAt: _readDate(map['generatedAt']),
      periodStart: _readDate(map['periodStart']),
      periodEnd: _readDate(map['periodEnd']),
      totalActions: _readInt(map['totalActions']),
      openActions: _readInt(map['openActions']),
      completedInPeriod: _readInt(
        map['completedInPeriod'],
      ),
      overdueActions: _readInt(map['overdueActions']),
      blockedActions: _readInt(map['blockedActions']),
      actionsWithoutResponsible: _readInt(
        map['actionsWithoutResponsible'],
      ),
      actionsWithoutRecentFollowUp: _readInt(
        map['actionsWithoutRecentFollowUp'],
      ),
      averageProgressPercent: _readDouble(
        map['averageProgressPercent'],
      ),
      executionHealthPercent: _readDouble(
        map['executionHealthPercent'],
      ),
      expectedFinancialImpact: _readDouble(
        map['expectedFinancialImpact'],
      ),
      achievements: _readStrings(map['achievements']),
      bottlenecks: _readStrings(map['bottlenecks']),
      focusActions: _readStrings(map['focusActions']),
    );
  }

  static DateTime _readDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.now();
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _readStrings(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .map((item) => item.toString())
        .toList(growable: false);
  }
}
