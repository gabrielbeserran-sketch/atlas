class AtlasReadinessCheck {
  const AtlasReadinessCheck({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.detail,
  });

  final String id;
  final String title;
  final String category;
  final AtlasReadinessStatus status;
  final String detail;

  bool get approved => status == AtlasReadinessStatus.approved;
}

enum AtlasReadinessStatus { approved, warning, blocked }

class AtlasOperationalReadinessReport {
  const AtlasOperationalReadinessReport({required this.checks});

  final List<AtlasReadinessCheck> checks;

  int get approvedCount => checks.where((item) => item.approved).length;
  int get warningCount => checks
      .where((item) => item.status == AtlasReadinessStatus.warning)
      .length;
  int get blockedCount => checks
      .where((item) => item.status == AtlasReadinessStatus.blocked)
      .length;
  double get progress => checks.isEmpty ? 0 : approvedCount / checks.length;
  bool get readyForProduction =>
      blockedCount == 0 && warningCount == 0 && checks.isNotEmpty;

  factory AtlasOperationalReadinessReport.standard() =>
      const AtlasOperationalReadinessReport(
        checks: [
          AtlasReadinessCheck(
            id: 'backend-tests',
            title: 'Testes do backend',
            category: 'Qualidade',
            status: AtlasReadinessStatus.approved,
            detail: 'Gate com pytest, contratos, migrations e OpenAPI.',
          ),
          AtlasReadinessCheck(
            id: 'api-budget',
            title: 'Orçamento da API',
            category: 'Desempenho',
            status: AtlasReadinessStatus.approved,
            detail: 'Limites de payload, timeout e concorrência documentados.',
          ),
          AtlasReadinessCheck(
            id: 'database',
            title: 'PostgreSQL',
            category: 'Infraestrutura',
            status: AtlasReadinessStatus.approved,
            detail: 'Banco principal com healthcheck e migrations.',
          ),
          AtlasReadinessCheck(
            id: 'workers',
            title: 'Workers e Redis',
            category: 'Infraestrutura',
            status: AtlasReadinessStatus.approved,
            detail: 'Filas isoladas e observáveis.',
          ),
          AtlasReadinessCheck(
            id: 'storage',
            title: 'Armazenamento de arquivos',
            category: 'Infraestrutura',
            status: AtlasReadinessStatus.approved,
            detail: 'Object storage compatível com S3.',
          ),
          AtlasReadinessCheck(
            id: 'observability',
            title: 'Observabilidade',
            category: 'Desempenho',
            status: AtlasReadinessStatus.approved,
            detail: 'Métricas, logs estruturados e dashboards.',
          ),
        ],
      );
}
