enum AtlasAutomationModule { drone, iot, managementAutomation, workflow }

extension AtlasAutomationModuleX on AtlasAutomationModule {
  String get code => switch (this) {
    AtlasAutomationModule.drone => 'drone',
    AtlasAutomationModule.iot => 'iot',
    AtlasAutomationModule.managementAutomation => 'management_automation',
    AtlasAutomationModule.workflow => 'workflow',
  };

  String get title => switch (this) {
    AtlasAutomationModule.drone => 'Drone Enterprise',
    AtlasAutomationModule.iot => 'IoT Enterprise',
    AtlasAutomationModule.managementAutomation => 'Automação de Manejos',
    AtlasAutomationModule.workflow => 'Workflow Operacional',
  };

  String get packageLabel => title;

  List<String> get features => switch (this) {
    AtlasAutomationModule.drone => const [
      'Planejamento de voos',
      'Contagem automática de animais',
      'Inspeção de cercas',
      'Inspeção de bebedouros',
      'Mapeamento de pastagens',
    ],
    AtlasAutomationModule.iot => const [
      'Sensores ambientais',
      'Sensores de água',
      'Sensores de ração',
      'Colares inteligentes',
      'Gateway IoT Atlas',
    ],
    AtlasAutomationModule.managementAutomation => const [
      'Automação de manejos',
      'Agenda automática',
      'Protocolos inteligentes',
      'Checklist digital',
      'Aprovação eletrônica',
    ],
    AtlasAutomationModule.workflow => const [
      'Workflow operacional',
      'Auditoria automática',
      'Controle de qualidade',
      'Indicadores Lean',
      'Gestão de processos',
    ],
  };
}

class AtlasAutomationRecord {
  const AtlasAutomationRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.deviceOrResponsible,
    required this.reference,
    required this.primaryValue,
    required this.secondaryValue,
    required this.unit,
    required this.progressPercent,
    required this.alertCount,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasAutomationModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String deviceOrResponsible;
  final String reference;
  final double primaryValue;
  final double secondaryValue;
  final String unit;
  final int progressPercent;
  final int alertCount;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Atenção' ||
      status == 'Offline' ||
      status == 'Bloqueado';

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Conectado' ||
      status == 'Concluído' ||
      status == 'Aprovado';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'deviceOrResponsible': deviceOrResponsible,
      'reference': reference,
      'primaryValue': primaryValue,
      'secondaryValue': secondaryValue,
      'unit': unit,
      'progressPercent': progressPercent,
      'alertCount': alertCount,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasAutomationRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasAutomationModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasAutomationModule.drone,
    );

    return AtlasAutomationRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      deviceOrResponsible: map['deviceOrResponsible']?.toString() ?? '',
      reference: map['reference']?.toString() ?? '',
      primaryValue: (map['primaryValue'] as num?)?.toDouble() ?? 0,
      secondaryValue: (map['secondaryValue'] as num?)?.toDouble() ?? 0,
      unit: map['unit']?.toString() ?? '',
      progressPercent: (map['progressPercent'] as num?)?.toInt() ?? 0,
      alertCount: (map['alertCount'] as num?)?.toInt() ?? 0,
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasAutomationDate(String value) {
  final iso = DateTime.tryParse(value.trim());
  if (iso != null) return iso;

  final parts = value.trim().split('/');
  if (parts.length != 3) return DateTime(1900);

  return DateTime(
    int.tryParse(parts[2]) ?? 1900,
    int.tryParse(parts[1]) ?? 1,
    int.tryParse(parts[0]) ?? 1,
  );
}

String formatAtlasAutomationDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
