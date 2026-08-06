enum AtlasEcosystemModule {
  sustainability,
  iot,
  consultancy,
}

extension AtlasEcosystemModuleX on AtlasEcosystemModule {
  String get code => switch (this) {
        AtlasEcosystemModule.sustainability => 'sustainability',
        AtlasEcosystemModule.iot => 'iot',
        AtlasEcosystemModule.consultancy => 'consultancy',
      };

  String get title => switch (this) {
        AtlasEcosystemModule.sustainability =>
          'Sustentabilidade Enterprise',
        AtlasEcosystemModule.iot => 'IoT e Automação',
        AtlasEcosystemModule.consultancy =>
          'Ecossistema de Consultoria',
      };

  String get packageLabel => switch (this) {
        AtlasEcosystemModule.sustainability => 'Pacote 47',
        AtlasEcosystemModule.iot => 'Pacote 48',
        AtlasEcosystemModule.consultancy => 'Pacote 49',
      };

  List<String> get features => switch (this) {
        AtlasEcosystemModule.sustainability => const [
            'Pegada de carbono',
            'Uso da água',
            'Indicadores ESG',
            'Recuperação de pastagens',
            'Relatórios ambientais',
          ],
        AtlasEcosystemModule.iot => const [
            'Integração com balanças eletrônicas',
            'Integração com brincos eletrônicos (RFID)',
            'Sensores de temperatura e umidade',
            'Coleta automática de dados',
            'Central de dispositivos conectados',
          ],
        AtlasEcosystemModule.consultancy => const [
            'Gestão de clientes da consultoria',
            'Agenda de visitas técnicas',
            'Relatórios por cliente',
            'Indicadores comparativos entre clientes',
            'Portal do cliente',
          ],
      };
}

class AtlasEcosystemRecord {
  const AtlasEcosystemRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.primaryValue,
    required this.secondaryValue,
    required this.unit,
    required this.responsible,
    required this.reference,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasEcosystemModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final double primaryValue;
  final double secondaryValue;
  final String unit;
  final String responsible;
  final String reference;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Crítico' ||
      status == 'Atenção' ||
      status == 'Desconectado';

  bool get isCompleted =>
      status == 'Concluído' ||
      status == 'Ativo' ||
      status == 'Conectado';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'primaryValue': primaryValue,
      'secondaryValue': secondaryValue,
      'unit': unit,
      'responsible': responsible,
      'reference': reference,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasEcosystemRecord.fromMap(
    Map<String, dynamic> map,
  ) {
    final code = map['module']?.toString() ?? '';

    final module = AtlasEcosystemModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasEcosystemModule.sustainability,
    );

    return AtlasEcosystemRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      primaryValue:
          (map['primaryValue'] as num?)?.toDouble() ?? 0,
      secondaryValue:
          (map['secondaryValue'] as num?)?.toDouble() ?? 0,
      unit: map['unit']?.toString() ?? '',
      responsible: map['responsible']?.toString() ?? '',
      reference: map['reference']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasEcosystemDate(String value) {
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

String formatAtlasEcosystemDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
