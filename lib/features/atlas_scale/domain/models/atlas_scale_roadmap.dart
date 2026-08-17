class AtlasScalePillar {
  const AtlasScalePillar({
    required this.title,
    required this.score,
    required this.target,
  });
  final String title;
  final int score;
  final int target;
  double get progress =>
      target <= 0 ? 0 : (score / target).clamp(0, 1).toDouble();
}

class AtlasScaleRoadmap {
  const AtlasScaleRoadmap({required this.pillars, required this.horizonYears});

  factory AtlasScaleRoadmap.standard() => const AtlasScaleRoadmap(
    horizonYears: 5,
    pillars: [
      AtlasScalePillar(title: 'Arquitetura modular', score: 75, target: 100),
      AtlasScalePillar(title: 'Escala multi-tenant', score: 70, target: 100),
      AtlasScalePillar(title: 'Expansão de mercado', score: 45, target: 100),
      AtlasScalePillar(
        title: 'Ecossistema de parceiros',
        score: 35,
        target: 100,
      ),
      AtlasScalePillar(title: 'Governança de produto', score: 65, target: 100),
    ],
  );

  final List<AtlasScalePillar> pillars;
  final int horizonYears;
  double get progress => pillars.isEmpty
      ? 0
      : pillars.map((item) => item.progress).reduce((a, b) => a + b) /
            pillars.length;
}
