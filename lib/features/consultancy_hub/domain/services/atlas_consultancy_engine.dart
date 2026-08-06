import '../models/atlas_consultancy_record.dart';

class AtlasConsultancySummary {
  const AtlasConsultancySummary({required this.total, required this.active, required this.attention, required this.visitsNext30Days, required this.averageScore, required this.monthlyRevenue, required this.openActions});
  final int total, active, attention, visitsNext30Days, openActions;
  final double averageScore, monthlyRevenue;
}

class AtlasConsultancyEngine {
  const AtlasConsultancyEngine();

  AtlasConsultancySummary summarize(List<AtlasConsultancyRecord> items) {
    final now = DateTime.now();
    final limit = now.add(const Duration(days: 30));
    final score = items.isEmpty ? 0.0 : items.fold<double>(0, (s, e) => s + e.executiveScore) / items.length;
    return AtlasConsultancySummary(
      total: items.length,
      active: items.where((e) => e.status == AtlasClientStatus.active).length,
      attention: items.where((e) => e.status == AtlasClientStatus.attention).length,
      visitsNext30Days: items.where((e) => !e.nextVisit.isBefore(now) && !e.nextVisit.isAfter(limit)).length,
      averageScore: score,
      monthlyRevenue: items.where((e) => e.status != AtlasClientStatus.inactive).fold<double>(0, (s, e) => s + e.monthlyFee),
      openActions: items.fold<int>(0, (s, e) => s + e.openActions),
    );
  }
}
