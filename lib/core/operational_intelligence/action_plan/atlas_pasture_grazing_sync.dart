import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'atlas_pasture_grazing_basis_service.dart';

abstract class AtlasGrazingRemote {
  Future<bool> supports(String farmId);

  /// `null` apenas quando o servidor antigo não oferece a rota de cursor.
  Future<List<Map<String, dynamic>>?> historyCursor(
    String farmId,
    String? afterCreatedAt,
    String? afterId,
    int limit,
  );
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
  Future<List<Map<String, dynamic>>?> historyCursor(
    String farmId,
    String? afterCreatedAt,
    String? afterId,
    int limit,
  ) async {
    try {
      return await _api.requestList(
        'GET',
        '${_path(farmId)}/cursor',
        queryParameters: {
          'limit': '$limit',
          if (afterCreatedAt != null) 'after_created_at': afterCreatedAt,
          if (afterId != null) 'after_id': afterId,
        },
      );
    } on AtlasEnterpriseApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

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

class AtlasGrazingSyncProgress {
  const AtlasGrazingSyncProgress.reading({
    required this.pagesRead,
    required this.recordsRead,
  }) : phase = AtlasGrazingSyncPhase.reading,
       sent = 0,
       totalToSend = 0;

  const AtlasGrazingSyncProgress.importing({required this.recordsRead})
    : phase = AtlasGrazingSyncPhase.importing,
      pagesRead = 0,
      sent = 0,
      totalToSend = 0;

  const AtlasGrazingSyncProgress.restarting()
    : phase = AtlasGrazingSyncPhase.restarting,
      pagesRead = 0,
      recordsRead = 0,
      sent = 0,
      totalToSend = 0;

  const AtlasGrazingSyncProgress.uploading({
    required this.sent,
    required this.totalToSend,
  }) : phase = AtlasGrazingSyncPhase.uploading,
       pagesRead = 0,
       recordsRead = 0;

  final AtlasGrazingSyncPhase phase;
  final int pagesRead;
  final int recordsRead;
  final int sent;
  final int totalToSend;

  String get message => switch (phase) {
    AtlasGrazingSyncPhase.reading =>
      'Consultando histórico: $recordsRead registro(s) em $pagesRead página(s)…',
    AtlasGrazingSyncPhase.importing =>
      'Conferindo e salvando $recordsRead registro(s) neste dispositivo…',
    AtlasGrazingSyncPhase.restarting =>
      'O histórico mudou durante a leitura. Conferindo novamente…',
    AtlasGrazingSyncPhase.uploading =>
      'Enviando bases pendentes: $sent de $totalToSend…',
  };
}

enum AtlasGrazingSyncPhase { reading, restarting, importing, uploading }

class _UnstableGrazingHistory implements Exception {}

/// Comando explícito: nunca condiciona abertura ou gravação local à rede.
class AtlasPastureGrazingSync {
  // O histórico é append-only. Um teto amplo permite fazendas antigas sem
  // manter uma consulta infinita caso o servidor repita páginas completas.
  static const int maxHistoryPages = 1000;

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

  ({DateTime createdAt, String id}) _cursor(Map<String, dynamic> data) {
    final date = data['created_at']?.toString() ?? '';
    final id = data['id']?.toString() ?? '';
    if (!RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(date) || id.isEmpty) {
      throw const FormatException('Cursor remoto incompleto.');
    }
    final createdAt = DateTime.tryParse(date);
    if (createdAt == null) {
      throw const FormatException('Data do cursor inválida.');
    }
    return (createdAt: createdAt.toUtc(), id: id);
  }

  Future<void> acceptRemoteConflict({
    required AtlasPastureGrazingBasis expectedRemote,
    required String reviewedBy,
    required Future<bool> Function() isAuthorized,
  }) async {
    if (_running) throw StateError('Aguarde a operação em andamento.');
    _running = true;
    try {
      expectedRemote.validate();
      if (!await isAuthorized()) throw StateError('Contexto da revisão mudou.');
      final items = await conflicts(
        expectedRemote.tenantId,
        expectedRemote.companyId,
        expectedRemote.farmId,
      );
      final matching = items
          .where(
            (item) =>
                (item['local'] as Map)['operationId'] ==
                expectedRemote.operationId,
          )
          .toList();
      if (matching.length != 1) {
        throw StateError('Conflito ausente ou duplicado; atualize a tela.');
      }
      final item = matching.single;
      final remoteVersion = AtlasPastureGrazingBasis.fromMap(
        Map<String, dynamic>.from(item['remote'] as Map),
      );
      final localVersion = AtlasPastureGrazingBasis.fromMap(
        Map<String, dynamic>.from(item['local'] as Map),
      );
      if (!remoteVersion.hasSameData(expectedRemote)) {
        throw StateError('A versão remota mudou; reabra a revisão.');
      }
      if (!await isAuthorized()) throw StateError('Contexto da revisão mudou.');
      await local.acceptReviewedRemote(
        expectedLocal: localVersion,
        remote: remoteVersion,
        reviewedBy: reviewedBy,
      );
      // Uma falha nesta última escrita mantém o conflito revisável; repetir é seguro.
      await preferences.setString(
        _conflictKey(
          expectedRemote.tenantId,
          expectedRemote.companyId,
          expectedRemote.farmId,
        ),
        jsonEncode(items.where((e) => !identical(e, item)).toList()),
      );
    } finally {
      _running = false;
    }
  }

  Future<AtlasGrazingSyncResult> synchronize({
    required String tenantId,
    required String companyId,
    required String farmId,
    required Future<bool> Function() isAuthorized,
    void Function(AtlasGrazingSyncProgress)? onProgress,
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
      await local.loadHistory(
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
      await guard();
      final cursorProbe = await remote.historyCursor(
        farmId,
        null,
        null,
        pageSize,
      );
      await guard();
      if (cursorProbe != null) {
        var complete = false;
        ({DateTime createdAt, String id})? previous;
        var items = cursorProbe;
        for (var page = 0; page < maxHistoryPages; page++) {
          if (items.length > pageSize) {
            throw StateError('Servidor excedeu o tamanho da página.');
          }
          for (final item in items) {
            final cursor = _cursor(item);
            if (previous != null &&
                !cursor.createdAt.isBefore(previous.createdAt) &&
                !(cursor.createdAt.isAtSameMomentAs(previous.createdAt) &&
                    cursor.id.compareTo(previous.id) < 0)) {
              throw StateError('Cursor remoto fora de ordem.');
            }
            final record = _decode(item, tenantId, companyId, farmId);
            if (records.containsKey(record.operationId)) {
              throw StateError('Operação repetida no histórico remoto.');
            }
            records[record.operationId] = record;
            previous = cursor;
          }
          onProgress?.call(
            AtlasGrazingSyncProgress.reading(
              pagesRead: page + 1,
              recordsRead: records.length,
            ),
          );
          if (items.length < pageSize) {
            complete = true;
            break;
          }
          await guard();
          items =
              await remote.historyCursor(
                farmId,
                previous!.createdAt.toIso8601String(),
                previous.id,
                pageSize,
              ) ??
              (throw StateError('Servidor perdeu suporte a cursor.'));
          await guard();
        }
        if (!complete) {
          throw StateError('Histórico remoto exige revisão de paginação.');
        }
      } else {
        var stable = false;
        for (var attempt = 0; attempt < 2; attempt++) {
          records.clear();
          var complete = false;
          var overlap = false;
          var pagesRead = 0;
          var firstPage = <AtlasPastureGrazingBasis>[];
          for (var page = 0; page < maxHistoryPages; page++) {
            await guard();
            final items = await remote.history(
              farmId,
              page * pageSize,
              pageSize,
            );
            await guard();
            if (items.length > pageSize) {
              throw StateError('Servidor excedeu o tamanho da página.');
            }
            final decoded = items
                .map((item) => _decode(item, tenantId, companyId, farmId))
                .toList();
            if (page == 0) firstPage = decoded;
            for (final record in decoded) {
              final duplicate = records[record.operationId];
              if (duplicate != null && !duplicate.hasSameData(record)) {
                throw StateError('Histórico remoto divergente.');
              }
              if (duplicate != null) overlap = true;
              records[record.operationId] = record;
            }
            if (overlap) break;
            pagesRead = page + 1;
            onProgress?.call(
              AtlasGrazingSyncProgress.reading(
                pagesRead: pagesRead,
                recordsRead: records.length,
              ),
            );
            if (items.length < pageSize) {
              complete = true;
              break;
            }
          }
          if (!complete && !overlap) {
            throw StateError('Histórico remoto exige revisão de paginação.');
          }
          if (!overlap && pagesRead > 1) {
            await guard();
            final latest = await remote.history(farmId, 0, pageSize);
            await guard();
            stable = latest.length == firstPage.length;
            if (stable) {
              for (var i = 0; i < latest.length; i++) {
                if (!firstPage[i].hasSameData(
                  _decode(latest[i], tenantId, companyId, farmId),
                )) {
                  stable = false;
                  break;
                }
              }
            }
          } else if (!overlap) {
            stable = true;
          }
          if (stable) break;
          if (attempt == 0) {
            onProgress?.call(const AtlasGrazingSyncProgress.restarting());
          }
        }
        if (!stable) {
          throw _UnstableGrazingHistory();
        }
      }
      // Releitura após a rede: uma gravação local feita durante a consulta
      // também precisa participar do confronto e da fila de envio.
      await guard();
      final current = await local.loadHistory(
        tenantId: tenantId,
        companyId: companyId,
        farmId: farmId,
        strict: true,
      );
      final conflictsFound = <Map<String, dynamic>>[];
      for (final record in current) {
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
      onProgress?.call(
        AtlasGrazingSyncProgress.importing(recordsRead: records.length),
      );
      await guard();
      received = await local.saveAll(records.values);
      final pending = current
          .where((e) => !records.containsKey(e.operationId))
          .toList();
      final toSend = pending.take(20).toList();
      if (toSend.isNotEmpty) {
        onProgress?.call(
          AtlasGrazingSyncProgress.uploading(
            sent: 0,
            totalToSend: toSend.length,
          ),
        );
      }
      for (final record in toSend) {
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
        onProgress?.call(
          AtlasGrazingSyncProgress.uploading(
            sent: sent,
            totalToSend: toSend.length,
          ),
        );
      }
      return AtlasGrazingSyncResult(
        '$received recebido(s), $sent enviado(s).'
        '${pending.length > sent ? ' ${pending.length - sent} aguardam próxima sincronização.' : ' Histórico conciliado.'}',
        sent: sent,
        received: received,
      );
    } on _UnstableGrazingHistory {
      return const AtlasGrazingSyncResult(
        'O histórico mudou durante a consulta. Nenhum dado foi enviado ou importado; tente sincronizar novamente em alguns instantes.',
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
