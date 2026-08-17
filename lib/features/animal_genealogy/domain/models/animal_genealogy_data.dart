class AnimalGenealogyNodeData {
  const AnimalGenealogyNodeData({
    required this.id,
    required this.farmId,
    required this.groupName,
    required this.tag,
    required this.name,
    required this.sex,
    required this.breed,
    required this.category,
    required this.birthDate,
    required this.status,
    required this.relation,
    required this.registered,
  });

  final String id;
  final String farmId;
  final String groupName;
  final String tag;
  final String name;
  final String sex;
  final String breed;
  final String category;
  final String birthDate;
  final String status;
  final String relation;
  final bool registered;

  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    return registered ? 'Animal $tag' : 'Brinco $tag';
  }

  factory AnimalGenealogyNodeData.fromMap(Map<String, dynamic> map) {
    return AnimalGenealogyNodeData(
      id: map['id']?.toString() ?? '',
      farmId: map['farm_id']?.toString() ?? '',
      groupName: map['group_name']?.toString() ?? '',
      tag: map['tag']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      sex: map['sex']?.toString() ?? '',
      breed: map['breed']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      birthDate: map['birth_date']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      relation: map['relation']?.toString() ?? '',
      registered: map['registered'] == true,
    );
  }
}

class AnimalGenealogyData {
  const AnimalGenealogyData({
    required this.animal,
    required this.father,
    required this.mother,
    required this.paternalGrandfather,
    required this.paternalGrandmother,
    required this.maternalGrandfather,
    required this.maternalGrandmother,
    required this.siblings,
    required this.halfSiblings,
    required this.children,
    required this.descendants,
    required this.unresolvedTags,
  });

  final AnimalGenealogyNodeData animal;
  final AnimalGenealogyNodeData? father;
  final AnimalGenealogyNodeData? mother;
  final AnimalGenealogyNodeData? paternalGrandfather;
  final AnimalGenealogyNodeData? paternalGrandmother;
  final AnimalGenealogyNodeData? maternalGrandfather;
  final AnimalGenealogyNodeData? maternalGrandmother;
  final List<AnimalGenealogyNodeData> siblings;
  final List<AnimalGenealogyNodeData> halfSiblings;
  final List<AnimalGenealogyNodeData> children;
  final List<AnimalGenealogyNodeData> descendants;
  final List<String> unresolvedTags;

  int get registeredAncestors => [
    father,
    mother,
    paternalGrandfather,
    paternalGrandmother,
    maternalGrandfather,
    maternalGrandmother,
  ].where((item) => item?.registered == true).length;

  int get familyCount =>
      registeredAncestors +
      siblings.length +
      halfSiblings.length +
      descendants.length;

  factory AnimalGenealogyData.fromMap(Map<String, dynamic> map) {
    AnimalGenealogyNodeData? optionalNode(String key) {
      final value = map[key];
      if (value is! Map) return null;
      return AnimalGenealogyNodeData.fromMap(Map<String, dynamic>.from(value));
    }

    List<AnimalGenealogyNodeData> nodes(String key) {
      final value = map[key];
      if (value is! List) {
        return const <AnimalGenealogyNodeData>[];
      }

      return value
          .whereType<Map>()
          .map(
            (item) => AnimalGenealogyNodeData.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false);
    }

    return AnimalGenealogyData(
      animal: AnimalGenealogyNodeData.fromMap(
        Map<String, dynamic>.from(map['animal'] as Map),
      ),
      father: optionalNode('father'),
      mother: optionalNode('mother'),
      paternalGrandfather: optionalNode('paternal_grandfather'),
      paternalGrandmother: optionalNode('paternal_grandmother'),
      maternalGrandfather: optionalNode('maternal_grandfather'),
      maternalGrandmother: optionalNode('maternal_grandmother'),
      siblings: nodes('siblings'),
      halfSiblings: nodes('half_siblings'),
      children: nodes('children'),
      descendants: nodes('descendants'),
      unresolvedTags: (map['unresolved_tags'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }
}
