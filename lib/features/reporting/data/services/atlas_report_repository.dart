import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/atlas_report.dart';

class AtlasReportRepository {
  static const String _storageKey = 'atlas_reporting_documents_v1';

  Future<List<AtlasReport>> load({String? farmId}) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final List<String> stored =
        preferences.getStringList(_storageKey) ?? <String>[];

    final List<AtlasReport> reports = stored
        .map(AtlasReport.fromJson)
        .where((AtlasReport item) => farmId == null || item.farmId == farmId)
        .toList();

    if (reports.isNotEmpty) {
      reports.sort((AtlasReport a, AtlasReport b) =>
          b.updatedAt.compareTo(a.updatedAt));
      return reports;
    }

    return _seed(farmId);
  }

  Future<void> save(List<AtlasReport> reports) async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      reports.map((AtlasReport item) => item.toJson()).toList(),
    );
  }

  List<AtlasReport> _seed(String? farmId) {
    final DateTime now = DateTime.now();
    return <AtlasReport>[
      AtlasReport(
        id: 'report-${now.microsecondsSinceEpoch}',
        farmId: farmId,
        title: 'Relatório técnico mensal',
        propertyName: 'Fazenda modelo',
        clientName: 'Produtor demonstrativo',
        type: AtlasReportType.technicalVisit,
        status: AtlasReportStatus.ready,
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(days: 2)),
        periodLabel: 'Últimos 30 dias',
        executiveSummary:
            'A propriedade apresentou evolução operacional, com atenção necessária ao custo por arroba e ao cumprimento das ações reprodutivas.',
        recommendations: const <String>[
          'Revisar o protocolo nutricional do lote de recria.',
          'Priorizar as matrizes com atraso reprodutivo.',
          'Acompanhar semanalmente o custo por arroba produzida.',
        ],
        kpis: const <String, double>{
          'Executive Score': 82,
          'Taxa de prenhez': 76,
          'Avanço do plano': 68,
          'Margem operacional': 18.4,
        },
      ),
    ];
  }
}
