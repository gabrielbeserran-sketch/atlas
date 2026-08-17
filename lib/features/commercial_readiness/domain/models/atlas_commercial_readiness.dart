class AtlasCommercialItem {
  const AtlasCommercialItem({
    required this.id,
    required this.title,
    required this.category,
    required this.completed,
  });
  final String id;
  final String title;
  final String category;
  final bool completed;
}

class AtlasCommercialReadiness {
  const AtlasCommercialReadiness({required this.items});
  final List<AtlasCommercialItem> items;
  int get completedCount => items.where((e) => e.completed).length;
  double get progress => items.isEmpty ? 0 : completedCount / items.length;
  bool get ready => items.isNotEmpty && completedCount == items.length;
  factory AtlasCommercialReadiness.standard() => const AtlasCommercialReadiness(
    items: [
      AtlasCommercialItem(
        id: 'onboarding',
        title: 'Roteiro de onboarding',
        category: 'Cliente',
        completed: true,
      ),
      AtlasCommercialItem(
        id: 'import',
        title: 'Modelo de importação',
        category: 'Dados',
        completed: true,
      ),
      AtlasCommercialItem(
        id: 'training',
        title: 'Treinamento inicial',
        category: 'Capacitação',
        completed: true,
      ),
      AtlasCommercialItem(
        id: 'docs',
        title: 'Documentação operacional',
        category: 'Suporte',
        completed: true,
      ),
      AtlasCommercialItem(
        id: 'demo',
        title: 'Roteiro de demonstração',
        category: 'Comercial',
        completed: true,
      ),
    ],
  );
}
