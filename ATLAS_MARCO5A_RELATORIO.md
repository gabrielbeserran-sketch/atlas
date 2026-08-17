# Projeto Atlas — Marco 5A: baseline protegida e inventário de produção

## Resultado

O Marco 4E aprovado passa a ser a referência protegida para o Marco 5. Quinze arquivos dos fluxos operacionais e testes de regressão foram congelados por SHA-256. Alterações neles exigem promoção explícita da baseline após novo Quality Gate completo.

## Prontidão já encontrada

- PostgreSQL obrigatório fora de desenvolvimento.
- JWT forte validado em ambiente production-like.
- auto-create schema proibido fora de development/test.
- CORS wildcard proibido em staging/production.
- força mínima de senha.
- login, refresh, logout, sessões, recuperação de senha e MFA existentes.
- headers de segurança e HSTS em production-like.
- backup PostgreSQL por `pg_dump` e retenção.

## Bloqueadores classificados

1. Produção deve recusar `ATLAS_BOOTSTRAP_ENABLED=true`.
2. Produção deve recusar documentação OpenAPI habilitada.
3. `ATLAS_PUBLIC_BASE_URL` precisa exigir HTTPS em production.
4. Chave IoT padrão/fraca precisa ser proibida.
5. Rate limit em memória não serve para múltiplas instâncias.
6. `X-Forwarded-For` precisa de política de proxies confiáveis.
7. Fotos permanecem em SharedPreferences.
8. Documentos permanecem em SharedPreferences.
9. Backup existe, mas restore ainda não está homologado.

A experiência Android de anexos continua corretamente diferida para o Marco 6.

## Sequência revisada

5B configuração/secrets/HTTPS/proxy; 5C autenticação/sessões/tenant; 5D anexos remotos; 5E transações/concorrência/idempotência; 5F rate limit/resiliência/observabilidade; 5G backup+restore; 5H gate estrito de produção; depois Marco 6 Android V1.
