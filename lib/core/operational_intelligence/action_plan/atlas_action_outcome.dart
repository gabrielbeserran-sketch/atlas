class AtlasActionOutcome {
  const AtlasActionOutcome({
    required this.id,
    required this.actionId,
    required this.farmName,
    required this.technicalResult,
    required this.lessonsLearned,
    required this.evidence,
    required this.expectedFinancialImpact,
    required this.realizedFinancialImpact,
    required this.executionCost,
    required this.revenueGenerated,
    required this.savingsGenerated,
    required this.recordedAt,
    required this.updatedAt,
  });

  final String id;
  final String actionId;
  final String? farmName;
  final String technicalResult;
  final String lessonsLearned;
  final String evidence;
  final double expectedFinancialImpact;
  final double realizedFinancialImpact;
  final double executionCost;
  final double revenueGenerated;
  final double savingsGenerated;
  final DateTime recordedAt;
  final DateTime updatedAt;

  double get totalFinancialBenefit =>
      realizedFinancialImpact +
      revenueGenerated +
      savingsGenerated;

  double get netFinancialResult =>
      totalFinancialBenefit - executionCost;

  double get financialVariance =>
      realizedFinancialImpact - expectedFinancialImpact;

  double get roiPercent {
    if (executionCost <= 0) {
      return totalFinancialBenefit > 0 ? 100 : 0;
    }

    return netFinancialResult / executionCost * 100;
  }

  bool get hasTechnicalResult =>
      technicalResult.trim().isNotEmpty;

  bool get hasFinancialData =>
      expectedFinancialImpact != 0 ||
      realizedFinancialImpact != 0 ||
      executionCost != 0 ||
      revenueGenerated != 0 ||
      savingsGenerated != 0;

  AtlasActionOutcome copyWith({
    String? technicalResult,
    String? lessonsLearned,
    String? evidence,
    double? expectedFinancialImpact,
    double? realizedFinancialImpact,
    double? executionCost,
    double? revenueGenerated,
    double? savingsGenerated,
    DateTime? updatedAt,
  }) {
    return AtlasActionOutcome(
      id: id,
      actionId: actionId,
      farmName: farmName,
      technicalResult:
          technicalResult ?? this.technicalResult,
      lessonsLearned:
          lessonsLearned ?? this.lessonsLearned,
      evidence: evidence ?? this.evidence,
      expectedFinancialImpact:
          expectedFinancialImpact ??
          this.expectedFinancialImpact,
      realizedFinancialImpact:
          realizedFinancialImpact ??
          this.realizedFinancialImpact,
      executionCost: executionCost ?? this.executionCost,
      revenueGenerated:
          revenueGenerated ?? this.revenueGenerated,
      savingsGenerated:
          savingsGenerated ?? this.savingsGenerated,
      recordedAt: recordedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'actionId': actionId,
      'farmName': farmName,
      'technicalResult': technicalResult,
      'lessonsLearned': lessonsLearned,
      'evidence': evidence,
      'expectedFinancialImpact':
          expectedFinancialImpact,
      'realizedFinancialImpact':
          realizedFinancialImpact,
      'executionCost': executionCost,
      'revenueGenerated': revenueGenerated,
      'savingsGenerated': savingsGenerated,
      'recordedAt': recordedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AtlasActionOutcome.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasActionOutcome(
      id: map['id']?.toString() ?? '',
      actionId: map['actionId']?.toString() ?? '',
      farmName: map['farmName']?.toString(),
      technicalResult:
          map['technicalResult']?.toString() ?? '',
      lessonsLearned:
          map['lessonsLearned']?.toString() ?? '',
      evidence: map['evidence']?.toString() ?? '',
      expectedFinancialImpact: _readDouble(
        map['expectedFinancialImpact'],
      ),
      realizedFinancialImpact: _readDouble(
        map['realizedFinancialImpact'],
      ),
      executionCost:
          _readDouble(map['executionCost']),
      revenueGenerated:
          _readDouble(map['revenueGenerated']),
      savingsGenerated:
          _readDouble(map['savingsGenerated']),
      recordedAt: DateTime.tryParse(
            map['recordedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
            map['updatedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
