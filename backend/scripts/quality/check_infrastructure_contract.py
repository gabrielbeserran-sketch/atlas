from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
required = [
    'docker-compose.local.yml',
    'docker-compose.staging.yml',
    'infrastructure/observability/prometheus/prometheus.yml',
    'infrastructure/observability/grafana/provisioning/datasources/datasource.yml',
    'infrastructure/production.env.example',
]
missing = [item for item in required if not (ROOT / item).exists()]
if missing:
    raise SystemExit(f'FALHA: arquivos de infraestrutura ausentes: {missing}')
print(f'OK: {len(required)} contratos de infraestrutura presentes.')
