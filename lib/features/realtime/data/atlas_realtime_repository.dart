
import 'dart:async';
import 'dart:convert';

import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AtlasRealtimeRepository {
  AtlasRealtimeRepository({
    AtlasHttpClient? client,
  }) : _client = client ?? AtlasHttpClient();

  final AtlasHttpClient _client;
  WebSocketChannel? _channel;

  Stream<Map<String, dynamic>> connect({
    required String baseWsUrl,
    required String companyId,
  }) {
    _channel?.sink.close();
    _channel = WebSocketChannel.connect(
      Uri.parse('$baseWsUrl/api/v1/realtime/ws/$companyId'),
    );

    return _channel!.stream.map(
      (event) => Map<String, dynamic>.from(
        jsonDecode(event.toString()) as Map,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> notifications({
    String? farmId,
    bool unreadOnly = false,
  }) async {
    final response = await _client.send(
      'GET',
      '/realtime/notifications',
      queryParameters: {
        if (farmId != null) 'farm_id': farmId,
        'unread_only': unreadOnly.toString(),
      },
    );
    return response.asMapList();
  }

  Future<void> markRead(String notificationId) async {
    await _client.send(
      'PATCH',
      '/realtime/notifications/$notificationId/read',
    );
  }

  Future<Map<String, dynamic>> metrics() async {
    final response = await _client.send(
      'GET',
      '/realtime/metrics',
    );
    return response.asMap();
  }

  void ping() {
    _channel?.sink.add(jsonEncode({'type': 'ping'}));
  }

  Future<void> close() async {
    await _channel?.sink.close();
    _channel = null;
  }
}
