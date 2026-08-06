class AtlasReleaseCheck {
  const AtlasReleaseCheck({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isCritical,
    required this.isCompleted,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final bool isCritical;
  final bool isCompleted;

  AtlasReleaseCheck copyWith({bool? isCompleted}) {
    return AtlasReleaseCheck(
      id: id,
      title: title,
      description: description,
      category: category,
      isCritical: isCritical,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
