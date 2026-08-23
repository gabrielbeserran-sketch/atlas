import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/security_camera/domain/models/atlas_security_camera_data.dart';

class AtlasSecurityCameraService {
  AtlasSecurityCameraService({AtlasHttpClient? client})
      : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;

  Future<List<AtlasSecurityCameraStatus>> loadCameras(
    String farmId,
  ) async {
    final response = await _client.send(
      'GET',
      '/security-camera/readiness',
      queryParameters: {'farm_id': farmId},
    );
    final cameras = response.asMap()['cameras'];
    if (cameras is! List) return const [];
    return cameras
        .whereType<Map>()
        .map(
          (item) => AtlasSecurityCameraStatus.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList(growable: false);
  }

  Future<List<AtlasSecurityCameraEvent>> loadEvents(
    String farmId,
  ) async {
    final response = await _client.send(
      'GET',
      '/security-camera/events',
      queryParameters: {
        'farm_id': farmId,
        'limit': '20',
      },
    );
    return response
        .asMapList()
        .map(AtlasSecurityCameraEvent.fromMap)
        .toList(growable: false);
  }

  Future<void> createEntranceCamera({
    required String farmId,
    required String name,
    required String externalId,
  }) async {
    await _client.send(
      'POST',
      '/security-camera/devices',
      queryParameters: {'farm_id': farmId},
      body: {
        'name': name,
        'external_id': externalId,
      },
    );
  }

  Future<AtlasSecurityCameraStatus> configure({
    required String deviceId,
    required String recipientWhatsapp,
    required bool whatsappOptInConfirmed,
    required bool enabled,
    required bool personEnabled,
    required bool vehicleEnabled,
    required int cooldownSeconds,
  }) async {
    final eventTypes = <String>[
      if (personEnabled) 'person',
      if (vehicleEnabled) 'vehicle',
    ];
    final response = await _client.send(
      'PATCH',
      '/security-camera/devices/$deviceId/alert-config',
      body: {
        'recipient_whatsapp': recipientWhatsapp,
        'whatsapp_opt_in_confirmed': whatsappOptInConfirmed,
        'security_alert_enabled': enabled,
        'allowed_event_types': eventTypes,
        'cooldown_seconds': cooldownSeconds,
      },
    );
    return AtlasSecurityCameraStatus.fromMap(response.asMap());
  }

  Future<AtlasSecurityCameraEvent> retry(String eventId) async {
    final response = await _client.send(
      'POST',
      '/security-camera/events/$eventId/retry',
    );
    return AtlasSecurityCameraEvent.fromMap(response.asMap());
  }
}
