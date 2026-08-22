import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/atlas_report.dart';

class AtlasReportRepository {
  static const String _storageKey = 'atlas_reporting_documents_v1';

  Future<List<AtlasReport>> load({String? farmId}) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<String> stored =
        preferences.getStringList(_storageKey) ?? <String>[];

    final List<AtlasReport> reports = stored
        .map(AtlasReport.fromJson)
        .where((AtlasReport item) => farmId == null || item.farmId == farmId)
        .toList();

    if (reports.isNotEmpty) {
      reports.sort(
        (AtlasReport a, AtlasReport b) => b.updatedAt.compareTo(a.updatedAt),
      );
      return reports;
    }

    return <AtlasReport>[];
  }

  Future<void> save(List<AtlasReport> reports) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      reports.map((AtlasReport item) => item.toJson()).toList(),
    );
  }
}
