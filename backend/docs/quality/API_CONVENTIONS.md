# Convenções oficiais da API Atlas

- `GET`: leitura, sem alteração de estado.
- `POST`: criação ou comando explícito.
- `PUT`: substituição idempotente.
- `PATCH`: alteração parcial.
- `DELETE`: exclusão lógica; `204` deve usar `Response` e não ter corpo.
- erros de validação: `422`.
- autenticação ausente ou inválida: `401`.
- permissão insuficiente: `403`.
- entidade inexistente no escopo: `404`.
- conflito de versão ou estado: `409`.
- paginação: `limit`, `offset` e total quando aplicável.
- toda requisição recebe `X-Request-ID`.
