
import 'package:projeto_atlas/core/network/atlas_http_client.dart';

class AtlasIotRepository {
  AtlasIotRepository({
    AtlasHttpClient? client,
  }) : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;

  Future<List<Map<String, dynamic>>> gateways(
    String farmId,
  ) async {
    final response = await _client.send(
      'GET',
      '/iot/gateways',
      queryParameters: {'farm_id': farmId},
    );
    return response.asMapList();
  }

  Future<List<Map<String, dynamic>>> devices(
    String farmId, {
    String? deviceType,
    String? status,
  }) async {
    final response = await _client.send(
      'GET',
      '/iot/devices',
      queryParameters: {
        'farm_id': farmId,
        if (deviceType != null) 'device_type': deviceType,
        if (status != null) 'status': status,
      },
    );
    return response.asMapList();
  }

  Future<Map<String, dynamic>> dashboard(
    String farmId,
  ) async {
    final response = await _client.send(
      'GET',
      '/iot/dashboard',
      queryParameters: {'farm_id': farmId},
    );
    return response.asMap();
  }

  Future<List<Map<String, dynamic>>> telemetry({
    required String deviceId,
    String? metricKey,
  }) async {
    final response = await _client.send(
      'GET',
      '/iot/telemetry',
      queryParameters: {
        'device_id': deviceId,
        if (metricKey != null) 'metric_key': metricKey,
      },
    );
    return response.asMapList();
  }

  Future<Map<String, dynamic>> sendCommand({
    required String deviceId,
    required String commandType,
    Map<String, dynamic> payload = const {},
  }) async {
    final response = await _client.send(
      'POST',
      '/iot/devices/$deviceId/commands',
      body: {
        'command_type': commandType,
        'payload': payload,
      },
    );
    return response.asMap();
  }
}
