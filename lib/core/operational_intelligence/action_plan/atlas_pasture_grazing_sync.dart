import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'atlas_pasture_grazing_basis_service.dart';

abstract class AtlasGrazingRemote {
  Future<bool> supports(String farmId);
  Future<List<Map<String, dynamic>>> history(
    String farmId,
    int offset,
    int limit,
  );
  Future<Map<String, dynamic>> upload(AtlasPastureGrazingBasis basis);
}

class AtlasGrazingApiRemote implements AtlasGrazingRemote {
  String _path(String farmId) =>
      '/livestock/farms/${Uri.encodeComponent(farmId)}/grazing-basis';
  final _api = AtlasEnterpriseApiClient.instance;

  @override
  Future<bool> supports(String farmId) async {
    final data = await _api.request('GET', '${_path(farmId)}/capabilities');
    return data['client_operation_id_idempotency'] == true &&
        data['append_only'] == true;
  }

  @override
  Future<List<Map<String, dynamic>>> history(
    String farmId,
    int offset,
    int limit,
  ) => _api.requestList(
    'GET',
    _path(farmId),
    queryParameters: {'offset': '$offset', 'limit': '$limit'},
  );

  @override
  Future<Map<String, dynamic>> upload(AtlasPastureGrazingBasis basis) =>
      _api.request(
        'POST',
        _path(basis.farmId),
        body: {
          'client_operation_id': basis.operationId,
          'effective_area_ha': basis.effectiveAreaHa,
          'grazing_animals': basis.grazingAnimals,
          'unique_area_confirmed': basis.uniqueAreaConfirmed,
          'recorded_at': basis.recordedAt.toUtc().toIso8601String(),
        },
      );
}

class AtlasGrazingSyncResult {
  const AtlasGrazingSyncResult(
    this.message, {
    this.received = 0,
    this.sent = 0,
  });
  final String message;
  final int received;
  final int sent;
}

/// Comando explícito: nunca condiciona abertura ou gravação local à rede.
class AtlasPastureGrazingSync {
  AtlasPastureGrazingSync({
    AtlasGrazingRemote? remote,
    AtlasPastureGrazingBasisService? local,
    SharedPreferencesAsync? preferences,
    this.pageSize = 100,
  }) : remote = remote ?? AtlasGrazingApiRemote(),
       local = local ?? AtlasPastureGrazingBasisService(),
       preferences = preferences ?? SharedPreferencesAsync();

  final AtlasGrazingRemote remote;
  final AtlasPastureGrazingBasisService local;
  final SharedPreferencesAsync preferences;
  final int pageSize;
  bool _running = false;

  String _conflictKey(String tenant, String company, String farm) =>
      'atlas_grazing_conflicts_v1_${base64Url.encode(utf8.encode(jsonEncode([tenant, company, farm])))}';

  Future<List<Map<String, dynamic>>> conflicts(
    String tenant,
    String company,
    String farm,
  ) async {
    final raw = await preferences.getString(
      _conflictKey(tenant, company, farm),
    );
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  AtlasPastureGrazingBasis _decode(
    Map<String, dynamic> data,
    String tenant,
    String company,
    String farm,
  ) {
    final date = data['recorded_at']?.toString() ?? '';
    if (!RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(date) ||
        data['grazing_animals'] is! int ||
        data['client_operation_id'] is! String) {
      throw const FormatException('Resposta de pastejo incompleta.');
    }
    final basis = AtlasPastureGrazingBasis.fromMap({
      'operationId': data['client_operation_id'],
      'tenantId': data['tenant_id'],
      'companyId': data['company_id'],
      'farmId': data['farm_id'],
      'effectiveAreaHa': data['effective_area_ha'],
      'grazingAnimals': data['grazing_animals'],
      'uniqueAreaConfirmed': data['unique_area_confirmed'],
      'recordedAt': date,
    });
    basis.validate();
    if (basis.tenantId != tenant ||
        basis.companyId != company ||
        basis.farmId != farm) {
      throw const FormatException('Resposta de outra empresa ou fazenda.');
    }
    return basis;
  }

  Future<AtlasGrazingSyncResult> synchronize({
    required String tenantId,
    required String companyId,
    required String farmId,
    required Future<bool> Function() isAuthorized,
  }) async {
    if (_running) {
      return const AtlasGrazingSyncResult('Sincronização já em andamento.');
    }
    _running = true;
    var sent = 0;
    var received = 0;
    Future<void> guard() async {
      if (!await isAuthorized()) throw StateError('Contexto da fazenda mudou.');
    }

    try {
      await guard();
      final existing = await local.loadHistory(
        tenantId: tenantId,
        companyId: companyId,
        farmId: farmId,
        strict: true,
      );
      if (!await remote.supports(farmId)) {
        return const AtlasGrazingSyncResult(
          'Servidor ainda não habilitou a sincronização. Dados locais preservados.',
        );
      }
      final records = <String, AtlasPastureGrazingBasis>{};
      var complete = false;
      for (var page = 0; page < 20; page++) {
        await guard();
        final items = await remote.history(farmId, page * pageSize, pageSize);
        await guard();
        for (final item in items) {
          final record = _decode(item, tenantId, companyId, farmId);
          final duplicate = records[record.operationId];
          if (duplicate != null && !duplicate.hasSameData(record)) {
            throw StateError('Histórico remoto divergente.');
          }
          records[record.operationId] = record;
        }
        if (items.length < pageSize) {
          complete = true;
          break;
        }
      }
      if (!complete) {
        throw StateError('Histórico remoto exige revisão de paginação.');
      }
      final conflictsFound = <Map<String, dynamic>>[];
      for (final record in existing) {
        final other = records[record.operationId];
        if (other != null && !record.hasSameData(other)) {
          conflictsFound.add({
            'local': record.toMap(),
            'remote': other.toMap(),
          });
        }
      }
      await guard();
      // Persistir as duas versões antes de qualquer envio ou alteração local.
      await preferences.setString(
        _conflictKey(tenantId, companyId, farmId),
        jsonEncode(conflictsFound),
      );
      if (conflictsFound.isNotEmpty) {
        return AtlasGrazingSyncResult(
          '${conflictsFound.length} conflito(s). Envio suspenso; ambas as versões preservadas.',
        );
      }
      for (final record in records.values) {
        await guard();
        await local.save(record);
        if (!existing.any((e) => e.operationId == record.operationId)) {
          received++;
        }
      }
      final pending = existing
          .where((e) => !records.containsKey(e.operationId))
          .toList();
      for (final record in pending.take(20)) {
        await guard();
        final response = await remote.upload(record);
        await guard();
        final confirmed = _decode(response, tenantId, companyId, farmId);
        if (!record.hasSameData(confirmed)) {
          await preferences.setString(
            _conflictKey(tenantId, companyId, farmId),
            jsonEncode([
              {'local': record.toMap(), 'remote': confirmed.toMap()},
            ]),
          );
          throw StateError('Confirmação remota divergente.');
        }
        sent++;
      }
      return AtlasGrazingSyncResult(
        '$received recebido(s), $sent enviado(s).'
        '${pending.length > sent ? ' ${pending.length - sent} aguardam próxima sincronização.' : ' Histórico conciliado.'}',
        sent: sent,
        received: received,
      );
    } on AtlasEnterpriseApiException catch (error) {
      return AtlasGrazingSyncResult(
        error.statusCode == 409
            ? 'Conflito no servidor. Dados locais preservados; consulte novamente o histórico.'
            : 'Conexão indisponível ou acesso recusado. Dados locais preservados.',
      );
    } catch (_) {
      return AtlasGrazingSyncResult(
        'Sincronização não concluída. Dados locais preservados.',
        sent: sent,
        received: received,
      );
    } finally {
      _running = false;
    }
  }
}
