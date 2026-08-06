class AtlasSprints1620DashboardData {
  const AtlasSprints1620DashboardData({required this.billing,required this.publicApi,required this.analytics,required this.machineLearning,required this.enterprise});
  final Map<String,dynamic> billing;
  final Map<String,dynamic> publicApi;
  final Map<String,dynamic> analytics;
  final Map<String,dynamic> machineLearning;
  final Map<String,dynamic> enterprise;
  factory AtlasSprints1620DashboardData.fromJson(Map<String,dynamic> json)=>AtlasSprints1620DashboardData(
    billing: Map<String,dynamic>.from(json['billing'] as Map? ?? const {}),
    publicApi: Map<String,dynamic>.from(json['public_api'] as Map? ?? const {}),
    analytics: Map<String,dynamic>.from(json['analytics'] as Map? ?? const {}),
    machineLearning: Map<String,dynamic>.from(json['machine_learning'] as Map? ?? const {}),
    enterprise: Map<String,dynamic>.from(json['enterprise_1_0'] as Map? ?? const {}),
  );
}
