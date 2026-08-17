# Atlas — Auditoria de infraestrutura local — 2026-08-15

## Incidente auditado

O backend passou a alcançar `127.0.0.1:5432`, porém o PostgreSQL respondeu `password authentication failed for user "atlas"`.

## Causa raiz

O volume persistente `atlas_postgres_data` havia sido inicializado anteriormente com outra senha. A variável `POSTGRES_PASSWORD` da imagem oficial PostgreSQL só é utilizada durante a primeira inicialização de um diretório de dados vazio. Alterar o valor no `docker-compose.yml` não redefine a senha da role em um volume existente.

A correção anterior validava container saudável e porta TCP, mas isso não comprovava autenticação real do backend. Por isso a infraestrutura podia ser declarada pronta antes do SQLAlchemy tentar autenticar.

## Correções permanentes

1. `scripts/dev/start_local_infrastructure.ps1`
   - compara o contrato do banco no Compose com `backend/.env`;
   - inicia o serviço `db` sem remover o volume;
   - espera `pg_isready`;
   - executa `ALTER ROLE` de forma idempotente para reconciliar a senha da role no volume existente;
   - confirma que `5432` está publicada para o Windows;
   - executa autenticação real usando o Python/SQLAlchemy do próprio backend.

2. `backend/scripts/check_local_database_connection.py`
   - usa exatamente `get_settings().atlas_database_url`;
   - abre uma conexão real;
   - executa `SELECT current_database(), current_user`;
   - não imprime a senha.

3. `scripts/dev/start_backend.ps1`
   - passa obrigatoriamente pelo reconciliador de infraestrutura antes de iniciar Uvicorn;
   - elimina o fluxo manual em que o backend podia ser iniciado contra um banco ainda inconsistente.

4. `scripts/quality/atlas_local_infrastructure_contract.py`
   - bloqueia divergência entre Compose, backend local e backend Docker;
   - bloqueia remoção de `5432:5432`;
   - bloqueia remoção das proteções de reconciliação/autenticação;
   - bloqueia comandos destrutivos `docker compose down -v` nos scripts críticos.

5. `scripts/quality/run_full_quality_gate.ps1`
   - passa a executar o contrato estático e a reconciliação/autenticação real antes de Flutter, Alembic ou pytest.

## Regra operacional

O backend local deve ser iniciado por:

```powershell
cd "C:\Projetos\Projetos Atlas"
powershell -ExecutionPolicy Bypass -File .\scripts\dev\start_backend.ps1
```

O banco não deve ser corrigido apagando volumes. `docker compose down -v` permanece proibido como procedimento comum porque pode destruir os dados locais.

## Validações executadas neste pacote

- contrato estático de infraestrutura: OK;
- auditoria estrutural Atlas: OK;
- matriz Marco 4 tela/rota: OK;
- classificação Marco 4 persistência/rotas: OK;
- classificação de features avançadas: OK;
- fechamento funcional V1 Marco 4D: OK;
- sintaxe do novo script Python: OK.

A validação runtime Docker/PowerShell deve ser executada no Windows do projeto porque este ambiente de geração não possui Docker Desktop/PowerShell.
