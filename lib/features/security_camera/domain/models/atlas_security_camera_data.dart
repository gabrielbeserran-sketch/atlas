class AtlasSecurityCameraStatus {
  const AtlasSecurityCameraStatus({
    required this.deviceId,
    required this.deviceExternalId,
    required this.deviceName,
    required this.enabled,
    required this.recipientWhatsapp,
    required this.whatsappOptInConfirmed,
    required this.allowedEventTypes,
    required this.providerReady,
    required this.ready,
    required this.cooldownSeconds,
  });

  final String deviceId;
  final String deviceExternalId;
  final String deviceName;
  final bool enabled;
  final String recipientWhatsapp;
  final bool whatsappOptInConfirmed;
  final List<String> allowedEventTypes;
  final bool providerReady;
  final bool ready;
  final int cooldownSeconds;

  factory AtlasSecurityCameraStatus.fromMap(Map<String, dynamic> map) {
    return AtlasSecurityCameraStatus(
      deviceId: map['device_id']?.toString() ?? '',
      deviceExternalId:
          map['device_external_id']?.toString() ?? '',
      deviceName: map['device_name']?.toString() ?? 'Câmera da entrada',
      enabled: map['enabled'] == true,
      recipientWhatsapp:
          map['recipient_whatsapp']?.toString() ?? '',
      whatsappOptInConfirmed:
          map['whatsapp_opt_in_confirmed'] == true,
      allowedEventTypes: (map['allowed_event_types'] as List?)
              ?.map((item) => item.toString())
              .toList(growable: false) ??
          const <String>[],
      providerReady: map['provider_ready'] == true,
      ready: map['ready'] == true,
      cooldownSeconds:
          (map['cooldown_seconds'] as num?)?.toInt() ?? 60,
    );
  }

  bool get personEnabled => allowedEventTypes.contains('person');
  bool get vehicleEnabled => allowedEventTypes.contains('vehicle');
}

class AtlasSecurityCameraEvent {
  const AtlasSecurityCameraEvent({
    required this.id,
    required this.deviceId,
    required this.eventType,
    required this.capturedAt,
    required this.alertStatus,
    required this.attemptCount,
    required this.errorMessage,
  });

  final String id;
  final String deviceId;
  final String eventType;
  final DateTime? capturedAt;
  final String alertStatus;
  final int attemptCount;
  final String errorMessage;

  factory AtlasSecurityCameraEvent.fromMap(Map<String, dynamic> map) {
    return AtlasSecurityCameraEvent(
      id: map['id']?.toString() ?? '',
      deviceId: map['device_id']?.toString() ?? '',
      eventType: map['event_type']?.toString() ?? '',
      capturedAt: DateTime.tryParse(
        map['captured_at']?.toString() ?? '',
      )?.toLocal(),
      alertStatus: map['alert_status']?.toString() ?? '',
      attemptCount: (map['attempt_count'] as num?)?.toInt() ?? 0,
      errorMessage: map['error_message']?.toString() ?? '',
    );
  }

  bool get canRetry => !{
        'provider_accepted',
        'delivered',
        'read',
        'ignored_event_type',
        'suppressed_cooldown',
      }.contains(alertStatus);
}
