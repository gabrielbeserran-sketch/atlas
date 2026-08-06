class AtlasSprintsDashboardData {
  const AtlasSprintsDashboardData(this.raw);
  final Map<String, dynamic> raw;
  factory AtlasSprintsDashboardData.fromJson(Map<String,dynamic> json)=>AtlasSprintsDashboardData(json);
  Map<String,dynamic> get brain=>Map<String,dynamic>.from(raw['brain'] as Map? ?? const {});
  Map<String,dynamic> get vision=>Map<String,dynamic>.from(raw['vision'] as Map? ?? const {});
  Map<String,dynamic> get iot=>Map<String,dynamic>.from(raw['iot'] as Map? ?? const {});
  Map<String,dynamic> get cloud=>Map<String,dynamic>.from(raw['cloud'] as Map? ?? const {});
  Map<String,dynamic> get web=>Map<String,dynamic>.from(raw['web'] as Map? ?? const {});
}
