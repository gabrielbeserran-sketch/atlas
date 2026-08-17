enum AtlasReleaseStatus { planned, validating, approved, deployed, rolledBack }

class AtlasReleaseCheck {
  const AtlasReleaseCheck({
    required this.id,
    required this.title,
    required this.completed,
  });
  final String id;
  final String title;
  final bool completed;
}

class AtlasReleasePlan {
  const AtlasReleasePlan({
    required this.version,
    required this.environment,
    required this.status,
    required this.checks,
  });
  final String version;
  final String environment;
  final AtlasReleaseStatus status;
  final List<AtlasReleaseCheck> checks;
  int get completedCount => checks.where((item) => item.completed).length;
  double get progress => checks.isEmpty ? 0 : completedCount / checks.length;
  bool get canDeploy =>
      checks.isNotEmpty &&
      completedCount == checks.length &&
      status != AtlasReleaseStatus.rolledBack;
  AtlasReleasePlan copyWith({
    AtlasReleaseStatus? status,
    List<AtlasReleaseCheck>? checks,
  }) => AtlasReleasePlan(
    version: version,
    environment: environment,
    status: status ?? this.status,
    checks: checks ?? this.checks,
  );
  factory AtlasReleasePlan.standard() => const AtlasReleasePlan(
    version: '1.0.0-rc.1',
    environment: 'staging',
    status: AtlasReleaseStatus.validating,
    checks: [
      AtlasReleaseCheck(
        id: 'flutter',
        title: 'Flutter analyze e testes',
        completed: true,
      ),
      AtlasReleaseCheck(
        id: 'backend',
        title: 'Gate completo do backend',
        completed: true,
      ),
      AtlasReleaseCheck(
        id: 'migrations',
        title: 'Migrations verificadas',
        completed: true,
      ),
      AtlasReleaseCheck(
        id: 'backup',
        title: 'Backup e rollback preparados',
        completed: true,
      ),
      AtlasReleaseCheck(
        id: 'approval',
        title: 'Aprovação humana registrada',
        completed: false,
      ),
    ],
  );
}
