import 'dart:convert';

enum AtlasReportType {
  technicalVisit,
  executive,
  reproductive,
  productive,
  financial,
  sanitary,
  investment,
  actionPlan,
}

enum AtlasReportStatus { draft, ready, archived }

class AtlasReport {
  const AtlasReport({
    required this.id,
    required this.title,
    required this.propertyName,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.periodLabel,
    required this.executiveSummary,
    required this.recommendations,
    required this.kpis,
    this.farmId,
    this.clientName = '',
    this.authorName = 'Beserra Consultoria Veterinária',
  });

  final String id;
  final String? farmId;
  final String title;
  final String propertyName;
  final String clientName;
  final AtlasReportType type;
  final AtlasReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String periodLabel;
  final String executiveSummary;
  final List<String> recommendations;
  final Map<String, double> kpis;
  final String authorName;

  AtlasReport copyWith({
    String? title,
    String? propertyName,
    String? clientName,
    AtlasReportType? type,
    AtlasReportStatus? status,
    DateTime? updatedAt,
    String? periodLabel,
    String? executiveSummary,
    List<String>? recommendations,
    Map<String, double>? kpis,
    String? authorName,
  }) {
    return AtlasReport(
      id: id,
      farmId: farmId,
      title: title ?? this.title,
      propertyName: propertyName ?? this.propertyName,
      clientName: clientName ?? this.clientName,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      periodLabel: periodLabel ?? this.periodLabel,
      executiveSummary: executiveSummary ?? this.executiveSummary,
      recommendations: recommendations ?? this.recommendations,
      kpis: kpis ?? this.kpis,
      authorName: authorName ?? this.authorName,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'farmId': farmId,
      'title': title,
      'propertyName': propertyName,
      'clientName': clientName,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'periodLabel': periodLabel,
      'executiveSummary': executiveSummary,
      'recommendations': recommendations,
      'kpis': kpis,
      'authorName': authorName,
    };
  }

  factory AtlasReport.fromMap(Map<String, dynamic> map) {
    return AtlasReport(
      id: map['id'] as String,
      farmId: map['farmId'] as String?,
      title: map['title'] as String? ?? '',
      propertyName: map['propertyName'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      type: AtlasReportType.values.firstWhere(
        (AtlasReportType item) => item.name == map['type'],
        orElse: () => AtlasReportType.technicalVisit,
      ),
      status: AtlasReportStatus.values.firstWhere(
        (AtlasReportStatus item) => item.name == map['status'],
        orElse: () => AtlasReportStatus.draft,
      ),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      periodLabel: map['periodLabel'] as String? ?? '',
      executiveSummary: map['executiveSummary'] as String? ?? '',
      recommendations: (map['recommendations'] as List<dynamic>? ?? const [])
          .map((dynamic item) => item.toString())
          .toList(),
      kpis: (map['kpis'] as Map<String, dynamic>? ?? const <String, dynamic>{})
          .map((String key, dynamic value) =>
              MapEntry<String, double>(key, (value as num).toDouble())),
      authorName:
          map['authorName'] as String? ?? 'Beserra Consultoria Veterinária',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AtlasReport.fromJson(String source) {
    return AtlasReport.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}
