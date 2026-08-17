# Ciclo 2 — Rebanho integrado

O Ciclo 2 conecta a área **Rebanho** diretamente aos endpoints oficiais do backend.

## Sprint 136 — Lista de animais
- carregamento por fazenda ativa e por lote;
- busca por brinco, SISBOV, nome, raça e categoria;
- filtros por lote, situação e sexo;
- estados de carregamento, erro e vazio.

## Sprint 137 — Cadastro e edição
- criação de lote por `POST /api/v1/livestock/lots`;
- edição de lote por `PATCH /api/v1/livestock/lots/{lot_id}`;
- criação de animal por `POST /api/v1/livestock/animals`;
- edição de animal por `PATCH /api/v1/livestock/animals/{animal_id}`;
- exclusão autorizada pelo endpoint oficial.

## Sprint 138 — Detalhes e linha do tempo
A lista abre o `AnimalDetailScreen`, que mantém genealogia, documentos, fotos, sanidade, reprodução, linha do tempo e painéis especializados já existentes.

## Sprint 139 — Pesagens
O atalho de pesagens abre `AnimalWeightListScreen`, conectado a:
- `GET /api/v1/livestock/animals/{animal_id}/weights`;
- `POST /api/v1/livestock/animals/{animal_id}/weights`.

## Sprint 140 — Movimentações e lotes
O atalho de movimentações abre `AnimalMovementListScreen`, conectado a:
- `GET /api/v1/livestock/animals/{animal_id}/movements`;
- `POST /api/v1/livestock/animals/{animal_id}/movements`.

A troca de lote atualiza o cadastro oficial e preserva o histórico imutável.
