import '../../../../core/network/atlas_http_client.dart';
import '../../domain/models/atlas_sprints_dashboard_data.dart';
class AtlasSprintsService {
  AtlasSprintsService({AtlasHttpClient? client}):_client=client??AtlasHttpClient();
  final AtlasHttpClient _client;
  Future<AtlasSprintsDashboardData> dashboard(String farmId) async { final r=await _client.send('GET','/sprints/dashboard',queryParameters:{'farm_id':farmId}); return AtlasSprintsDashboardData.fromJson(r.asMap()); }
  Future<Map<String,dynamic>> brainContext(String farmId) async => (await _client.send('GET','/sprints/brain/farms/$farmId/context')).asMap();
  Future<Map<String,dynamic>> weeklyPlan(String farmId) async => (await _client.send('POST','/sprints/brain/farms/$farmId/weekly-plan')).asMap();
  Future<Map<String,dynamic>> iotDashboard(String farmId) async => (await _client.send('GET','/sprints/iot/farms/$farmId/dashboard')).asMap();
  Future<Map<String,dynamic>> cloudReadiness() async => (await _client.send('GET','/sprints/cloud/readiness')).asMap();
  Future<Map<String,dynamic>> webDashboard({String? farmId}) async => (await _client.send('GET','/sprints/web/dashboard',queryParameters:{if(farmId!=null&&farmId.isNotEmpty)'farm_id':farmId})).asMap();
}
