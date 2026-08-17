import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_atlas_score.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_dashboard_period.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_executive_diagnosis.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_financial_series_point.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_farm_summary.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_health_series_point.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_inventory_series_point.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_nutrition_series_point.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_reproduction_series_point.dart';
import 'package:projeto_atlas/features/technical_dashboard/domain/models/technical_weight_series_point.dart';

class TechnicalDashboardAnalysis {
  const TechnicalDashboardAnalysis({
    required this.period,
    required this.generatedAt,
    required this.current,
    required this.financialSeries,
    required this.weightSeries,
    required this.reproductionSeries,
    required this.healthSeries,
    required this.inventorySeries,
    required this.nutritionSeries,
    this.previous,
  });

  final TechnicalDashboardPeriod period;
  final DateTime generatedAt;
  final TechnicalFarmSummary current;
  final List<TechnicalFinancialSeriesPoint> financialSeries;
  final List<TechnicalWeightSeriesPoint> weightSeries;
  final List<TechnicalReproductionSeriesPoint> reproductionSeries;
  final List<TechnicalHealthSeriesPoint> healthSeries;
  final List<TechnicalInventorySeriesPoint> inventorySeries;
  final List<TechnicalNutritionSeriesPoint> nutritionSeries;
  final TechnicalFarmSummary? previous;

  bool get hasComparison => previous != null;

  TechnicalAtlasScore get atlasScore =>
      TechnicalAtlasScore.fromSummary(current);

  TechnicalExecutiveDiagnosis get executiveDiagnosis =>
      TechnicalExecutiveDiagnosis.fromData(
        summary: current,
        score: atlasScore,
        balanceVariationPercent: balanceVariationPercent,
      );

  double? get incomeVariationPercent =>
      _variation(current.income, previous?.income);

  double? get expenseVariationPercent =>
      _variation(current.expenses, previous?.expenses);

  double? get balanceVariationPercent =>
      _variation(current.balance, previous?.balance);

  double? get healthRecordVariationPercent => _variation(
    current.healthRecords.toDouble(),
    previous?.healthRecords.toDouble(),
  );

  double? get reproductionRecordVariationPercent => _variation(
    current.reproductionRecords.toDouble(),
    previous?.reproductionRecords.toDouble(),
  );

  static double? _variation(double current, double? previous) {
    if (previous == null) return null;
    if (previous == 0) {
      if (current == 0) return 0;
      return null;
    }
    return ((current - previous) / previous.abs()) * 100;
  }
}
