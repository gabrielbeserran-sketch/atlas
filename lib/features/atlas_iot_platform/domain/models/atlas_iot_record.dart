enum AtlasIotModule {
  smartScales,
  rfidTags,
  smartCollars,
  environmentalSensors,
  waterSensors,
  energySensors,
  weatherStations,
  drones,
  satellites,
  iotCommandCenter,
}

extension AtlasIotModuleX on AtlasIotModule {
  String get code => switch (this) {
        AtlasIotModule.smartScales => 'smart_scales',
        AtlasIotModule.rfidTags => 'rfid_tags',
        AtlasIotModule.smartCollars => 'smart_collars',
        AtlasIotModule.environmentalSensors =>
          'environmental_sensors',
        AtlasIotModule.waterSensors => 'water_sensors',
        AtlasIotModule.energySensors => 'energy_sensors',
        AtlasIotModule.weatherStations => 'weather_stations',
        AtlasIotModule.drones => 'drones',
        AtlasIotModule.satellites => 'satellites',
        AtlasIotModule.iotCommandCenter => 'iot_command_center',
      };

  String get title => switch (this) {
        AtlasIotModule.smartScales =>
          'Integração com Balanças',
        AtlasIotModule.rfidTags =>
          'Brincos Eletrônicos RFID',
        AtlasIotModule.smartCollars =>
          'Colares Inteligentes',
        AtlasIotModule.environmentalSensors =>
          'Sensores Ambientais',
        AtlasIotModule.waterSensors =>
          'Sensores de Água',
        AtlasIotModule.energySensors =>
          'Sensores de Energia',
        AtlasIotModule.weatherStations =>
          'Estações Meteorológicas',
        AtlasIotModule.drones =>
          'Integração com Drones',
        AtlasIotModule.satellites =>
          'Integração com Satélites',
        AtlasIotModule.iotCommandCenter =>
          'Central IoT',
      };

  String get packageLabel => switch (this) {
        AtlasIotModule.smartScales => 'Pacote 121',
        AtlasIotModule.rfidTags => 'Pacote 122',
        AtlasIotModule.smartCollars => 'Pacote 123',
        AtlasIotModule.environmentalSensors => 'Pacote 124',
        AtlasIotModule.waterSensors => 'Pacote 125',
        AtlasIotModule.energySensors => 'Pacote 126',
        AtlasIotModule.weatherStations => 'Pacote 127',
        AtlasIotModule.drones => 'Pacote 128',
        AtlasIotModule.satellites => 'Pacote 129',
        AtlasIotModule.iotCommandCenter => 'Pacote 130',
      };

  List<String> get features => switch (this) {
        AtlasIotModule.smartScales => const [
            'Cadastro de balanças',
            'Leituras de peso',
            'Calibração',
            'Sincronização',
            'Alertas de inconsistência',
          ],
        AtlasIotModule.rfidTags => const [
            'Cadastro de brincos',
            'Associação com animais',
            'Leituras RFID',
            'Movimentações',
            'Perdas e substituições',
          ],
        AtlasIotModule.smartCollars => const [
            'Cadastro de colares',
            'Atividade animal',
            'Ruminação',
            'Localização',
            'Alertas comportamentais',
          ],
        AtlasIotModule.environmentalSensors => const [
            'Temperatura',
            'Umidade',
            'Qualidade do ar',
            'Conforto térmico',
            'Alertas ambientais',
          ],
        AtlasIotModule.waterSensors => const [
            'Nível de reservatórios',
            'Vazão',
            'Qualidade da água',
            'Consumo',
            'Alertas de abastecimento',
          ],
        AtlasIotModule.energySensors => const [
            'Consumo de energia',
            'Demanda',
            'Picos e anomalias',
            'Disponibilidade',
            'Alertas elétricos',
          ],
        AtlasIotModule.weatherStations => const [
            'Temperatura e umidade',
            'Chuva',
            'Vento',
            'Pressão',
            'Sincronização meteorológica',
          ],
        AtlasIotModule.drones => const [
            'Cadastro de aeronaves',
            'Planos de voo',
            'Imagens e vídeos',
            'Inspeções',
            'Alertas operacionais',
          ],
        AtlasIotModule.satellites => const [
            'Fontes de imagem',
            'Cobertura',
            'Índices espectrais',
            'Atualizações',
            'Alertas de mudança',
          ],
        AtlasIotModule.iotCommandCenter => const [
            'Dispositivos conectados',
            'Status em tempo real',
            'Eventos e alertas',
            'Saúde da rede',
            'Painel consolidado',
          ],
      };
}

class AtlasIotRecord {
  const AtlasIotRecord({
    required this.id,
    required this.module,
    required this.feature,
    required this.title,
    required this.date,
    required this.status,
    required this.deviceId,
    required this.location,
    required this.metricName,
    required this.metricValue,
    required this.unit,
    required this.signalPercent,
    required this.batteryPercent,
    required this.alertCount,
    required this.lastSync,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final AtlasIotModule module;
  final String feature;
  final String title;
  final String date;
  final String status;
  final String deviceId;
  final String location;
  final String metricName;
  final double metricValue;
  final String unit;
  final double signalPercent;
  final double batteryPercent;
  final int alertCount;
  final String lastSync;
  final String notes;
  final String createdAt;
  final String updatedAt;

  bool get isCritical =>
      status == 'Falha' ||
      status == 'Desconectado' ||
      status == 'Crítico' ||
      status == 'Atenção';

  bool get isOperational =>
      status == 'Ativo' ||
      status == 'Sincronizado' ||
      status == 'Monitorado' ||
      status == 'Concluído';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module.code,
      'feature': feature,
      'title': title,
      'date': date,
      'status': status,
      'deviceId': deviceId,
      'location': location,
      'metricName': metricName,
      'metricValue': metricValue,
      'unit': unit,
      'signalPercent': signalPercent,
      'batteryPercent': batteryPercent,
      'alertCount': alertCount,
      'lastSync': lastSync,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AtlasIotRecord.fromMap(Map<String, dynamic> map) {
    final code = map['module']?.toString() ?? '';
    final module = AtlasIotModule.values.firstWhere(
      (item) => item.code == code,
      orElse: () => AtlasIotModule.smartScales,
    );

    return AtlasIotRecord(
      id: map['id']?.toString() ?? '',
      module: module,
      feature: map['feature']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Planejado',
      deviceId: map['deviceId']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      metricName: map['metricName']?.toString() ?? '',
      metricValue:
          (map['metricValue'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit']?.toString() ?? '',
      signalPercent:
          (map['signalPercent'] as num?)?.toDouble() ?? 0.0,
      batteryPercent:
          (map['batteryPercent'] as num?)?.toDouble() ?? 0.0,
      alertCount:
          (map['alertCount'] as num?)?.toInt() ?? 0,
      lastSync: map['lastSync']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? '',
    );
  }
}

DateTime parseAtlasIotDate(String value) {
  final text = value.trim();
  if (text.isEmpty) return DateTime(1900);

  final iso = DateTime.tryParse(text);
  if (iso != null) return iso;

  final parts = text.split('/');
  if (parts.length != 3) return DateTime(1900);

  return DateTime(
    int.tryParse(parts[2]) ?? 1900,
    int.tryParse(parts[1]) ?? 1,
    int.tryParse(parts[0]) ?? 1,
  );
}

String formatAtlasIotDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
