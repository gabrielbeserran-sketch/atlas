class AtlasFinancingSimulation {
  const AtlasFinancingSimulation({
    required this.financedAmount,
    required this.monthlyPayment,
    required this.totalPaid,
    required this.totalInterest,
  });

  final double financedAmount;
  final double monthlyPayment;
  final double totalPaid;
  final double totalInterest;
}
