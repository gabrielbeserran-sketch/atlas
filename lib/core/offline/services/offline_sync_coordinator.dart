import '../../network/atlas_http_client.dart';
import '../models/offline_operation.dart';
import 'offline_repository.dart';

class OfflineSyncReport { const OfflineSyncReport({required this.pushed, required this.conflicts, required this.pulled, required this.nextCursor}); final int pushed, conflicts, pulled, nextCursor; }

class OfflineSyncCoordinator {
  OfflineSyncCoordinator({AtlasHttpClient? client, OfflineRepository? repository}) : _client = client ?? AtlasHttpClient(), _repository = repository ?? OfflineRepository();
  final AtlasHttpClient _client;
  final OfflineRepository _repository;
  Future<OfflineSyncReport> synchronize({String? farmId}) async {
    int pushed = 0, conflicts = 0, pulled = 0;
    final List<OfflineOperation> operations = await _repository.pending();
    if (operations.isNotEmpty) {
      final response = await _client.send('POST', '/offline/push-batch', body: {'operations': operations.map((e) => e.toApi()).toList(), 'stop_on_conflict': false});
      final data = response.asMap();
      for (final raw in (data['results'] as List<dynamic>? ?? const [])) {
        final item = Map<String, dynamic>.from(raw as Map);
        final operation = operations.firstWhere((e) => e.id == item['operation_id']);
        if (item['accepted'] == true) { await _repository.markAccepted(operation.id); pushed++; }
        else if (item['conflict'] == true) { await _repository.saveConflict(operation: operation, remoteVersion: item['remote_version'] as int? ?? 0, remotePayload: Map<String, dynamic>.from(item['remote_payload'] as Map? ?? const {})); conflicts++; }
        else { await _repository.markFailed(operation.id, item['error']?.toString() ?? 'Falha de sincronização'); }
      }
    }
    int cursor = await _repository.getCursor(); bool hasMore;
    do {
      final response = await _client.send('GET', '/offline/pull-page', queryParameters: {'cursor': '$cursor', 'limit': '250', if (farmId != null && farmId.isNotEmpty) 'farm_id': farmId});
      final data = response.asMap();
      final changes = data['changes'] as List<dynamic>? ?? const [];
      for (final raw in changes) { await _repository.applyChange(Map<String, dynamic>.from(raw as Map)); pulled++; }
      cursor = data['next_cursor'] as int? ?? cursor; await _repository.setCursor(cursor); hasMore = data['has_more'] == true;
    } while (hasMore);
    return OfflineSyncReport(pushed: pushed, conflicts: conflicts, pulled: pulled, nextCursor: cursor);
  }
}
