import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/paddock/domain/models/paddock_data.dart';

/// Repositório oficial de piquetes. A autoridade é o backend Atlas.
class PaddockStorageService {
  PaddockStorageService({AtlasEnterpriseApiClient? api})
    : _api = api ?? AtlasEnterpriseApiClient.instance;

  final AtlasEnterpriseApiClient _api;

  Future<List<PaddockData>> loadPaddocks(String farmId) async {
    if (farmId.trim().isEmpty) {
      return const [];
    }
    final rows = await _api.requestList(
      'GET',
      '/livestock/paddocks?farm_id=${Uri.encodeQueryComponent(farmId)}',
    );
    return rows.map(PaddockData.fromMap).toList(growable: false);
  }

  Future<PaddockData> createPaddock({
    required String farmId,
    required PaddockData paddock,
  }) async {
    final row = await _api.request(
      'POST',
      '/livestock/paddocks',
      body: {
        'farm_id': farmId,
        'name': paddock.name,
        'area': paddock.area,
        'status': paddock.status,
        'animals': paddock.animals,
        'notes': paddock.notes,
      },
    );
    final created = PaddockData.fromMap(row);
    return _verifyPaddock(farmId: farmId, paddockId: created.id);
  }

  Future<PaddockData> updatePaddock({
    required String farmId,
    required PaddockData paddock,
  }) async {
    await _api.request(
      'PATCH',
      '/livestock/paddocks/${paddock.id}',
      body: {
        'name': paddock.name,
        'area': paddock.area,
        'status': paddock.status,
        'animals': paddock.animals,
        'notes': paddock.notes,
      },
    );
    return _verifyPaddock(farmId: farmId, paddockId: paddock.id);
  }

  Future<void> deletePaddock({
    required String farmId,
    required String id,
  }) async {
    await _api.request('DELETE', '/livestock/paddocks/$id');
    final remaining = await loadPaddocks(farmId);
    if (remaining.any((item) => item.id == id)) {
      throw StateError(
        'A exclusão do piquete não foi confirmada pelo servidor.',
      );
    }
  }

  Future<PaddockData> _verifyPaddock({
    required String farmId,
    required String paddockId,
  }) async {
    final paddocks = await loadPaddocks(farmId);
    for (final paddock in paddocks) {
      if (paddock.id == paddockId) {
        return paddock;
      }
    }
    throw StateError(
      'O piquete não foi confirmado após nova leitura do servidor.',
    );
  }
}
