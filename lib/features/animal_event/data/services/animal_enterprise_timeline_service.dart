import 'package:projeto_atlas/features/animal_event/domain/models/animal_enterprise_history_data.dart';
import 'package:projeto_atlas/features/animal_event/domain/models/animal_enterprise_timeline_data.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';

class AnimalEnterpriseTimelineService {
  AnimalEnterpriseTimelineService({
    AtlasEnterpriseApiClient? api,
  }) : _api = api ?? AtlasEnterpriseApiClient.instance;

  final AtlasEnterpriseApiClient _api;

  Future<List<AnimalEnterpriseTimelineData>> loadTimeline(
    String animalId,
  ) async {
    final response = await _api.requestList(
      'GET',
      '/animals/$animalId/timeline',
    );

    return response
        .map(AnimalEnterpriseTimelineData.fromMap)
        .toList(growable: false);
  }

  Future<List<AnimalEnterpriseHistoryData>> loadHistory(
    String animalId,
  ) async {
    final response = await _api.requestList(
      'GET',
      '/animals/$animalId/history',
    );

    return response
        .map(AnimalEnterpriseHistoryData.fromMap)
        .toList(growable: false);
  }
}
