import 'atlas_financing_simulation.dart';
import 'atlas_investment_project.dart';

class AtlasInvestmentProjectAnalysis {
  const AtlasInvestmentProjectAnalysis({
    required this.project,
    required this.npv,
    required this.roi,
    required this.irr,
    required this.paybackYears,
    required this.priorityScore,
    required this.decision,
    required this.reason,
  });

  final AtlasInvestmentProject project;
  final double npv;
  final double roi;
  final double irr;
  final double paybackYears;
  final double priorityScore;
  final AtlasInvestmentDecision decision;
  final String reason;
}

class AtlasInvestmentPortfolio {
  const AtlasInvestmentPortfolio({
    required this.items,
    required this.selected,
    required this.totalRequiredCapital,
    required this.allocatedCapital,
    required this.remainingCapital,
    required this.portfolioNpv,
    required this.portfolioRoi,
    required this.averageRisk,
    required this.averagePayback,
    required this.financing,
    required this.recommendation,
  });

  final List<AtlasInvestmentProjectAnalysis> items;
  final List<AtlasInvestmentProjectAnalysis> selected;
  final double totalRequiredCapital;
  final double allocatedCapital;
  final double remainingCapital;
  final double portfolioNpv;
  final double portfolioRoi;
  final double averageRisk;
  final double averagePayback;
  final AtlasFinancingSimulation financing;
  final String recommendation;
}
