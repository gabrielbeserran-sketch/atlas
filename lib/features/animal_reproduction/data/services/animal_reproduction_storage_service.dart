import 'dart:convert';

import 'package:projeto_atlas/core/network/atlas_http_client.dart';
import 'package:projeto_atlas/core/text/atlas_text_normalizer.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/services/reproduction_return_resolution.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/reproduction_return_queue.dart';
import 'package:projeto_atlas/features/enterprise_platform/data/services/atlas_enterprise_remote_auth_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimalReproductionStorageService {
  AnimalReproductionStorageService({
    AtlasHttpClient? httpClient,
    ReproductionReturnQueue? returnQueue,
    Future<ReturnQueueScope> Function(String farmId)? scopeProvider,
  }) : _http = httpClient ?? AtlasHttpClient(),
       _returnQueue = returnQueue ?? ReproductionReturnQueue(),
       _scopeProvider = scopeProvider;

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final AtlasHttpClient _http;
  final ReproductionReturnQueue _returnQueue;
  final Future<ReturnQueueScope> Function(String farmId)? _scopeProvider;

  Future<ReturnQueueScope> _scope(String farmId) async {
    if (_scopeProvider != null) return _scopeProvider(farmId);
    final session = await AtlasEnterpriseRemoteAuthStore.instance.loadSession();
    if (session == null ||
        farmId.trim().isEmpty ||
        !session.allows('reproduction.write') ||
        (!session.hasUnrestrictedFarmAccess &&
            !session.farmIds.contains(farmId))) {
      throw StateError('Sessão ou fazenda não autorizada para baixa offline.');
    }
    return ReturnQueueScope(
      session.tenantId,
      session.companyId,
      farmId,
      session.userId,
    );
  }

  Future<List<PendingReturn>> pendingReturns({
    required String farmId,
    required String animalId,
  }) async => (await _returnQueue.read(
    await _scope(farmId),
  )).where((row) => row.animalId == animalId).toList();

  Future<PendingReturn> queueReturn({
    required String farmId,
    required AnimalReproductionData record,
    required String status,
    required String responsible,
    String reason = '',
  }) async => _returnQueue.stage(
    await _scope(farmId),
    record,
    status: status,
    responsible: responsible,
    reason: reason,
  );

  Future<void> discardQueuedReturn({
    required String farmId,
    required PendingReturn pending,
  }) async => _returnQueue.remove(await _scope(farmId), pending);

  bool _auditMatches(PendingReturn pending, AnimalReproductionData record) {
    final audit = record.metadata['atlas_return_resolution'];
    return audit is Map &&
        pending.audit.entries.every((entry) => audit[entry.key] == entry.value);
  }

  Future<int> syncQueuedReturns({
    required String farmId,
    required String farmName,
    required String groupName,
    required String animalId,
  }) async {
    final scope = await _scope(farmId);
    final rows = (await _returnQueue.read(
      scope,
    )).where((item) => item.animalId == animalId).toList();
    var confirmed = 0;
    for (final pending in rows) {
      final activeScope = await _scope(farmId);
      if (activeScope.tenantId != scope.tenantId ||
          activeScope.companyId != scope.companyId ||
          activeScope.userId != scope.userId ||
          activeScope.farmId != scope.farmId) {
        throw StateError(
          'Conta ou fazenda mudou. Fila anterior preservada, sem novo envio.',
        );
      }
      final response = await _http.send(
        'GET',
        '/livestock/animals/$animalId/reproduction',
      );
      if (!_hasReturnContract(response)) {
        throw StateError(
          'Servidor sem contrato de baixas; fila local preservada.',
        );
      }
      final matches = response
          .asMapList()
          .map(AnimalReproductionData.fromMap)
          .where((item) => item.id == pending.eventId)
          .toList();
      String? conflict;
      if (matches.length != 1) {
        conflict = 'Evento ausente ou duplicado no servidor.';
      } else {
        final current = matches.single.withAnimalId(animalId);
        if (current.date != pending.occurredDate ||
            current.expectedDate != pending.expectedDate) {
          conflict = 'Previsão ou origem mudou no servidor.';
        } else if (current.hasConfirmedReturnResolution) {
          if (_auditMatches(pending, current)) {
            await _returnQueue.remove(scope, pending);
            await _saveLocal(
              _key(farmName, groupName, animalId),
              response
                  .asMapList()
                  .map(AnimalReproductionData.fromMap)
                  .map((item) => item.withAnimalId(animalId))
                  .toList(),
            );
            confirmed++;
            continue;
          }
          conflict = 'Outra baixa já foi confirmada no servidor.';
        } else if (current.returnResolutionStatus != null &&
            !_auditMatches(pending, current)) {
          conflict = 'Outra resolução aguarda confirmação no servidor.';
        } else {
          final candidate = AnimalReproductionData.fromMap({
            ...current.toMap(),
            'metadata': {
              ...current.metadata,
              'atlas_return_resolution': pending.audit,
            },
          });
          if (candidate.returnResolutionStatus != pending.status) {
            conflict = 'Auditoria local inválida; nenhum envio foi feito.';
          } else {
            final beforeWrite = await _scope(farmId);
            if (beforeWrite.tenantId != scope.tenantId ||
                beforeWrite.companyId != scope.companyId ||
                beforeWrite.userId != scope.userId ||
                beforeWrite.farmId != scope.farmId) {
              throw StateError(
                'Conta ou fazenda mudou. Fila anterior preservada, sem novo envio.',
              );
            }
            final saved = await _sendResolutionMetadata(
              farmName: farmName,
              groupName: groupName,
              animalId: animalId,
              candidate: candidate,
            );
            if (!_auditMatches(pending, saved)) {
              conflict = 'Resposta do servidor divergiu da baixa local.';
            } else {
              await _returnQueue.remove(scope, pending);
              confirmed++;
              continue;
            }
          }
        }
      }
      await _returnQueue.replace(scope, pending.withConflict(conflict));
    }
    return confirmed;
  }

  bool _hasReturnContract(AtlasHttpResponse response) =>
      response.headers.entries.any(
        (entry) =>
            entry.key.toLowerCase() == 'x-atlas-reproduction-returns' &&
            entry.value == 'v1',
      );

  Future<AnimalReproductionData> _sendResolutionMetadata({
    required String farmName,
    required String groupName,
    required String animalId,
    required AnimalReproductionData candidate,
  }) async {
    await _http.send(
      'PATCH',
      '/livestock/animals/$animalId/reproduction/${candidate.id}',
      body: {'metadata_json': candidate.metadata},
    );
    final saved = await _verifyAndCache(
      farmName: farmName,
      groupName: groupName,
      animalId: animalId,
      recordId: candidate.id,
    );
    final audit = candidate.metadata['atlas_return_resolution'] as Map;
    final actual = saved.metadata['atlas_return_resolution'];
    if (!saved.hasConfirmedReturnResolution ||
        actual is! Map ||
        audit.entries.any((entry) => actual[entry.key] != entry.value)) {
      throw StateError(
        'Servidor não confirmou a baixa; fila preservada para reconciliação.',
      );
    }
    return saved;
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  String _key(String farmName, String groupName, String animalId) =>
      'atlas_animal_reproduction_${_normalize(farmName)}_'
      '${_normalize(groupName)}_${_normalize(animalId)}';

  Future<List<AnimalReproductionData>> loadRecords({
    required String farmName,
    required String groupName,
    required String animalId,
  }) async {
    final key = _key(farmName, groupName, animalId);
    try {
      final remote = await _fetchRemote(animalId);
      await _saveLocal(key, remote);
      return remote;
    } catch (_) {
      return _loadLocal(key);
    }
  }

  Future<AnimalReproductionData> createRecord({
    required String farmName,
    required String groupName,
    required String animalId,
    required AnimalReproductionData record,
  }) async {
    final response = await _http.send(
      'POST',
      '/livestock/animals/$animalId/reproduction',
      body: record.toApi(),
    );
    final created = AnimalReproductionData.fromMap(response.asMap());
    return _verifyAndCache(
      farmName: farmName,
      groupName: groupName,
      animalId: animalId,
      recordId: created.id,
    );
  }

  Future<AnimalReproductionData> updateRecord({
    required String farmName,
    required String groupName,
    required String animalId,
    required AnimalReproductionData record,
  }) async {
    await _http.send(
      'PATCH',
      '/livestock/animals/$animalId/reproduction/${record.id}',
      body: record.toApi(),
    );
    final saved = await _verifyAndCache(
      farmName: farmName,
      groupName: groupName,
      animalId: animalId,
      recordId: record.id,
    );
    if (record.returnResolutionStatus != null) {
      final expected = record.metadata['atlas_return_resolution'] as Map;
      final actual = saved.metadata['atlas_return_resolution'];
      if (!saved.hasConfirmedReturnResolution ||
          saved.returnResolutionStatus != record.returnResolutionStatus ||
          actual is! Map ||
          expected.entries.any((entry) => actual[entry.key] != entry.value)) {
        throw StateError(
          'A resolução do retorno não foi confirmada na nova leitura do servidor.',
        );
      }
    }
    return saved;
  }

  Future<AnimalReproductionData> resolveReturn({
    required String farmName,
    required String groupName,
    required String animalId,
    required AnimalReproductionData record,
    required String status,
    required String responsible,
    String reason = '',
  }) async {
    final response = await _http.send(
      'GET',
      '/livestock/animals/$animalId/reproduction',
    );
    if (!_hasReturnContract(response)) {
      throw StateError(
        'O servidor precisa do contrato atualizado de retornos. Nenhuma baixa foi enviada.',
      );
    }
    final matches = response
        .asMapList()
        .map(AnimalReproductionData.fromMap)
        .where((item) => item.id == record.id)
        .toList();
    if (matches.length != 1) {
      throw StateError('Identidade do retorno não foi confirmada.');
    }
    final current = matches.single.withAnimalId(animalId);
    if (current.date != record.date ||
        current.expectedDate != record.expectedDate) {
      throw StateError(
        'O retorno mudou no servidor. Atualize o histórico antes de confirmar.',
      );
    }
    if (current.hasConfirmedReturnResolution) {
      if (current.returnResolutionStatus != status) {
        throw StateError('O retorno já possui outra resolução confirmada.');
      }
      await _saveLocal(
        _key(farmName, groupName, animalId),
        response
            .asMapList()
            .map(AnimalReproductionData.fromMap)
            .map((item) => item.withAnimalId(animalId))
            .toList(),
      );
      return current;
    }
    final candidate = current.returnResolutionStatus != null
        ? current
        : ReproductionReturnResolution.resolve(
            current,
            status: status,
            responsible: responsible,
            at: DateTime.now(),
            reason: reason,
          );
    if (candidate.returnResolutionStatus != status) {
      throw StateError(
        'Existe uma resolução aguardando confirmação com outro estado.',
      );
    }
    return _sendResolutionMetadata(
      farmName: farmName,
      groupName: groupName,
      animalId: animalId,
      candidate: candidate,
    );
  }

  Future<void> deleteRecord({
    required String farmName,
    required String groupName,
    required String animalId,
    required String recordId,
  }) async {
    await _http.send(
      'DELETE',
      '/livestock/animals/$animalId/reproduction/$recordId',
    );
    final remote = await _fetchRemote(animalId);
    if (remote.any((item) => item.id == recordId)) {
      throw StateError(
        'O registro reprodutivo ainda existe após a exclusão no servidor.',
      );
    }
    await _saveLocal(_key(farmName, groupName, animalId), remote);
  }

  Future<List<AnimalReproductionData>> saveRecords({
    required String farmName,
    required String groupName,
    required String animalId,
    required List<AnimalReproductionData> records,
  }) async {
    final remote = await _fetchRemote(animalId);
    final remoteIds = remote.map((item) => item.id).toSet();
    final created = <AnimalReproductionData>[];
    for (final record in records) {
      if (remoteIds.contains(record.id) || record.synced) {
        continue;
      }
      created.add(
        await createRecord(
          farmName: farmName,
          groupName: groupName,
          animalId: animalId,
          record: record,
        ),
      );
    }
    final refreshed = created.isEmpty ? remote : await _fetchRemote(animalId);
    await _saveLocal(_key(farmName, groupName, animalId), refreshed);
    return refreshed;
  }

  Future<AnimalReproductionData> _verifyAndCache({
    required String farmName,
    required String groupName,
    required String animalId,
    required String recordId,
  }) async {
    final remote = await _fetchRemote(animalId);
    final saved = remote.firstWhere(
      (item) => item.id == recordId,
      orElse: () => throw StateError(
        'O registro reprodutivo não foi confirmado após nova leitura do servidor.',
      ),
    );
    await _saveLocal(_key(farmName, groupName, animalId), remote);
    return saved;
  }

  Future<List<AnimalReproductionData>> _fetchRemote(String animalId) async {
    final response = await _http.send(
      'GET',
      '/livestock/animals/$animalId/reproduction',
    );
    return response
        .asMapList()
        .map(AnimalReproductionData.fromMap)
        .map((record) => record.withAnimalId(animalId))
        .toList();
  }

  Future<List<AnimalReproductionData>> _loadLocal(String key) async {
    final raw = await _preferences.getString(key);
    if (raw == null || raw.isEmpty) return <AnimalReproductionData>[];
    try {
      return (AtlasTextNormalizer.normalize(jsonDecode(raw)) as List<dynamic>)
          .map(
            (item) => AnimalReproductionData.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return <AnimalReproductionData>[];
    }
  }

  Future<void> _saveLocal(String key, List<AnimalReproductionData> records) =>
      _preferences.setString(
        key,
        jsonEncode(records.map((record) => record.toMap()).toList()),
      );
}
