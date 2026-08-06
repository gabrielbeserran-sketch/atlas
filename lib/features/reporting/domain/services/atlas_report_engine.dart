import '../models/atlas_report.dart';

class AtlasReportSummary {
  const AtlasReportSummary({
    required this.total,
    required this.ready,
    required this.drafts,
    required this.archived,
    required this.averageKpi,
  });

  final int total;
  final int ready;
  final int drafts;
  final int archived;
  final double averageKpi;
}

class AtlasReportEngine {
  const AtlasReportEngine();

  AtlasReportSummary summarize(List<AtlasReport> reports) {
    final List<double> values = reports
        .expand((AtlasReport report) => report.kpis.values)
        .toList();

    return AtlasReportSummary(
      total: reports.length,
      ready: reports
          .where((AtlasReport item) => item.status == AtlasReportStatus.ready)
          .length,
      drafts: reports
          .where((AtlasReport item) => item.status == AtlasReportStatus.draft)
          .length,
      archived: reports
          .where((AtlasReport item) => item.status == AtlasReportStatus.archived)
          .length,
      averageKpi: values.isEmpty
          ? 0
          : values.reduce((double a, double b) => a + b) / values.length,
    );
  }

  String buildPlainText(AtlasReport report) {
    final StringBuffer buffer = StringBuffer()
      ..writeln(report.authorName)
      ..writeln(report.title)
      ..writeln('Propriedade: ${report.propertyName}')
      ..writeln('Cliente: ${report.clientName}')
      ..writeln('Período: ${report.periodLabel}')
      ..writeln()
      ..writeln('RESUMO EXECUTIVO')
      ..writeln(report.executiveSummary)
      ..writeln()
      ..writeln('INDICADORES');

    for (final MapEntry<String, double> entry in report.kpis.entries) {
      buffer.writeln('${entry.key}: ${entry.value.toStringAsFixed(1)}');
    }

    buffer
      ..writeln()
      ..writeln('RECOMENDAÇÕES');

    for (int index = 0; index < report.recommendations.length; index++) {
      buffer.writeln('${index + 1}. ${report.recommendations[index]}');
    }

    return buffer.toString();
  }
}
