import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/platform_v1/domain/models/atlas_platform_dashboard_data.dart';

class AtlasPlatformService {
  AtlasPlatformService({AtlasHttpClient? httpClient}):_http=httpClient??AtlasHttpClient();
  final AtlasHttpClient _http;
  Future<AtlasPlatformDashboardData> loadFarmDashboard(String farmId) async => AtlasPlatformDashboardData.fromMap((await _http.send('GET','/platform/dashboard/farms/$farmId')).asMap());
  Future<Map<String,dynamic>> loadCompanyDashboard() async => (await _http.send('GET','/platform/dashboard/company')).asMap();
  Future<Map<String,dynamic>> loadAiContext(String farmId) async => (await _http.send('GET','/platform/ai/context/farms/$farmId')).asMap();
  Future<Map<String,dynamic>> loadSecurityReadiness(String farmId) async => (await _http.send('GET','/platform/security/readiness/farms/$farmId')).asMap();
  Future<Map<String,dynamic>> loadProductionReadiness() async => (await _http.send('GET','/platform/production/readiness')).asMap();
  Future<Map<String,dynamic>> bootstrapAutomations(String farmId) async => (await _http.send('POST','/platform/automations/farms/$farmId/bootstrap')).asMap();
  Future<Map<String,dynamic>> evaluateAutomations(String farmId,{bool dryRun=true}) async => (await _http.send('POST','/platform/automations/farms/$farmId/evaluate',body:{'dry_run':dryRun,'execute_actions':!dryRun})).asMap();
  Future<Map<String,dynamic>> decideRecommendation(String id,String decision,{String notes=''}) async => (await _http.send('POST','/platform/ai/recommendations/$id/decision',body:{'decision':decision,'notes':notes})).asMap();
}
