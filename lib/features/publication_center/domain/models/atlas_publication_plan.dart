class AtlasPublicationCheck {
  const AtlasPublicationCheck({
    required this.name,
    required this.completed,
    required this.channel,
  });

  final String name;
  final bool completed;
  final String channel;
}

class AtlasPublicationPlan {
  const AtlasPublicationPlan({required this.checks});

  factory AtlasPublicationPlan.standard() => const AtlasPublicationPlan(
    checks: [
      AtlasPublicationCheck(
        name: 'Assinatura Android configurada',
        completed: false,
        channel: 'Android',
      ),
      AtlasPublicationCheck(
        name: 'Bundle AAB validado',
        completed: false,
        channel: 'Android',
      ),
      AtlasPublicationCheck(
        name: 'Certificados iOS configurados',
        completed: false,
        channel: 'iOS',
      ),
      AtlasPublicationCheck(
        name: 'Build web otimizado',
        completed: false,
        channel: 'Web',
      ),
      AtlasPublicationCheck(
        name: 'Política de privacidade publicada',
        completed: false,
        channel: 'Legal',
      ),
      AtlasPublicationCheck(
        name: 'Termos de uso publicados',
        completed: false,
        channel: 'Legal',
      ),
      AtlasPublicationCheck(
        name: 'Canal de suporte de produção ativo',
        completed: false,
        channel: 'Suporte',
      ),
    ],
  );

  final List<AtlasPublicationCheck> checks;

  int get completedCount => checks.where((item) => item.completed).length;
  double get progress => checks.isEmpty ? 0 : completedCount / checks.length;
  bool get ready => checks.isNotEmpty && completedCount == checks.length;
}
