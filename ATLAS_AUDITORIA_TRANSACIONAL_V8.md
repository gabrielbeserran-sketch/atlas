# Atlas — V8 Auditoria Transacional Automatizada

A V8 transforma as proteções criadas na V7 em testes de roundtrip executáveis.

Cobertura adicionada:
- pesagem: criar → editar → excluir → recalcular estado do animal;
- lote: PATCH do animal → movimentação auditada;
- sanidade: criar → consumir estoque → gerar financeiro/tarefa → editar → reconciliar → excluir → estornar;
- nutrição: consumo → baixa → financeiro → exclusão → estorno;
- financeiro integrado: bloqueio de alteração/exclusão fora do módulo de origem;
- estoque: bloqueio de edição direta de saldo;
- agenda: criar → editar → cancelar → reler persistência;
- regressão Marco 2 atualizada para zerar estoque por movimentação antes de inativar produto.

A V8 não exige produção para validar o contrato: os testes usam o banco SQLite de testes definido em `backend/tests/conftest.py`.
