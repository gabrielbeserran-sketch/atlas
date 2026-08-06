class AtlasSprints2125DashboardData {
  const AtlasSprints2125DashboardData({required this.precision, required this.reproduction, required this.health, required this.nutrition, required this.operations});
  final Map<String, dynamic> precision;
  final Map<String, dynamic> reproduction;
  final Map<String, dynamic> health;
  final Map<String, dynamic> nutrition;
  final Map<String, dynamic> operations;
  factory AtlasSprints2125DashboardData.fromJson(Map<String, dynamic> json) => AtlasSprints2125DashboardData(
    precision: Map<String, dynamic>.from(json['precision'] as Map? ?? const {}),
    reproduction: Map<String, dynamic>.from(json['reproduction'] as Map? ?? const {}),
    health: Map<String, dynamic>.from(json['health'] as Map? ?? const {}),
    nutrition: Map<String, dynamic>.from(json['nutrition'] as Map? ?? const {}),
    operations: Map<String, dynamic>.from(json['operations'] as Map? ?? const {}),
  );
}
