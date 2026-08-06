class AnimalEventData {
  const AnimalEventData({
    required this.id,
    required this.type,
    required this.date,
    required this.title,
    required this.description,
  });

  final String id;
  final String type;
  final String date;
  final String title;
  final String description;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'date': date,
      'title': title,
      'description': description,
    };
  }

  factory AnimalEventData.fromMap(Map<String, dynamic> map) {
    return AnimalEventData(
      id: map['id'] as String,
      type: map['type'] as String,
      date: map['date'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
    );
  }
}
