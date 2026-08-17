#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-/opt/atlas}"
DEPLOY_DIR="${PROJECT_DIR}/deploy/free_oracle_duckdns"
ENV_FILE="${DEPLOY_DIR}/.env"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Execute com sudo/root."
  exit 1
fi

[[ -f "${ENV_FILE}" ]] || { echo ".env ausente."; exit 1; }

set -a
source "${ENV_FILE}"
set +a

require_secret() {
  local name="$1"
  local min="$2"
  local value="${!name:-}"
  [[ -n "${value}" && "${value}" != CHANGE_ME* && "${#value}" -ge "${min}" ]] || {
    echo "Secret inválido/fraco: ${name}"
    exit 1
  }
}

[[ -n "${DUCKDNS_SUBDOMAIN:-}" && "${DUCKDNS_SUBDOMAIN}" != "CHANGE_ME" ]] || {
  echo "DUCKDNS_SUBDOMAIN inválido."
  exit 1
}

require_secret ATLAS_POSTGRES_PASSWORD 32
require_secret ATLAS_JWT_SECRET 64
require_secret ATLAS_MFA_ENCRYPTION_KEY 64
require_secret ATLAS_IOT_INGEST_KEY 64

cd "${DEPLOY_DIR}"

docker compose config >/tmp/atlas-compose-rendered.yml
docker compose pull postgres redis caddy
docker compose build api migrate backup-worker
docker compose up -d

for attempt in $(seq 1 60); do
  if docker compose ps --format json | jq -e 'select(.Service=="api" and .Health=="healthy")' >/dev/null 2>&1; then
    break
  fi

  if [[ "${attempt}" -eq 60 ]]; then
    docker compose logs --tail=200 api
    exit 1
  fi
  sleep 5
done

PUBLIC_URL="https://${DUCKDNS_SUBDOMAIN}.duckdns.org/api/v1/health/ready"

for attempt in $(seq 1 60); do
  if curl -fsS --max-time 10 "${PUBLIC_URL}" | jq -e '.status=="ready"' >/dev/null 2>&1; then
    echo "ATLAS FREE PRODUCTION: APROVADA"
    echo "${PUBLIC_URL}"
    exit 0
  fi

  if [[ "${attempt}" -eq 60 ]]; then
    docker compose logs --tail=200 caddy
    exit 1
  fi
  sleep 5
done
