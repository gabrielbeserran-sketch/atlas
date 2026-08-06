class PaddockData {
  const PaddockData({
    required this.name,
    required this.area,
    required this.status,
    required this.animals,
  });

  final String name;
  final double area;
  final String status;
  final int animals;

  Map<String, dynamic> toMap() {
    return {'name': name, 'area': area, 'status': status, 'animals': animals};
  }

  factory PaddockData.fromMap(Map<String, dynamic> map) {
    return PaddockData(
      name: map['name'] as String,
      area: (map['area'] as num).toDouble(),
      status: map['status'] as String,
      animals: map['animals'] as int,
    );
  }
}
