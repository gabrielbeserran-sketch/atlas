import 'package:projeto_atlas/features/animal/domain/models/animal_data.dart';
import 'package:projeto_atlas/features/herd/domain/models/herd_group_data.dart';

class TechnicalPendingWeighingAnimal {
  const TechnicalPendingWeighingAnimal({
    required this.animal,
    required this.group,
    this.lastValidWeightDate,
  });

  final AnimalData animal;
  final HerdGroupData group;
  final DateTime? lastValidWeightDate;

  String get id => animal.id;
  String get tag => animal.tag;
  String get name => animal.name;
  String get groupName => group.name;

  String get label {
    final normalizedTag = tag.trim();
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      return normalizedTag.isEmpty ? 'Animal sem identificação' : normalizedTag;
    }
    if (normalizedTag.isEmpty || normalizedTag == normalizedName) {
      return normalizedName;
    }
    return '$normalizedTag · $normalizedName';
  }
}
