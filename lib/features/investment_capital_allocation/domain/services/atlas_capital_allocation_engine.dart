import 'dart:math' as math;

import '../models/atlas_capital_constraint.dart';
import '../models/atlas_financing_simulation.dart';
import '../models/atlas_investment_portfolio.dart';
import '../models/atlas_investment_project.dart';

class AtlasCapitalAllocationEngine {
  const AtlasCapitalAllocationEngine();

  AtlasInvestmentPortfolio optimize({
    required List<AtlasInvestmentProject> projects,
    required AtlasCapitalConstraint constraint,
  }) {
    final analyses =
        projects.map((project) {
          final npv = _npv(project, constraint.discountRate);
          final roi = project.totalCapital <= 0
              ? 0.0
              : ((project.annualNetCashFlow * project.horizonYears +
                            project.residualValue -
                            project.totalCapital) /
                        project.totalCapital) *
                    100;
          final payback = project.annualNetCashFlow <= 0
              ? 99.0
              : project.totalCapital / project.annualNetCashFlow;
          final irr = _irr(project);
          final score = _priority(project, npv, roi, payback);
          final decision = _decision(project, npv, roi, payback, score);
          return AtlasInvestmentProjectAnalysis(
            project: project,
            npv: npv,
            roi: roi,
            irr: irr,
            paybackYears: payback,
            priorityScore: score,
            decision: decision,
            reason: _reason(project, npv, roi, payback, decision),
          );
        }).toList()..sort((a, b) {
          if (a.project.mandatory != b.project.mandatory) {
            return a.project.mandatory ? -1 : 1;
          }
          return b.priorityScore.compareTo(a.priorityScore);
        });

    final selected = <AtlasInvestmentProjectAnalysis>[];
    var allocated = 0.0;
    final limit = math.min(
      constraint.totalCapitalLimit,
      constraint.annualBudget,
    );
    for (final item in analyses) {
      final acceptable =
          item.decision == AtlasInvestmentDecision.approve ||
          item.decision == AtlasInvestmentDecision.phase ||
          item.project.mandatory;
      if (acceptable && allocated + item.project.totalCapital <= limit) {
        selected.add(item);
        allocated += item.project.totalCapital;
      }
    }

    final ownCapital = math.min(allocated, constraint.ownCapitalLimit);
    final financed = math.max(0.0, allocated - ownCapital);
    final financing = simulateFinancing(
      amount: financed,
      annualRate: constraint.interestRate,
      years: constraint.financingYears,
    );

    final selectedCapital = selected.fold<double>(
      0,
      (sum, item) => sum + item.project.totalCapital,
    );
    final selectedNpv = selected.fold<double>(0, (sum, item) => sum + item.npv);
    final selectedProfit = selected.fold<double>(
      0,
      (sum, item) =>
          sum +
          item.project.annualNetCashFlow * item.project.horizonYears +
          item.project.residualValue -
          item.project.totalCapital,
    );
    final portfolioRoi = selectedCapital <= 0
        ? 0.0
        : selectedProfit / selectedCapital * 100;
    final averageRisk = selected.isEmpty
        ? 0.0
        : selected.fold<double>(
                0,
                (sum, item) => sum + item.project.riskScore,
              ) /
              selected.length;
    final averagePayback = selected.isEmpty
        ? 0.0
        : selected.fold<double>(0, (sum, item) => sum + item.paybackYears) /
              selected.length;

    return AtlasInvestmentPortfolio(
      items: analyses,
      selected: selected,
      totalRequiredCapital: projects.fold<double>(
        0,
        (sum, item) => sum + item.totalCapital,
      ),
      allocatedCapital: allocated,
      remainingCapital: math.max(0, limit - allocated),
      portfolioNpv: selectedNpv,
      portfolioRoi: portfolioRoi,
      averageRisk: averageRisk,
      averagePayback: averagePayback,
      financing: financing,
      recommendation: selected.isEmpty
          ? 'Revise as premissas: nenhum projeto cabe no orçamento com retorno e risco aceitáveis.'
          : 'Priorize ${selected.length} projeto(s), preserve a reserva de caixa e reavalie os projetos adiados no próximo ciclo.',
    );
  }

  AtlasFinancingSimulation simulateFinancing({
    required double amount,
    required double annualRate,
    required int years,
  }) {
    if (amount <= 0 || years <= 0) {
      return const AtlasFinancingSimulation(
        financedAmount: 0,
        monthlyPayment: 0,
        totalPaid: 0,
        totalInterest: 0,
      );
    }
    final months = years * 12;
    final rate = annualRate / 100 / 12;
    final payment = rate == 0
        ? amount / months
        : amount *
              rate *
              math.pow(1 + rate, months) /
              (math.pow(1 + rate, months) - 1);
    final total = payment * months;
    return AtlasFinancingSimulation(
      financedAmount: amount,
      monthlyPayment: payment,
      totalPaid: total,
      totalInterest: total - amount,
    );
  }

  double _npv(AtlasInvestmentProject project, double discountRate) {
    var value = -project.totalCapital;
    final rate = discountRate / 100;
    for (var year = 1; year <= project.horizonYears; year++) {
      var flow = project.annualNetCashFlow;
      if (year == project.horizonYears) flow += project.residualValue;
      value += flow / math.pow(1 + rate, year);
    }
    return value;
  }

  double _irr(AtlasInvestmentProject project) {
    var low = -0.95;
    var high = 5.0;
    for (var i = 0; i < 80; i++) {
      final rate = (low + high) / 2;
      var value = -project.totalCapital;
      for (var year = 1; year <= project.horizonYears; year++) {
        var flow = project.annualNetCashFlow;
        if (year == project.horizonYears) flow += project.residualValue;
        value += flow / math.pow(1 + rate, year);
      }
      if (value > 0) {
        low = rate;
      } else {
        high = rate;
      }
    }
    return ((low + high) / 2) * 100;
  }

  double _priority(
    AtlasInvestmentProject project,
    double npv,
    double roi,
    double payback,
  ) {
    final returnScore = (roi.clamp(-100, 200) + 100) / 3;
    final npvScore = project.totalCapital <= 0
        ? 0.0
        : ((npv / project.totalCapital) * 50 + 50).clamp(0, 100).toDouble();
    final paybackScore = (100 - payback * 12).clamp(0, 100).toDouble();
    final riskScore = 100 - project.riskScore.clamp(0, 100);
    final mandatoryBonus = project.mandatory ? 12.0 : 0.0;
    return (returnScore * 0.25 +
            npvScore * 0.25 +
            paybackScore * 0.15 +
            project.strategicAlignment * 0.15 +
            project.operationalCapacity * 0.10 +
            riskScore * 0.10 +
            mandatoryBonus)
        .clamp(0, 100)
        .toDouble();
  }

  AtlasInvestmentDecision _decision(
    AtlasInvestmentProject project,
    double npv,
    double roi,
    double payback,
    double score,
  ) {
    if (project.mandatory) return AtlasInvestmentDecision.approve;
    if (npv > 0 && roi >= 20 && score >= 65 && project.riskScore <= 65) {
      return AtlasInvestmentDecision.approve;
    }
    if (npv > 0 && roi > 0 && score >= 48) {
      return AtlasInvestmentDecision.phase;
    }
    if (npv > 0 || score >= 38) return AtlasInvestmentDecision.postpone;
    return AtlasInvestmentDecision.reject;
  }

  String _reason(
    AtlasInvestmentProject project,
    double npv,
    double roi,
    double payback,
    AtlasInvestmentDecision decision,
  ) {
    if (project.mandatory) {
      return 'Projeto obrigatório: deve ser protegido no orçamento antes dos investimentos discricionários.';
    }
    switch (decision) {
      case AtlasInvestmentDecision.approve:
        return 'Retorno, valor presente, risco e aderência estratégica sustentam a execução.';
      case AtlasInvestmentDecision.phase:
        return 'Há geração de valor, mas a implantação por etapas reduz pressão de caixa e risco operacional.';
      case AtlasInvestmentDecision.postpone:
        return 'O projeto precisa de melhor relação entre retorno, prazo e capacidade disponível.';
      case AtlasInvestmentDecision.reject:
        return 'As premissas atuais indicam destruição de valor ou risco excessivo.';
    }
  }
}
