import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class HerdAnimalRecord {
  const HerdAnimalRecord({required this.animal, required this.group});

  final AnimalData animal;
  final HerdGroupData group;
}

class HerdWorkspaceData {
  const HerdWorkspaceData({required this.groups, required this.records});

  final List<HerdGroupData> groups;
  final List<HerdAnimalRecord> records;

  int get totalAnimals => records.length;
  int get activeAnimals => records
      .where((record) => _isActiveStatus(record.animal.status))
      .length;
  int get females => records
      .where((record) => _normalize(record.animal.sex).startsWith('f'))
      .length;
  int get males => records
      .where((record) => _normalize(record.animal.sex).startsWith('m'))
      .length;

  double get averageWeight {
    final weighted = records
        .where((record) => record.animal.weight > 0)
        .map((record) => record.animal.weight)
        .toList(growable: false);
    if (weighted.isEmpty) return 0;
    return weighted.reduce((first, second) => first + second) / weighted.length;
  }

  List<HerdAnimalRecord> filter({
    String query = '',
    String lotId = '',
    String status = '',
    String sex = '',
  }) {
    final normalizedQuery = _normalize(query);
    final normalizedStatus = _normalize(status);
    final normalizedSex = _normalize(sex);

    return records
        .where((record) {
          final animal = record.animal;
          final matchesQuery =
              normalizedQuery.isEmpty ||
              [
                animal.tag,
                animal.sisbov,
                animal.name,
                animal.breed,
                animal.category,
              ].map(_normalize).any((value) => value.contains(normalizedQuery));
          final matchesLot = lotId.isEmpty || record.group.id == lotId;
          final matchesStatus =
              normalizedStatus.isEmpty ||
              _statusMatches(animal.status, normalizedStatus);
          final matchesSex =
              normalizedSex.isEmpty || _normalize(animal.sex) == normalizedSex;
          return matchesQuery && matchesLot && matchesStatus && matchesSex;
        })
        .toList(growable: false);
  }

  static bool _isActiveStatus(String value) {
    final normalized = _normalize(value);
    return normalized == 'ativo' || normalized == 'active';
  }

  static bool _statusMatches(String value, String selected) {
    final normalizedValue = _normalize(value);
    if (selected == 'ativo' || selected == 'active') {
      return normalizedValue == 'ativo' || normalizedValue == 'active';
    }
    return normalizedValue == selected;
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}
