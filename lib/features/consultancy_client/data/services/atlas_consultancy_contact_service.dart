import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/consultancy_client/domain/models/atlas_consultancy_contact_profile.dart';

class AtlasConsultancyContactService {
  AtlasConsultancyContactService({AtlasHttpClient? httpClient})
      : _http = httpClient ?? AtlasHttpClient();

  final AtlasHttpClient _http;

  Future<AtlasConsultancyContactProfile> loadForFarm(
    String farmId,
  ) async {
    final response = await _http.send(
      'GET',
      '/consultancy/contact',
      queryParameters: {'farm_id': farmId},
    );
    return AtlasConsultancyContactProfile.fromMap(response.asMap());
  }

  Future<AtlasConsultancyContactProfile> updateForFarm({
    required String farmId,
    required String displayName,
    required String role,
    required String whatsappNumber,
    required String companyLabel,
    required bool active,
  }) async {
    final response = await _http.send(
      'PATCH',
      '/consultancy/contact',
      queryParameters: {'farm_id': farmId},
      body: {
        'display_name': displayName.trim(),
        'role': role.trim(),
        'whatsapp_number': whatsappNumber.trim(),
        'company_label': companyLabel.trim(),
        'active': active,
      },
    );
    return AtlasConsultancyContactProfile.fromMap(response.asMap());
  }
}
