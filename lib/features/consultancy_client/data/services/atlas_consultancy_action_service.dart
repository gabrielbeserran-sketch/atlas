import 'package:projeto_atlas/features/consultancy_client/domain/models/atlas_consultancy_action.dart';
import 'package:projeto_atlas/features/dashboard/domain/models/atlas_operational_intelligence_data.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class AtlasConsultancyActionService {
  AtlasConsultancyActionService({AtlasEnterpriseApiClient? api})
      : _api = api ?? AtlasEnterpriseApiClient.instance;

  final AtlasEnterpriseApiClient _api;

  Future<List<AtlasConsultancyAction>> load(String farmId) async {
    final response = await _api.requestList(
      'GET',
      '/business/consulting/actions',
      queryParameters: {'farm_id': farmId},
    );
    return response
        .map(AtlasConsultancyAction.fromMap)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> loadOutcomes(String farmId) async {
    await _api.request(
      'POST',
      '/business/consulting/actions/reconcile-outcomes',
      queryParameters: {'farm_id': farmId},
    );
    return _api.request(
      'GET',
      '/business/consulting/actions/outcomes',
      queryParameters: {'farm_id': farmId},
    );
  }

  Future<AtlasConsultancyAction> createFromPriority({
    required String farmId,
    required AtlasOperationalActionData priority,
    required DateTime? generatedAt,
  }) async {
    final stableSource = priority.entityId.trim().isNotEmpty
        ? '${priority.entityType}:${priority.entityId}'
        : '${priority.area}:${priority.title}';
    final cycle = priority.dueAt ?? generatedAt ?? DateTime.now();
    final cycleKey = '${cycle.year.toString().padLeft(4, '0')}-'
        '${cycle.month.toString().padLeft(2, '0')}-'
        '${cycle.day.toString().padLeft(2, '0')}';
    final idempotencyKey = 'operational:$stableSource:$cycleKey';

    final response = await _api.request(
      'POST',
      '/business/consulting/actions',
      body: {
        'farm_id': farmId,
        'title': priority.title,
        'description': priority.recommendedAction,
        'area': priority.area,
        'priority': _priority(priority.severity),
        'due_at': priority.dueAt?.toUtc().toIso8601String(),
        'expected_result': priority.recommendedAction,
        'source_entity_type': priority.entityType,
        'source_entity_id': priority.entityId,
        'idempotency_key': idempotencyKey,
      },
    );
    return AtlasConsultancyAction.fromMap(response);
  }

  Future<AtlasConsultancyAction> complete({
    required String actionId,
    required String actualResult,
    required String sourceModule,
    List<String> evidence = const <String>[],
  }) async {
    final response = await _api.request(
      'PATCH',
      '/business/consulting/actions/$actionId/complete',
      body: {
        'actual_result': actualResult.trim(),
        'source_module': sourceModule.trim(),
        'evidence': evidence.where((item) => item.trim().isNotEmpty).toList(),
      },
    );
    return AtlasConsultancyAction.fromMap(response);
  }

  String _priority(String severity) {
    switch (severity.trim().toLowerCase()) {
      case 'critical':
        return 'critical';
      case 'high':
        return 'high';
      case 'low':
        return 'low';
      default:
        return 'medium';
    }
  }
}
