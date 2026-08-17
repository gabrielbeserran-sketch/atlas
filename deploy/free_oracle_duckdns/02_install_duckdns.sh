#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${1:-/opt/atlas}"
ENV_FILE="${PROJECT_DIR}/deploy/free_oracle_duckdns/.env"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Execute com sudo/root."
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Arquivo ausente: ${ENV_FILE}"
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

if [[ -z "${DUCKDNS_SUBDOMAIN:-}" || "${DUCKDNS_SUBDOMAIN}" == "CHANGE_ME" ]]; then
  echo "DUCKDNS_SUBDOMAIN inválido."
  exit 1
fi

if [[ -z "${DUCKDNS_TOKEN:-}" || "${DUCKDNS_TOKEN}" == "CHANGE_ME" ]]; then
  echo "DUCKDNS_TOKEN inválido."
  exit 1
fi

install -d -m 700 /etc/atlas

cat >/etc/atlas/duckdns.env <<EOF
DUCKDNS_SUBDOMAIN=${DUCKDNS_SUBDOMAIN}
DUCKDNS_TOKEN=${DUCKDNS_TOKEN}
EOF
chmod 600 /etc/atlas/duckdns.env

cat >/usr/local/bin/atlas-duckdns-update <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
source /etc/atlas/duckdns.env
response="$(curl -fsS "https://www.duckdns.org/update?domains=${DUCKDNS_SUBDOMAIN}&token=${DUCKDNS_TOKEN}&ip=")"
[[ "${response}" == "OK" ]] || { echo "DuckDNS respondeu: ${response}" >&2; exit 1; }
EOF
chmod 755 /usr/local/bin/atlas-duckdns-update

cat >/etc/systemd/system/atlas-duckdns.service <<'EOF'
[Unit]
Description=Atualiza o endereço Atlas no DuckDNS
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/atlas-duckdns-update
EOF

cat >/etc/systemd/system/atlas-duckdns.timer <<'EOF'
[Unit]
Description=Atualiza DuckDNS do Atlas

[Timer]
OnBootSec=30
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now atlas-duckdns.timer
/usr/local/bin/atlas-duckdns-update

echo "ATLAS DUCKDNS: APROVADO"
echo "https://${DUCKDNS_SUBDOMAIN}.duckdns.org"
