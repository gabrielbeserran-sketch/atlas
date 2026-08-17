# Atlas — API pública HTTPS

Pré-requisitos externos: servidor Linux, domínio DNS, Docker e portas 80/443.

1. Copie `.env.example` para `.env`.
2. Troque todos os `CHANGE_ME`.
3. Execute `docker compose up -d --build`.
4. `migrate` aplica Alembic antes de liberar a API.
5. Caddy emite/renova TLS quando DNS e portas estão corretos.
6. Valide `https://SEU_DOMINIO/api/v1/health/ready`.

PostgreSQL, Redis e Uvicorn não expõem portas públicas.
