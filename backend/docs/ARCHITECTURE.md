# Arquitetura definitiva do Atlas

O backend é organizado por responsabilidades estáveis, não por números de sprint.

- `app/core`: configuração, autenticação, autorização, banco, middleware e infraestrutura transversal.
- `app/models`: destino gradual dos modelos separados por domínio.
- `app/repositories`: acesso persistente e consultas reutilizáveis.
- `app/services`: regras de negócio e orquestração.
- `app/routers`: contratos HTTP FastAPI.
- `app/schemas`: contratos de entrada e saída.
- `app/workers`: processamento assíncrono e tarefas agendadas.
- `tests`: testes ativos por domínio.
- `test_backups/legacy_sprint_phase_contracts`: testes históricos, fora da coleta do pytest.

As migrations mantêm seus nomes históricos porque fazem parte da cadeia imutável do banco.
