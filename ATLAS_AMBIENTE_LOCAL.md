# Atlas — Ambiente local confiável

## Regra permanente

O PostgreSQL local pode usar um volume Docker criado há várias versões do Atlas. Alterar `POSTGRES_PASSWORD` no Compose não altera automaticamente a senha gravada dentro desse volume. Por isso o Atlas não considera mais `healthy` ou porta aberta como prova suficiente de banco pronto.

O script oficial agora valida quatro coisas antes de liberar o backend:

1. contrato `docker-compose.yml` x `backend/.env`;
2. container PostgreSQL saudável;
3. senha real da role `atlas` reconciliada no volume existente;
4. autenticação real usando a mesma URL/SQLAlchemy do backend.

## Terminal 1 — infraestrutura

Abra o Docker Desktop. Depois execute:

```powershell
cd "C:\Projetos\Projetos Atlas"
powershell -ExecutionPolicy Bypass -File .\scripts\dev\start_local_infrastructure.ps1
```

O resultado correto termina com:

```text
ATLAS DATABASE CONNECTION: OK
PostgreSQL Atlas pronto e autenticado.
```

## Terminal 2 — backend (comando recomendado)

Não é mais necessário ativar a `.venv` e iniciar o Uvicorn manualmente. Use o inicializador oficial, que sempre valida/reconcilia o banco antes do backend:

```powershell
cd "C:\Projetos\Projetos Atlas"
powershell -ExecutionPolicy Bypass -File .\scripts\dev\start_backend.ps1
```

Esse terminal deve permanecer aberto enquanto o backend estiver em uso.

## Terminal 3 — Flutter

```powershell
cd "C:\Projetos\Projetos Atlas"
flutter devices
flutter run
```

## Quality Gate

```powershell
cd "C:\Projetos\Projetos Atlas"
powershell -ExecutionPolicy Bypass -File .\scripts\quality\run_full_quality_gate.ps1
```

O gate chama o mesmo reconciliador de infraestrutura antes de Alembic, portanto não depende de o usuário lembrar de preparar o banco manualmente.

## Contratos de conexão

- Backend executado no Windows: `localhost:5432` conforme `backend/.env`.
- Backend executado por Docker Compose: `db:5432` pelo override do `docker-compose.yml`.
- PostgreSQL local: usuário `atlas`, banco `atlas`, senha de desenvolvimento `atlas_local_change_me`.
- O volume `atlas_postgres_data` é preservado; a inicialização reconcilia a senha da role sem apagar dados.

## Regra de segurança operacional

Nunca use `docker compose down -v` como tentativa comum de corrigir autenticação, porque `-v` remove volumes e pode destruir o banco local. O reconciliador existe justamente para corrigir credenciais preservando os dados.
