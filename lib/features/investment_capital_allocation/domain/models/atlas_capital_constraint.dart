class AtlasCapitalConstraint {
  const AtlasCapitalConstraint({
    required this.availableCash,
    required this.annualBudget,
    required this.maximumDebt,
    required this.interestRate,
    required this.financingYears,
    required this.maximumCashCommitment,
    required this.discountRate,
  });

  final double availableCash;
  final double annualBudget;
  final double maximumDebt;
  final double interestRate;
  final int financingYears;
  final double maximumCashCommitment;
  final double discountRate;

  double get ownCapitalLimit =>
      availableCash * (maximumCashCommitment.clamp(0, 100) / 100);
  double get totalCapitalLimit => ownCapitalLimit + maximumDebt;

  AtlasCapitalConstraint copyWith({
    double? availableCash,
    double? annualBudget,
    double? maximumDebt,
    double? interestRate,
    int? financingYears,
    double? maximumCashCommitment,
    double? discountRate,
  }) {
    return AtlasCapitalConstraint(
      availableCash: availableCash ?? this.availableCash,
      annualBudget: annualBudget ?? this.annualBudget,
      maximumDebt: maximumDebt ?? this.maximumDebt,
      interestRate: interestRate ?? this.interestRate,
      financingYears: financingYears ?? this.financingYears,
      maximumCashCommitment:
          maximumCashCommitment ?? this.maximumCashCommitment,
      discountRate: discountRate ?? this.discountRate,
    );
  }
}
