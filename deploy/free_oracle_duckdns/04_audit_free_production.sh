#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-/opt/atlas}"
DEPLOY_DIR="${PROJECT_DIR}/deploy/free_oracle_duckdns"
ENV_FILE="${DEPLOY_DIR}/.env"

cd "${DEPLOY_DIR}"
set -a
source "${ENV_FILE}"
set +a

fail=0

check() {
  local title="$1"
  shift
  if "$@"; then
    printf "[OK]   %s\n" "${title}"
  else
    printf "[FAIL] %s\n" "${title}"
    fail=1
  fi
}

check "Docker ativo" systemctl is-active --quiet docker
check "DuckDNS timer ativo" systemctl is-active --quiet atlas-duckdns.timer
check "PostgreSQL saudável" bash -c 'docker compose ps --format json | jq -e "select(.Service==\"postgres\" and .Health==\"healthy\")" >/dev/null'
check "Redis saudável" bash -c 'docker compose ps --format json | jq -e "select(.Service==\"redis\" and .Health==\"healthy\")" >/dev/null'
check "API saudável" bash -c 'docker compose ps --format json | jq -e "select(.Service==\"api\" and .Health==\"healthy\")" >/dev/null'
check "Caddy em execução" bash -c 'docker compose ps --format json | jq -e "select(.Service==\"caddy\" and .State==\"running\")" >/dev/null'
check "API pública HTTPS" bash -c "curl -fsS --max-time 15 'https://${DUCKDNS_SUBDOMAIN}.duckdns.org/api/v1/health/ready' | jq -e '.status==\"ready\"' >/dev/null"

if [[ "${fail}" -ne 0 ]]; then
  echo "ATLAS FREE PRODUCTION AUDIT: FAIL"
  exit 1
fi

echo "ATLAS FREE PRODUCTION AUDIT: APROVADO"
