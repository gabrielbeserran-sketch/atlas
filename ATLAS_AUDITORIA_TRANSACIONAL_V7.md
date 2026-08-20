# Atlas — Auditoria Transacional e Integridade V7

## Escopo auditado

A V7 foi realizada diretamente sobre o projeto enviado pelo usuário, após a homologação visual da V6. O foco desta rodada é integridade de mutações e efeitos cruzados: editar, mover, excluir/reverter e impedir que módulos dependentes fiquem divergentes.

## Problemas encontrados e corrigidos

### 1. Pesagens sem CRUD transacional completo
O backend permitia criar e listar pesagens, mas não editar ou excluir. Isso impedia corrigir uma pesagem incorreta sem deixar o peso atual do animal inconsistente.

**Correção:** adicionados PATCH e DELETE de pesagem e recálculo automático de `current_weight` e `body_condition_score` a partir da última pesagem restante.

### 2. Alteração direta de lote não gerava histórico
`PATCH /animals/{id}` podia mudar `lot_id` sem registrar `AnimalMovement`.

**Correção:** mudança de lote por edição cadastral agora gera movimentação automática, preservando a Timeline e a rastreabilidade.

### 3. Edição sanitária não reconciliava Estoque e Financeiro
O cadastro de evento sanitário baixava estoque e gerava despesa, mas a edição podia mudar produto, quantidade ou custo sem estornar o efeito anterior.

**Correção:** o PATCH sanitário agora recompõe o estoque anterior, aplica a nova baixa, recalcula custo quando necessário e recria o lançamento financeiro integrado de forma coerente. Repetidas edições calculam o saldo líquido por produto.

### 4. Exclusão sanitária podia estornar somente uma movimentação
Em históricos com ajustes, o DELETE considerava apenas uma movimentação original.

**Correção:** o estorno passa a calcular consumo e devoluções acumuladas por produto e devolve apenas o saldo ainda consumido.

### 5. Consumo nutricional não tinha reversão integrada
A exclusão de um consumo nutricional não possuía fluxo oficial para devolver estoque e remover a despesa automática.

**Correção:** novo `DELETE /livestock/nutrition/events/{event_id}` estorna a baixa de estoque, remove lançamentos financeiros vinculados e então exclui o evento.

### 6. Financeiro permitia alterar/excluir lançamentos gerados por outros módulos
Uma despesa de Sanidade ou Nutrição poderia ser editada diretamente no Financeiro, quebrando a fonte de verdade.

**Correção:** lançamentos com `reference_type=health_event` ou `nutrition_event` são protegidos. A alteração/exclusão deve ser feita no módulo de origem.

### 7. Estoque permitia alteração direta de quantidade
O PATCH de produto aceitava `quantity`, o que permitiria mudar saldo sem criar movimentação de estoque.

**Correção:** quantidade não pode mais ser modificada pela edição do produto. Alterações de saldo devem passar por movimentações. Produto com saldo positivo também não pode ser inativado.

### 8. Mutações entre fazendas
Produto, plano nutricional e lançamento financeiro podiam receber payload apontando para fazenda diferente do registro existente.

**Correção:** a fazenda desses registros tornou-se imutável na edição e referências de lote/animal são validadas contra a fazenda original.

### 9. Exclusão visual da Agenda sem confirmação de persistência
A Agenda enviava `cancelled` ao servidor e removia o item local imediatamente.

**Correção:** depois do PATCH, a Agenda relê o servidor e só confirma a exclusão visual quando o estado remoto `cancelled` foi realmente persistido.

## Riscos previstos para as próximas fases

1. **Duplo clique / dupla submissão:** endpoints integrados devem continuar usando referência/idempotência e bloqueios transacionais.
2. **Concorrência de estoque:** operações de consumo devem sempre obter o produto com lock antes de atualizar quantidade.
3. **Financeiro órfão:** novas integrações futuras devem adotar `reference_type/reference_id` e reversão pela fonte.
4. **Exclusão de animal:** continua sendo exclusão lógica (`Excluído`), adequada para preservar histórico; deve permanecer assim.
5. **Movimentações de animal:** movimentações já consolidadas não devem ser apagadas; correções futuras devem preferir movimentação compensatória.
6. **Agenda integrada:** tarefas provenientes de Sanidade/Reprodução devem continuar alterando a data no evento de origem quando o vencimento é editado.

## Validações executadas

- `python -m py_compile` nos arquivos Python alterados.
- Auditoria estática V7: 16/16 verificações aprovadas.
- Verificação de contratos de pesagem, reconciliação sanitária, reversão nutricional, proteção financeira, proteção de estoque e persistência da Agenda.

## Próxima fase recomendada

Após publicação da V7: smoke test curto em produção e, se aprovado, seguir para endurecimento Android/offline, tratamento de dupla submissão no Flutter e preparação de build de produção.
