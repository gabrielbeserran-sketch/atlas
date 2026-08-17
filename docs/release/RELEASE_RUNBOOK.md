# Runbook de release

1. Executar gate completo.
2. Criar backup e testar restauração.
3. Registrar versão, migrations e responsáveis.
4. Aprovação humana no ambiente staging.
5. Implantar gradualmente.
6. Validar healthcheck, OpenAPI, login, sync e métricas.
7. Manter artefato anterior disponível para rollback.
