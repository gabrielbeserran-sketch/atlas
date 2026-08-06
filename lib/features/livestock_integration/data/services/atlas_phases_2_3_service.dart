import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/livestock_integration/domain/models/atlas_phases_2_3_data.dart';

class AtlasPhases23Service {
  AtlasPhases23Service({AtlasHttpClient? httpClient})
      : _http = httpClient ?? AtlasHttpClient();

  final AtlasHttpClient _http;

  Future<List<AtlasInventoryAlertData>> loadInventoryAlerts({
    required String farmId,
    int expiryDays = 30,
  }) async {
    final response = await _http.send(
      'GET',
      '/livestock/inventory/alerts',
      queryParameters: <String, String>{
        'farm_id': farmId,
        'expiry_days': '$expiryDays',
      },
    );
    return response
        .asMapList()
        .map(AtlasInventoryAlertData.fromMap)
        .toList();
  }

  Future<AtlasNutritionPerformanceData> loadNutritionPerformance({
    required String farmId,
    String? lotId,
  }) async {
    final response = await _http.send(
      'GET',
      '/livestock/nutrition/performance',
      queryParameters: <String, String>{
        'farm_id': farmId,
        if (lotId != null && lotId.trim().isNotEmpty) 'lot_id': lotId.trim(),
      },
    );
    return AtlasNutritionPerformanceData.fromMap(response.asMap());
  }

  Future<AtlasFinancialSummaryData> loadFinancialSummary({
    required String farmId,
  }) async {
    final response = await _http.send(
      'GET',
      '/livestock/finance/summary',
      queryParameters: <String, String>{'farm_id': farmId},
    );
    return AtlasFinancialSummaryData.fromMap(response.asMap());
  }

  Future<Map<String, dynamic>> registerNutritionConsumption({
    required String lotId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _http.send(
      'POST',
      '/livestock/nutrition/lots/$lotId/consumption',
      body: payload,
    );
    return response.asMap();
  }

  Future<Map<String, dynamic>> createFinancialEntry(
    Map<String, dynamic> payload,
  ) async {
    final response = await _http.send(
      'POST',
      '/livestock/finance/v2',
      body: payload,
    );
    return response.asMap();
  }
}
