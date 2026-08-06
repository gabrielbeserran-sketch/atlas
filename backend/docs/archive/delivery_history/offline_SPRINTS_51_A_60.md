# Sprints 51 a 60 — Operação offline

Esta entrega estabelece o contrato oficial para banco local, fila de operações, push idempotente, pull incremental, conflitos, dispositivos, diagnósticos e confiabilidade em campo.

## Regras

1. Toda mutação offline recebe `operation_id` e `idempotency_key`.
2. Operações respeitam dependências: fazenda → lote → animal → evento.
3. O pull é paginado por cursor crescente e persiste `next_cursor` localmente.
4. Conflitos nunca são resolvidos silenciosamente.
5. Exclusões são lógicas.
6. Sessões offline respeitam validade e permissões armazenadas.
7. Dados sensíveis devem usar armazenamento seguro do sistema operacional.
8. Diagnósticos não devem transportar senhas, tokens ou dados clínicos completos.
