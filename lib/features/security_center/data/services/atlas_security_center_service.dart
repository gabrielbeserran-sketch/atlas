import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/security_center/domain/models/atlas_security_snapshot.dart';

class AtlasSecurityCenterService {
  AtlasSecurityCenterService({AtlasHttpClient? client})
    : _client = client ?? AtlasHttpClient();
  final AtlasHttpClient _client;

  Future<AtlasSecuritySnapshot> load() async {
    final dashboard = await _client.send(
      'GET',
      '/security-compliance/dashboard',
    );
    final audit = await _client.send(
      'GET',
      '/security-compliance/audit/verify',
    );
    return AtlasSecuritySnapshot.fromMaps(dashboard.asMap(), audit.asMap());
  }

  Future<Map<String, dynamic>> create(
    String path,
    String code,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.send(
      'POST',
      path,
      body: {'code': code, 'name': code, 'data': data},
    );
    return response.asMap();
  }
}
