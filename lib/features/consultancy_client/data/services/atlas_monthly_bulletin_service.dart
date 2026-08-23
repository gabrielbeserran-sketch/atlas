import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/features/consultancy_client/domain/models/atlas_monthly_bulletin_data.dart';

class AtlasMonthlyBulletinService {
  AtlasMonthlyBulletinService({AtlasHttpClient? httpClient})
      : _http = httpClient ?? AtlasHttpClient();

  final AtlasHttpClient _http;

  Future<AtlasBulletinProviderStatus> providerStatus() async {
    final response = await _http.send(
      'GET',
      '/bulletins/provider-status',
    );
    return AtlasBulletinProviderStatus.fromMap(response.asMap());
  }

  Future<List<AtlasMonthlyBulletinSchedule>> loadSchedules(
    String farmId,
  ) async {
    final response = await _http.send(
      'GET',
      '/bulletins/schedules',
      queryParameters: {'farm_id': farmId},
    );
    return response
        .asMapList()
        .map(AtlasMonthlyBulletinSchedule.fromMap)
        .toList(growable: false);
  }

  Future<AtlasMonthlyBulletinSchedule> updateSchedule({
    required String farmId,
    required String bulletinType,
    required String recipientWhatsapp,
    required bool whatsappOptInConfirmed,
    required bool enabled,
    required int dayOfMonth,
    required int hour,
    required int minute,
  }) async {
    final response = await _http.send(
      'PATCH',
      '/bulletins/schedules/$bulletinType',
      queryParameters: {'farm_id': farmId},
      body: {
        'recipient_whatsapp': recipientWhatsapp,
        'whatsapp_opt_in_confirmed': whatsappOptInConfirmed,
        'enabled': enabled,
        'day_of_month': dayOfMonth,
        'hour': hour,
        'minute': minute,
        'timezone_name': 'America/Sao_Paulo',
      },
    );
    return AtlasMonthlyBulletinSchedule.fromMap(response.asMap());
  }

  Future<AtlasBulletinPreview> preview({
    required String farmId,
    required String bulletinType,
  }) async {
    final response = await _http.send(
      'GET',
      '/bulletins/preview/$bulletinType',
      queryParameters: {'farm_id': farmId},
    );
    return AtlasBulletinPreview.fromMap(response.asMap());
  }
}
