# Projeto Atlas — Marco 5 concluído

## 5A — Baseline e inventário
Baseline protegida e inventário de produção automatizado.

## 5B — Configuração e segurança
Secrets fortes, HTTPS, CORS, proxy confiável, docs/bootstrap seguros.

## 5C — Identidade
Sessão vinculada ao JWT, revogação imediata, MFA criptografado e recuperação endurecida.

## 5D — Fotos e Documentos
Autoridade remota multi-dispositivo com metadados no PostgreSQL e arquivos persistentes.

## 5E — Transações, concorrência e idempotência
- Estoque usa row lock (`SELECT ... FOR UPDATE`).
- Operações com reference_type/reference_id usam advisory transaction lock.
- Repetição da mesma referência retorna o registro já confirmado sem nova baixa/lançamento.

## 5F — Rate limit e resiliência
- Redis compartilhado entre instâncias.
- Produção exige `ATLAS_REDIS_URL`.
- Falha do Redis em produção não vira fail-open de segurança.
- Request IDs, logs estruturados e métricas existentes permanecem ativos.

## 5G — Backup/restauração
- Backup completo `.atlasbackup`.
- Inclui banco + anexos.
- Manifesto SHA-256.
- Restore é provado em banco temporário e removido após validação.

## 5H — Gate final
O Marco 5 só fecha quando o inventário retorna `blocker_count = 0`.

## Débito conscientemente transferido
ATT-003 — seleção/abertura nativa Android de anexos pertence ao Marco 6.

## Próximo marco
Marco 6 — Android V1: configuração definitiva, package ID, ícone/splash, keystore,
build release/AAB, API pública HTTPS e homologação no celular/Google Play testing.


## Correção de homologação 5D
Os testes de anexos inicialmente assumiam a existência de um animal no banco
de teste. A fixture oficial recria o banco e não garante Fazenda/Lote/Animal.
Os testes foram tornados autossuficientes: cada cenário cria suas próprias
precondições pela API oficial antes de testar Fotos/Documentos.

O contrato 5D agora bloqueia regressão para `_first_animal()` ou outra
dependência implícita de dados previamente existentes.
