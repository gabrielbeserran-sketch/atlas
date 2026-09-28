import 'dart:async';
import 'dart:convert';

import 'package:projeto_atlas/core/text/atlas_text_normalizer.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_enterprise_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/animal_reproduction/data/services/animal_reproduction_storage_service.dart';
import 'package:projeto_atlas/features/animal_reproduction/domain/models/animal_reproduction_data.dart';
import 'package:projeto_atlas/features/enterprise_platform/data/services/atlas_enterprise_remote_auth_store.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/models/atlas_enterprise_remote_session.dart';
import 'package:projeto_atlas/features/enterprise_platform/domain/services/atlas_enterprise_api_client.dart';
import 'package:projeto_atlas/features/farm/domain/models/farm_data.dart';
import 'package:projeto_atlas/features/herd/data/services/herd_enterprise_service.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReproductionOverviewEntry {
  const ReproductionOverviewEntry({
    required this.farm,
    required this.group,
    required this.animal,
    required this.records,
  });

  final FarmData farm;
  final HerdGroupData group;
  final AnimalData animal;
  final List<AnimalReproductionData> records;

  Map<String, dynamic> toMap() => {
    'farm': farm.toMap(),
    'group': group.toMap(),
    'animal': animal.toMap(),
    'records': records.map((record) => record.toMap()).toList(),
  };

  factory ReproductionOverviewEntry.fromMap(Map<String, dynamic> map) =>
      ReproductionOverviewEntry(
        farm: FarmData.fromMap(Map<String, dynamic>.from(map['farm'] as Map)),
        group: HerdGroupData.fromMap(
          Map<String, dynamic>.from(map['group'] as Map),
        ),
        animal: AnimalData.fromMap(
          Map<String, dynamic>.from(map['animal'] as Map),
        ),
        records: (map['records'] as List)
            .map(
              (row) => AnimalReproductionData.fromMap(
                Map<String, dynamic>.from(row as Map),
              ),
            )
            .toList(growable: false),
      );
}

class ReproductionOverviewSnapshot {
  const ReproductionOverviewSnapshot({
    required this.entries,
    required this.available,
  });

  final List<ReproductionOverviewEntry> entries;
  final bool available;
}

/// Snapshot completo da visão geral, separado dos caches legados por nome.
/// Uma falha em qualquer lote/animal/evento mantém a última cópia intacta.
class ReproductionOverviewSnapshotService {
  ReproductionOverviewSnapshotService({
    SharedPreferencesAsync? preferences,
    Future<AtlasRemoteSession?> Function()? sessionProvider,
    Future<List<FarmData>> Function()? farmsProvider,
    Future<List<HerdGroupData>> Function(String farmId)? groupsProvider,
    Future<List<AnimalData>> Function(String farmId, String lotId)?
    animalsProvider,
    Future<List<AnimalReproductionData>> Function(
      String farmId,
      String animalId,
    )?
    recordsProvider,
    this.maxConcurrentRecordReads = 4,
  }) : assert(maxConcurrentRecordReads > 0 && maxConcurrentRecordReads <= 8),
       _preferences = preferences ?? SharedPreferencesAsync(),
       _sessionProvider =
           sessionProvider ??
           AtlasEnterpriseRemoteAuthStore.instance.loadSession,
       _farmsProvider = farmsProvider ?? _loadRemoteFarms,
       _groupsProvider = groupsProvider ?? HerdEnterpriseService().listGroups,
       _animalsProvider = animalsProvider ?? _loadRemoteAnimals,
       _recordsProvider = recordsProvider ?? _loadRemoteRecords;

  final SharedPreferencesAsync _preferences;
  final Future<AtlasRemoteSession?> Function() _sessionProvider;
  final Future<List<FarmData>> Function() _farmsProvider;
  final Future<List<HerdGroupData>> Function(String) _groupsProvider;
  final Future<List<AnimalData>> Function(String, String) _animalsProvider;
  final Future<List<AnimalReproductionData>> Function(String, String)
  _recordsProvider;
  final int maxConcurrentRecordReads;

  static const _prefix = 'atlas_reproduction_overview_v1_';
  static final Map<String, int> _refreshRevisions = {};
  static final Map<String, Future<void>> _pendingWrites = {};

  static Future<List<FarmData>> _loadRemoteFarms() async {
    final rows = await AtlasEnterpriseApiClient.instance.requestList(
      'GET',
      '/farms',
    );
    return rows.map(FarmData.fromMap).toList(growable: false);
  }

  static Future<List<AnimalData>> _loadRemoteAnimals(
    String farmId,
    String lotId,
  ) => AnimalEnterpriseService().listAnimals(farmId: farmId, lotId: lotId);

  static Future<List<AnimalReproductionData>> _loadRemoteRecords(
    String farmId,
    String animalId,
  ) => AnimalReproductionStorageService().refreshRecords(
    farmId: farmId,
    animalId: animalId,
  );

  Future<AtlasRemoteSession> _session() async {
    final session = await _sessionProvider();
    if (session == null ||
        session.tenantId.trim().isEmpty ||
        session.companyId.trim().isEmpty ||
        session.userId.trim().isEmpty ||
        !session.allows('reproduction.read')) {
      throw StateError('Sessão não autorizada para a visão reprodutiva.');
    }
    return session;
  }

  String _key(AtlasRemoteSession session) =>
      _prefix +
      [
        session.tenantId,
        session.companyId,
        session.userId,
      ].map(Uri.encodeComponent).join('_');

  bool _allowed(AtlasRemoteSession session, String farmId) =>
      farmId.trim().isNotEmpty &&
      (session.hasUnrestrictedFarmAccess || session.farmIds.contains(farmId));

  List<ReproductionOverviewEntry> _visible(
    AtlasRemoteSession session,
    List<ReproductionOverviewEntry> entries,
    FarmData? selectedFarm,
  ) => entries
      .where(
        (entry) =>
            _allowed(session, entry.farm.id ?? '') &&
            (selectedFarm == null || entry.farm.id == selectedFarm.id),
      )
      .toList(growable: false);

  Future<ReproductionOverviewSnapshot> loadCached({
    FarmData? selectedFarm,
  }) async {
    final session = await _session();
    final raw = await _preferences.getString(_key(session));
    if (raw == null || raw.isEmpty) {
      return const ReproductionOverviewSnapshot(entries: [], available: false);
    }
    try {
      final decoded = AtlasTextNormalizer.normalize(jsonDecode(raw)) as Map;
      final farmIds = (decoded['farm_ids'] as List).map((id) => '$id').toSet();
      if (!session.hasUnrestrictedFarmAccess &&
          !session.farmIds.every(farmIds.contains)) {
        return const ReproductionOverviewSnapshot(
          entries: [],
          available: false,
        );
      }
      final entries = (decoded['entries'] as List)
          .map(
            (row) => ReproductionOverviewEntry.fromMap(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(growable: false);
      if (selectedFarm != null &&
          (!_allowed(session, selectedFarm.id ?? '') ||
              !farmIds.contains(selectedFarm.id))) {
        return const ReproductionOverviewSnapshot(
          entries: [],
          available: false,
        );
      }
      return ReproductionOverviewSnapshot(
        entries: _visible(session, entries, selectedFarm),
        available: true,
      );
    } catch (_) {
      return const ReproductionOverviewSnapshot(entries: [], available: false);
    }
  }

  Future<List<ReproductionOverviewEntry>> refresh({
    FarmData? selectedFarm,
  }) async {
    final initial = await _session();
    final key = _key(initial);
    final revision = (_refreshRevisions[key] ?? 0) + 1;
    _refreshRevisions[key] = revision;
    final remoteFarms = await _farmsProvider();
    if (_refreshRevisions[key] != revision) {
      throw StateError('Atualização mais recente já iniciada.');
    }
    final permitted = remoteFarms
        .where((farm) => _allowed(initial, farm.id ?? ''))
        .toList(growable: false);
    if (selectedFarm != null &&
        !permitted.any((farm) => farm.id == selectedFarm.id)) {
      throw StateError('Fazenda não autorizada nesta sessão.');
    }

    final jobs = <({FarmData farm, HerdGroupData group, AnimalData animal})>[];
    for (final farm in permitted) {
      final farmId = farm.id!;
      final groups = await _groupsProvider(farmId);
      if (_refreshRevisions[key] != revision) {
        throw StateError('Atualização mais recente já iniciada.');
      }
      for (final group in groups) {
        if (group.id.trim().isEmpty) {
          throw StateError('Lote sem identidade remota; cópia não atualizada.');
        }
        final animals = await _animalsProvider(farmId, group.id);
        if (_refreshRevisions[key] != revision) {
          throw StateError('Atualização mais recente já iniciada.');
        }
        for (final animal in animals) {
          final sex = animal.sex.trim().toLowerCase();
          if (sex != 'fêmea' && sex != 'femea' && sex != 'female') continue;
          if (animal.id.trim().isEmpty) {
            throw StateError(
              'Animal sem identidade remota; cópia não atualizada.',
            );
          }
          jobs.add((farm: farm, group: group, animal: animal));
        }
      }
    }

    final results = List<ReproductionOverviewEntry?>.filled(jobs.length, null);
    var nextJob = 0;
    Object? firstFailure;
    StackTrace? firstStack;
    Future<void> worker() async {
      while (firstFailure == null &&
          _refreshRevisions[key] == revision &&
          nextJob < jobs.length) {
        final index = nextJob++;
        final job = jobs[index];
        try {
          final records = await _recordsProvider(job.farm.id!, job.animal.id);
          results[index] = ReproductionOverviewEntry(
            farm: job.farm,
            group: job.group,
            animal: job.animal,
            records: records,
          );
        } catch (error, stack) {
          firstFailure ??= error;
          firstStack ??= stack;
        }
      }
    }

    await Future.wait(
      List.generate(
        jobs.length < maxConcurrentRecordReads
            ? jobs.length
            : maxConcurrentRecordReads,
        (_) => worker(),
      ),
    );
    if (firstFailure case final failure?) {
      Error.throwWithStackTrace(failure, firstStack!);
    }
    if (_refreshRevisions[key] != revision) {
      throw StateError('Atualização mais recente já iniciada.');
    }
    final entries = results.cast<ReproductionOverviewEntry>();

    final current = await _session();
    if (_refreshRevisions[key] != revision ||
        _key(current) != key ||
        current.role != initial.role ||
        current.farmIds
            .toSet()
            .difference(initial.farmIds.toSet())
            .isNotEmpty ||
        initial.farmIds
            .toSet()
            .difference(current.farmIds.toSet())
            .isNotEmpty ||
        permitted.any((farm) => !_allowed(current, farm.id ?? ''))) {
      throw StateError('Conta ou acesso à fazenda mudou durante a leitura.');
    }
    await _storeIfCurrent(
      key: key,
      revision: revision,
      initial: initial,
      farms: permitted,
      value: jsonEncode({
        'farm_ids': permitted.map((farm) => farm.id).toList(),
        'entries': entries.map((entry) => entry.toMap()).toList(),
      }),
    );
    return _visible(current, entries, selectedFarm);
  }

  Future<void> _storeIfCurrent({
    required String key,
    required int revision,
    required AtlasRemoteSession initial,
    required List<FarmData> farms,
    required String value,
  }) async {
    final previous = _pendingWrites[key];
    final completed = Completer<void>();
    final currentWrite = completed.future;
    _pendingWrites[key] = currentWrite;
    try {
      if (previous != null) await previous;
      final current = await _session();
      if (_refreshRevisions[key] != revision ||
          _key(current) != key ||
          current.role != initial.role ||
          current.farmIds.toSet().length != initial.farmIds.toSet().length ||
          !current.farmIds.toSet().containsAll(initial.farmIds) ||
          farms.any((farm) => !_allowed(current, farm.id ?? ''))) {
        throw StateError(
          'Leitura antiga ou acesso alterado; cópia preservada.',
        );
      }
      await _preferences.setString(key, value);
    } finally {
      completed.complete();
      if (identical(_pendingWrites[key], currentWrite)) {
        _pendingWrites.remove(key);
      }
    }
  }
}
