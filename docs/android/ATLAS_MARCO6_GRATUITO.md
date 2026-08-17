# Projeto Atlas — Marco 6 gratuito

Arquitetura alvo de custo mensal R$ 0:

Android → HTTPS → DuckDNS gratuito → Oracle Cloud Always Free → Caddy → FastAPI → PostgreSQL/Redis.

Passos:
1. Criar conta Oracle Cloud Free Tier.
2. Criar VM Always Free com Ubuntu 24.04.
3. Criar subdomínio em DuckDNS.
4. Copiar projeto para `/opt/atlas`.
5. Executar:
   `sudo bash deploy/free_oracle_duckdns/01_prepare_oracle_free_server.sh`
6. Copiar `.env.example` para `.env`, gerar secrets com `python3 generate_secrets.py` e preencher DuckDNS.
7. Executar:
   `sudo bash deploy/free_oracle_duckdns/02_install_duckdns.sh`
8. Executar:
   `sudo bash deploy/free_oracle_duckdns/03_deploy_atlas_free.sh`
9. Auditar:
   `sudo bash deploy/free_oracle_duckdns/04_audit_free_production.sh`
10. No Windows:
   `powershell -ExecutionPolicy Bypass -File .\scripts\android\17_marco6_free_gate.ps1 -DuckDnsSubdomain "SEU_SUBDOMINIO"`

Não é necessário comprar domínio nem contratar VPS.
