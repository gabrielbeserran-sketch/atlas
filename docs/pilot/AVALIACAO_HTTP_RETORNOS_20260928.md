# Contrato HTTP local dos retornos — 28/09/2026

Runner independente: `backend/scripts/test_reproduction_return_http.py`. Ele força `ATLAS_DATABASE_URL=sqlite:///:memory:` antes de importar a aplicação, cria cinco tabelas necessárias em banco temporário com StaticPool e nunca importa `app.main`, pytest/conftest nem usa `backend/atlas_test.db`. Os dados de teste são artificiais e só existem no processo.

Oito testes passaram via FastAPI/TestClient: GET com cabeçalho de contrato v1; PATCH do evento com autoria autenticada e conclusão da tarefa no mesmo commit; releitura em nova sessão; replay idêntico sem segunda evidência; cancelamento/motivo; baixa pela Agenda; reabertura/alteração da previsão e auditoria incompatível bloqueadas; previsão alterada antes da intenção offline e encerramento manual legado conflitante devolvem 409 sem gravar; empresa diferente devolve 404.

Dois desses testes usam JWT local, `get_principal` e `require_permission` reais, com User/Company/Membership/RefreshSession em memória: acesso válido funciona; `reproduction.write` removida devolve 403; sessão revogada ou expirada devolve 401; tenant divergente devolve 403. Os demais substituem o principal de teste para focalizar o contrato de rota. Não são testes da autenticação nem do servidor de produção.

Os 27 testes isolados anteriores foram reexecutados, 35 no total. Ruff F do novo runner, compileall e diff aprovados. Nenhuma mudança de código de produção foi necessária, portanto não houve nova compilação Flutter/Windows/Android nem instalação. O banco preexistente foi preservado com hash SHA-256 `7763CD50F8650291CBDCB7388904E14A3C4EA4FAC3F5FB498FC18B6631C6061A`.

Limites: SQLite não testa `FOR UPDATE`, migrações PostgreSQL, isolamento concorrente entre processos nem a rede/implantação real. Uma única verificação local de `docker info` retornou daemon indisponível; o ambiente não foi iniciado nem alterado. O próximo aceite exige PostgreSQL descartável funcional, cenários concorrentes, backend autorizado e dois dispositivos. Não confundir este teste HTTP local com deploy ou aceite ponta a ponta.

Checkpoint: `atlas-reproduction-return-http-local-20260928`.
