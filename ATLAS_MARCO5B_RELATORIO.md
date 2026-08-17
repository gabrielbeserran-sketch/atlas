# Projeto Atlas — Marco 5B

## Objetivo
Endurecer configuração de produção, secrets, HTTPS/CORS, superfície de
documentação e confiança de reverse proxy antes de avançar para autenticação
e isolamento.

## Bloqueadores resolvidos
- SEC-003 — bootstrap proibido em staging/production.
- SEC-004 — docs/OpenAPI proibidos em production.
- SEC-005 — URL pública HTTPS obrigatória; host local proibido em production.
- SEC-006 — chave IoT forte e não padrão obrigatória.
- NET-003 — X-Forwarded-For só é aceito de peer em CIDR explicitamente confiável.

## Proteções adicionais
- CORS de staging/production exige HTTPS e sem wildcard.
- Produção não autoriza localhost/loopback em CORS.
- Chave IoT comparada com `hmac.compare_digest`.
- Root não anuncia `/docs` quando documentação está desligada.
- Produção não expõe o nome do ambiente no root.
- `.env.production.example` seguro por padrão e com CHANGE_ME deliberadamente
  rejeitado pelos validadores.
- Testes negativos garantem que configuração insegura não inicia.

## Bloqueadores restantes após 5B
- NET-002 — rate limit compartilhado/distribuído.
- ATT-001/ATT-002 — Fotos e Documentos ainda têm autoridade local.
- BKP-002 — restore ainda não homologado.
- ATT-003 permanece corretamente adiado para Marco 6/Android.

## Próximo marco
5C — autenticação, sessões, MFA, recuperação e isolamento tenant/empresa/fazenda.
