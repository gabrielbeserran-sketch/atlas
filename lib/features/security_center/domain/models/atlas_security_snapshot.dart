class AtlasSecuritySnapshot {
  const AtlasSecuritySnapshot({
    required this.dashboard,
    required this.auditValid,
    required this.auditRecords,
  });
  final Map<String, dynamic> dashboard;
  final bool auditValid;
  final int auditRecords;

  factory AtlasSecuritySnapshot.fromMaps(
    Map<String, dynamic> dashboard,
    Map<String, dynamic> audit,
  ) {
    return AtlasSecuritySnapshot(
      dashboard: Map<String, dynamic>.unmodifiable(dashboard),
      auditValid: audit['valid'] == true,
      auditRecords: (audit['records'] as num?)?.toInt() ?? 0,
    );
  }
  int count(String key) =>
      (dashboard[key] as num?)?.toInt() ??
      int.tryParse(dashboard[key]?.toString() ?? '') ??
      0;
}
