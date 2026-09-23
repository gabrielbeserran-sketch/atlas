class TechnicalPendingWeighingAnimal {
  const TechnicalPendingWeighingAnimal({
    required this.id,
    required this.tag,
    required this.name,
    required this.groupName,
    this.lastValidWeightDate,
  });

  final String id;
  final String tag;
  final String name;
  final String groupName;
  final DateTime? lastValidWeightDate;

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
