class AtlasExecutionCycleReport {
  const AtlasExecutionCycleReport({
    required this.id,
    required this.farmName,
    required this.generatedAt,
    required this.periodStart,
    required this.periodEnd,
    required this.totalActions,
    required this.completedActions,
    required this.overdueActions,
    required this.actionsWithOutcome,
    required this.expectedFinancialImpact,
    required this.realizedFinancialImpact,
    required this.executionCost,
    required this.totalNetFinancialResult,
    required this.averageRoiPercent,
    required this.executiveSummary,
    required this.highlights,
    required this.attentionPoints,
    required this.lessonsLearned,
  });

  final String id;
  final String? farmName;
  final DateTime generatedAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalActions;
  final int completedActions;
  final int overdueActions;
  final int actionsWithOutcome;
  final double expectedFinancialImpact;
  final double realizedFinancialImpact;
  final double executionCost;
  final double totalNetFinancialResult;
  final double averageRoiPercent;
  final String executiveSummary;
  final List<String> highlights;
  final List<String> attentionPoints;
  final List<String> lessonsLearned;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'farmName': farmName,
      'generatedAt': generatedAt.toIso8601String(),
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'totalActions': totalActions,
      'completedActions': completedActions,
      'overdueActions': overdueActions,
      'actionsWithOutcome': actionsWithOutcome,
      'expectedFinancialImpact':
          expectedFinancialImpact,
      'realizedFinancialImpact':
          realizedFinancialImpact,
      'executionCost': executionCost,
      'totalNetFinancialResult':
          totalNetFinancialResult,
      'averageRoiPercent': averageRoiPercent,
      'executiveSummary': executiveSummary,
      'highlights': highlights,
      'attentionPoints': attentionPoints,
      'lessonsLearned': lessonsLearned,
    };
  }

  factory AtlasExecutionCycleReport.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasExecutionCycleReport(
      id: map['id']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      generatedAt: _readDate(map['generatedAt']),
      periodStart: _readDate(map['periodStart']),
      periodEnd: _readDate(map['periodEnd']),
      totalActions: _readInt(map['totalActions']),
      completedActions:
          _readInt(map['completedActions']),
      overdueActions: _readInt(map['overdueActions']),
      actionsWithOutcome:
          _readInt(map['actionsWithOutcome']),
      expectedFinancialImpact:
          _readDouble(map['expectedFinancialImpact']),
      realizedFinancialImpact:
          _readDouble(map['realizedFinancialImpact']),
      executionCost: _readDouble(map['executionCost']),
      totalNetFinancialResult:
          _readDouble(map['totalNetFinancialResult']),
      averageRoiPercent:
          _readDouble(map['averageRoiPercent']),
      executiveSummary:
          map['executiveSummary']?.toString() ?? '',
      highlights: _readStrings(map['highlights']),
      attentionPoints:
          _readStrings(map['attentionPoints']),
      lessonsLearned:
          _readStrings(map['lessonsLearned']),
    );
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

  static DateTime _readDate(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.now();
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
