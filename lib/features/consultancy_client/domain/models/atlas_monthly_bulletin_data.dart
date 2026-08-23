class AtlasMonthlyBulletinSchedule {
  const AtlasMonthlyBulletinSchedule({
    required this.id,
    required this.farmId,
    required this.bulletinType,
    required this.label,
    required this.recipientWhatsapp,
    required this.whatsappOptInConfirmed,
    required this.enabled,
    required this.dayOfMonth,
    required this.hour,
    required this.minute,
    required this.timezoneName,
    required this.lastRunAt,
    required this.nextRunAt,
  });

  final String id;
  final String farmId;
  final String bulletinType;
  final String label;
  final String recipientWhatsapp;
  final bool whatsappOptInConfirmed;
  final bool enabled;
  final int dayOfMonth;
  final int hour;
  final int minute;
  final String timezoneName;
  final DateTime? lastRunAt;
  final DateTime? nextRunAt;

  factory AtlasMonthlyBulletinSchedule.fromMap(Map<String, dynamic> map) {
    return AtlasMonthlyBulletinSchedule(
      id: map['id']?.toString() ?? '',
      farmId: map['farm_id']?.toString() ?? '',
      bulletinType: map['bulletin_type']?.toString() ?? '',
      label: map['label']?.toString() ?? 'Boletim',
      recipientWhatsapp:
          map['recipient_whatsapp']?.toString() ?? '',
      whatsappOptInConfirmed:
          map['whatsapp_opt_in_confirmed'] == true,
      enabled: map['enabled'] == true,
      dayOfMonth: (map['day_of_month'] as num?)?.toInt() ?? 1,
      hour: (map['hour'] as num?)?.toInt() ?? 8,
      minute: (map['minute'] as num?)?.toInt() ?? 0,
      timezoneName:
          map['timezone_name']?.toString() ?? 'America/Sao_Paulo',
      lastRunAt: DateTime.tryParse(
        map['last_run_at']?.toString() ?? '',
      )?.toLocal(),
      nextRunAt: DateTime.tryParse(
        map['next_run_at']?.toString() ?? '',
      )?.toLocal(),
    );
  }
}

class AtlasBulletinProviderStatus {
  const AtlasBulletinProviderStatus({
    required this.provider,
    required this.automaticDeliveryEnabled,
    required this.schedulerEnabled,
    required this.configurationRequired,
  });

  final String provider;
  final bool automaticDeliveryEnabled;
  final bool schedulerEnabled;
  final bool configurationRequired;

  factory AtlasBulletinProviderStatus.fromMap(
    Map<String, dynamic> map,
  ) {
    return AtlasBulletinProviderStatus(
      provider: map['provider']?.toString() ?? 'meta_cloud',
      automaticDeliveryEnabled:
          map['automatic_delivery_enabled'] == true,
      schedulerEnabled: map['scheduler_enabled'] == true,
      configurationRequired:
          map['configuration_required'] == true,
    );
  }
}

class AtlasBulletinPreview {
  const AtlasBulletinPreview({
    required this.bulletinType,
    required this.label,
    required this.content,
  });

  final String bulletinType;
  final String label;
  final String content;

  factory AtlasBulletinPreview.fromMap(Map<String, dynamic> map) {
    return AtlasBulletinPreview(
      bulletinType: map['bulletin_type']?.toString() ?? '',
      label: map['label']?.toString() ?? 'Boletim',
      content: map['content']?.toString() ?? '',
    );
  }
}
