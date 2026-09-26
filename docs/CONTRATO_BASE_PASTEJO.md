# Contrato de base de pastejo

Checkpoint de implementação: `9d744cb`. Validado localmente em SQLite; não representa confirmação de migração em produção.

## Rotas

Prefixo: `/api/v1/livestock/farms/{farm_id}/grazing-basis`.

- `GET /capabilities`: requer `nutrition.read` e fazenda autorizada. Só retorna `client_operation_id_idempotency: true` e `append_only: true` quando tabela e restrição de unicidade estão instaladas. O cliente não deve enviar sem essas confirmações.
- `GET`: requer `nutrition.read`; histórico mais recente primeiro, desempate por ID. `offset >= 0`, `limit` entre 1 e 500, padrão 100. Percorrer páginas sem tratar a primeira como histórico completo.
- `POST`: requer `nutrition.write`; cria retrato imutável. Campos: `client_operation_id` (8–180 caracteres), `effective_area_ha` (finita positiva), `grazing_animals` (inteiro positivo), `unique_area_confirmed: true`, `recorded_at` com timezone. Data futura além de um minuto é recusada. Área conhecida da fazenda limita novas gravações.

O servidor determina tenant, empresa, fazenda e autor a partir da autenticação e da rota; esses campos não são aceitos no corpo. Resposta inclui identificação, dados e datas UTC. Permissões e escopo são verificados também nas repetições.

## Conciliação prevista para o cliente

1. Salvar localmente antes da rede, mantendo o mesmo identificador da operação.
2. Consultar capacidade; 404, 503 ou falha de rede não autorizam reenvio.
3. Repetição idêntica retorna o registro original com 201, sem nova linha. Mesma chave com dados ou fazenda diferentes retorna 409. A chave é única por empresa.
4. Manter ambas as versões em caso de conflito; não alterar o identificador para forçar gravação nem apagar a versão local automaticamente.
5. Carregar histórico remoto por páginas, verificar o escopo e conciliar por identificador. Não associar registros por nome de fazenda.

Sem a migração, GET/POST retornam 503. Não há rota de edição/exclusão de retratos: correção exige uma nova confirmação, preservando auditoria.

## Limites da entrega

API e migração implementadas; o aplicativo ainda não chama estas rotas. Homologação PostgreSQL, confirmação autenticada em produção e ensaio em dois dispositivos permanecem pendentes. Nenhuma credencial nem banco existente foi utilizado nos testes.
