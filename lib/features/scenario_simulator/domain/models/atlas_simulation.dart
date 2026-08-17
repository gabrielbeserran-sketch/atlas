import 'package:projeto_atlas/features/digital_twin/domain/models/atlas_digital_twin.dart';

class AtlasSimulation {
  const AtlasSimulation({
    required this.id,
    required this.name,
    required this.description,
    required this.farmId,
    required this.farmName,
    required this.createdAt,
    required this.horizonMonths,
    required this.changes,
  });

  final String id;
  final String name;
  final String description;
  final String farmId;
  final String farmName;
  final DateTime createdAt;
  final int horizonMonths;
  final AtlasSimulationChanges changes;

  AtlasSimulation copyWith({
    String? id,
    String? name,
    String? description,
    String? farmId,
    String? farmName,
    DateTime? createdAt,
    int? horizonMonths,
    AtlasSimulationChanges? changes,
  }) {
    return AtlasSimulation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      createdAt: createdAt ?? this.createdAt,
      horizonMonths: horizonMonths ?? this.horizonMonths,
      changes: changes ?? this.changes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'farmId': farmId,
      'farmName': farmName,
      'createdAt': createdAt.toIso8601String(),
      'horizonMonths': horizonMonths,
      'changes': changes.toJson(),
    };
  }

  factory AtlasSimulation.fromJson(Map<String, dynamic> json) {
    return AtlasSimulation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Cenário',
      description: json['description'] as String? ?? '',
      farmId: json['farmId'] as String? ?? 'global',
      farmName: json['farmName'] as String? ?? 'Operação',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      horizonMonths: json['horizonMonths'] as int? ?? 12,
      changes: AtlasSimulationChanges.fromJson(
        Map<String, dynamic>.from(
          json['changes'] as Map? ?? const <String, dynamic>{},
        ),
      ),
    );
  }
}

class AtlasSimulationChanges {
  const AtlasSimulationChanges({
    this.animalScoreChange = 0,
    this.sanitaryScoreChange = 0,
    this.reproductiveScoreChange = 0,
    this.financialScoreChange = 0,
    this.inventoryScoreChange = 0,
    this.operationalScoreChange = 0,
    this.herdSizeChange = 0,
    this.initialInvestment = 0,
    this.expectedMonthlyRevenueChange = 0,
    this.expectedMonthlyCostChange = 0,
  });

  final double animalScoreChange;
  final double sanitaryScoreChange;
  final double reproductiveScoreChange;
  final double financialScoreChange;
  final double inventoryScoreChange;
  final double operationalScoreChange;
  final int herdSizeChange;
  final double initialInvestment;
  final double expectedMonthlyRevenueChange;
  final double expectedMonthlyCostChange;

  bool get hasStrategicChange {
    return animalScoreChange != 0 ||
        sanitaryScoreChange != 0 ||
        reproductiveScoreChange != 0 ||
        financialScoreChange != 0 ||
        inventoryScoreChange != 0 ||
        operationalScoreChange != 0 ||
        herdSizeChange != 0 ||
        initialInvestment != 0 ||
        expectedMonthlyRevenueChange != 0 ||
        expectedMonthlyCostChange != 0;
  }

  double changeForArea(AtlasDigitalTwinArea area) {
    switch (area) {
      case AtlasDigitalTwinArea.animal:
        return animalScoreChange;
      case AtlasDigitalTwinArea.sanitary:
        return sanitaryScoreChange;
      case AtlasDigitalTwinArea.reproductive:
        return reproductiveScoreChange;
      case AtlasDigitalTwinArea.financial:
        return financialScoreChange;
      case AtlasDigitalTwinArea.inventory:
        return inventoryScoreChange;
      case AtlasDigitalTwinArea.operational:
        return operationalScoreChange;
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'animalScoreChange': animalScoreChange,
      'sanitaryScoreChange': sanitaryScoreChange,
      'reproductiveScoreChange': reproductiveScoreChange,
      'financialScoreChange': financialScoreChange,
      'inventoryScoreChange': inventoryScoreChange,
      'operationalScoreChange': operationalScoreChange,
      'herdSizeChange': herdSizeChange,
      'initialInvestment': initialInvestment,
      'expectedMonthlyRevenueChange': expectedMonthlyRevenueChange,
      'expectedMonthlyCostChange': expectedMonthlyCostChange,
    };
  }

  factory AtlasSimulationChanges.fromJson(Map<String, dynamic> json) {
    return AtlasSimulationChanges(
      animalScoreChange: (json['animalScoreChange'] as num?)?.toDouble() ?? 0,
      sanitaryScoreChange:
          (json['sanitaryScoreChange'] as num?)?.toDouble() ?? 0,
      reproductiveScoreChange:
          (json['reproductiveScoreChange'] as num?)?.toDouble() ?? 0,
      financialScoreChange:
          (json['financialScoreChange'] as num?)?.toDouble() ?? 0,
      inventoryScoreChange:
          (json['inventoryScoreChange'] as num?)?.toDouble() ?? 0,
      operationalScoreChange:
          (json['operationalScoreChange'] as num?)?.toDouble() ?? 0,
      herdSizeChange: json['herdSizeChange'] as int? ?? 0,
      initialInvestment: (json['initialInvestment'] as num?)?.toDouble() ?? 0,
      expectedMonthlyRevenueChange:
          (json['expectedMonthlyRevenueChange'] as num?)?.toDouble() ?? 0,
      expectedMonthlyCostChange:
          (json['expectedMonthlyCostChange'] as num?)?.toDouble() ?? 0,
    );
  }
}
