import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_atlas/features/animal/data/services/animal_enterprise_service.dart';
import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'atlas_pasture_grazing_basis_service.dart';

class AtlasGrazingCandidate {
  const AtlasGrazingCandidate(this.id, this.tag, this.name, this.active);
  final String id;
  final String tag;
  final String name;
  final bool active;
  Map<String, dynamic> toMap() => {
    'id': id,
    'tag': tag,
    'name': name,
    'active': active,
  };
  factory AtlasGrazingCandidate.fromMap(Map<String, dynamic> map) =>
      AtlasGrazingCandidate(
        map['id'] as String,
        map['tag'] as String,
        map['name'] as String,
        map['active'] == true,
      );
}

class AtlasGrazingRoster {
  const AtlasGrazingRoster(this.animals, this.recordedAt);
  final List<AtlasGrazingCandidate> animals;
  final DateTime recordedAt;
  bool isCurrent(DateTime now) =>
      !now.isBefore(recordedAt) &&
      now.difference(recordedAt) <= const Duration(days: 7);
}

class AtlasGrazingSelection {
  const AtlasGrazingSelection(
    this.basis,
    this.animalIds,
    this.recordedAt,
    this.rosterAt,
  );
  final AtlasPastureGrazingBasis basis;
  final List<String> animalIds;
  final DateTime recordedAt;
  final DateTime rosterAt;
  Map<String, dynamic> toMap() => {
    'basis': basis.toMap(),
    'animalIds': animalIds,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    'rosterAt': rosterAt.toUtc().toIso8601String(),
  };
  factory AtlasGrazingSelection.fromMap(Map<String, dynamic> map) =>
      AtlasGrazingSelection(
        AtlasPastureGrazingBasis.fromMap(
          Map<String, dynamic>.from(map['basis'] as Map),
        ),
        List<String>.from(map['animalIds'] as List),
        DateTime.parse(map['recordedAt'] as String),
        DateTime.parse(map['rosterAt'] as String),
      );
}

/// Não reutiliza o cache legado por nome de fazenda/lote.
class AtlasGrazingAnimalsService {
  AtlasGrazingAnimalsService({
    SharedPreferencesAsync? preferences,
    Future<List<AnimalData>> Function(String farmId)? fetchAnimals,
  }) : preferences = preferences ?? SharedPreferencesAsync(),
       fetchAnimals =
           fetchAnimals ??
           ((farmId) => AnimalEnterpriseService().listAnimals(
             farmId: farmId,
             lotId: '',
           ));
  final SharedPreferencesAsync preferences;
  final Future<List<AnimalData>> Function(String farmId) fetchAnimals;
  static final Map<String, Future<void>> _writes = {};

  String _key(AtlasPastureGrazingBasis basis) {
    basis.validate();
    return 'atlas_grazing_animals_v1_${base64Url.encode(utf8.encode(jsonEncode([basis.tenantId, basis.companyId, basis.farmId])))}';
  }

  Future<AtlasGrazingRoster?> loadRoster(AtlasPastureGrazingBasis basis) async {
    final raw = await preferences.getString('${_key(basis)}_roster');
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    if (map['tenantId'] != basis.tenantId ||
        map['companyId'] != basis.companyId ||
        map['farmId'] != basis.farmId) {
      throw const FormatException('Carteira de outra fazenda.');
    }
    final animals = (map['animals'] as List)
        .map(
          (e) => AtlasGrazingCandidate.fromMap(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    if (animals.any((e) => e.id.isEmpty) ||
        animals.map((e) => e.id).toSet().length != animals.length) {
      throw const FormatException('Identificação dos animais inconsistente.');
    }
    return AtlasGrazingRoster(
      animals,
      DateTime.parse(map['recordedAt'] as String),
    );
  }

  Future<AtlasGrazingRoster> refreshRoster(
    AtlasPastureGrazingBasis basis,
    Future<bool> Function() isAuthorized,
  ) async {
    final key = _key(basis);
    if (!await isAuthorized()) throw StateError('Fazenda não autorizada.');
    final records = await fetchAnimals(basis.farmId);
    if (!await isAuthorized()) {
      throw StateError('Contexto mudou durante a consulta.');
    }
    final animals = records
        .map(
          (e) => AtlasGrazingCandidate(
            e.id,
            e.tag,
            e.displayName,
            e.status.toLowerCase() == 'ativo' ||
                e.status.toLowerCase() == 'active',
          ),
        )
        .toList();
    if (animals.any((e) => e.id.isEmpty) ||
        animals.map((e) => e.id).toSet().length != animals.length) {
      throw const FormatException('Identificação dos animais inconsistente.');
    }
    final roster = AtlasGrazingRoster(animals, DateTime.now().toUtc());
    await preferences.setString(
      '${key}_roster',
      jsonEncode({
        'tenantId': basis.tenantId,
        'companyId': basis.companyId,
        'farmId': basis.farmId,
        'recordedAt': roster.recordedAt.toIso8601String(),
        'animals': animals.map((e) => e.toMap()).toList(),
      }),
    );
    return roster;
  }

  Future<List<AtlasGrazingSelection>> loadHistory(
    AtlasPastureGrazingBasis basis,
  ) async {
    final raw = await preferences.getString('${_key(basis)}_selections');
    if (raw == null) return [];
    final records = (jsonDecode(raw) as List)
        .map(
          (e) => AtlasGrazingSelection.fromMap(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    for (final item in records) {
      item.basis.validate();
      if (item.basis.tenantId != basis.tenantId ||
          item.basis.companyId != basis.companyId ||
          item.basis.farmId != basis.farmId ||
          item.animalIds.any((e) => e.trim().isEmpty) ||
          item.animalIds.toSet().length != item.animalIds.length ||
          item.animalIds.length != item.basis.grazingAnimals) {
        throw const FormatException('Vínculos de pastejo inconsistentes.');
      }
    }
    return records;
  }

  Future<AtlasGrazingSelection?> loadCurrent(
    AtlasPastureGrazingBasis basis,
  ) async {
    final records = await loadHistory(basis);
    for (final item in records.reversed) {
      if (item.basis.hasSameData(basis)) return item;
    }
    return null;
  }

  Future<void> saveSelection(
    AtlasPastureGrazingBasis basis,
    List<String> animalIds,
    Future<bool> Function() isAuthorized,
  ) async {
    final key = _key(basis);
    final selectedIds = List<String>.from(animalIds)..sort();
    final previous = _writes[key] ?? Future<void>.value();
    final write = previous.then((_) async {
      if (!await isAuthorized() || !basis.isCurrentAt(DateTime.now())) {
        throw StateError('Atualize a base de pastejo autorizada.');
      }
      final roster = await loadRoster(basis);
      if (roster == null || !roster.isCurrent(DateTime.now())) {
        throw StateError('Atualize a carteira de animais.');
      }
      final eligible = roster.animals
          .where((e) => e.active)
          .map((e) => e.id)
          .toSet();
      if (selectedIds.length != basis.grazingAnimals ||
          selectedIds.toSet().length != selectedIds.length ||
          selectedIds.any((id) => !eligible.contains(id))) {
        throw ArgumentError(
          'Selecione exatamente os animais ativos informados na base.',
        );
      }
      final history = await loadHistory(basis);
      if (!await isAuthorized()) throw StateError('Contexto mudou.');
      final selection = AtlasGrazingSelection(
        basis,
        selectedIds,
        DateTime.now().toUtc(),
        roster.recordedAt,
      );
      await preferences.setString(
        '${key}_selections',
        jsonEncode([...history.map((e) => e.toMap()), selection.toMap()]),
      );
    });
    final tail = write.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    _writes[key] = tail;
    try {
      await write;
    } finally {
      if (identical(_writes[key], tail)) _writes.remove(key);
    }
  }
}
