# Correção de tabelas SQLAlchemy duplicadas

Esta entrega corrige declarações duplicadas na mesma `MetaData`:

- `workflow_definitions` e `workflow_instances` permanecem como tabelas oficiais do motor de automação existente.
- O módulo Enterprise Operations passa a usar `enterprise_workflow_definitions` e `enterprise_workflow_instances`.
- `privacy_requests` permanece como tabela oficial do módulo de privacidade existente.
- O módulo Security & Compliance passa a usar `compliance_privacy_requests`.

As migrations 0032 e 0035 foram atualizadas de forma coerente. A cadeia mantém 36 revisões e head único `20260806_0036`.
