import 'package:projeto_atlas/features/atlas_intelligence_center/domain/models/atlas_intelligence_models.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class AtlasIntelligenceService {
  AtlasIntelligenceService({AtlasEnterpriseApiClient? api})
    : _api = api ?? AtlasEnterpriseApiClient.instance;
  final AtlasEnterpriseApiClient _api;

  Future<Map<String, dynamic>> buildContext(String farmId) =>
      _api.request('POST', '/ai-operational/farms/$farmId/context');

  Future<List<AtlasAiRecommendation>> recommendations(String farmId) async {
    final data = await _api.request(
      'POST',
      '/ai-operational/farms/$farmId/recommendations',
    );
    final items = data['recommendations'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map(
          (item) =>
              AtlasAiRecommendation.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  Future<void> decide(String recommendationId, String decision) async {
    await _api.request(
      'POST',
      '/ai-operational/recommendations/$recommendationId/decision',
      body: {'decision': decision, 'result': <String, dynamic>{}},
    );
  }

  Future<AtlasAiSimulation> simulate(
    String farmId, {
    required double saleAmount,
    required double extraCost,
    required double investment,
    required double expectedReturn,
  }) async {
    final data = await _api.request(
      'POST',
      '/ai-operational/farms/$farmId/simulate',
      body: {
        'sale_amount': saleAmount,
        'extra_cost': extraCost,
        'investment': investment,
        'expected_return': expectedReturn,
      },
    );
    return AtlasAiSimulation.fromMap(data);
  }

  Future<void> remember(
    String farmId, {
    required String area,
    required String title,
    required String summary,
  }) async {
    await _api.request(
      'POST',
      '/ai-operational/farms/$farmId/memory',
      body: {
        'area': area,
        'title': title,
        'summary': summary,
        'evidence': <dynamic>[],
        'decision': <String, dynamic>{},
        'result': <String, dynamic>{},
        'confidence': 0.7,
      },
    );
  }

  Future<Map<String, dynamic>> createAutomation(
    String farmId, {
    String? recommendationId,
    required String actionType,
    required Map<String, dynamic> payload,
  }) => _api.request(
    'POST',
    '/ai-operational/farms/$farmId/automations',
    body: {
      'recommendation_id': recommendationId,
      'action_type': actionType,
      'payload': payload,
      'requires_approval': true,
      'financial_limit': 0,
    },
  );
}
