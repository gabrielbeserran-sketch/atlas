# Atlas — Carga DEMO V5 — diagnóstico preventivo

## Erro atual corrigido

O `GET /livestock/nutrition` retornava HTTP 500 porque o
`NutritionEventResponse` ainda descrevia o contrato legado
`quantity_per_head`, mas o modelo real `NutritionEvent` usa:

- amount_per_animal
- animal_count
- planned_quantity
- observed_daily_gain_kg
- feed_conversion

A serialização da resposta falhava antes mesmo do script registrar consumo.

O endpoint legado de criação `/livestock/nutrition` também foi reconciliado.

## Próximos erros previstos e prevenção aplicada

1. **Financeiro duplicado em reexecução**
   - O backend já possui idempotência por `reference_type/reference_id`.
   - O script V5 também consulta antes do POST.

2. **Permissão insuficiente em Agenda**
   - Agenda exige `automation.read/manage`.
   - É tratada como módulo opcional no preflight e na carga.

3. **Tarefas indisponíveis**
   - Tratadas como opcionais para não interromper módulos pecuários.

4. **Render Free frio/lento**
   - Wake-up, retries e timeout 180 s continuam ativos.

5. **JSON com acentos no Windows PowerShell 5.1**
   - UTF-8 explícito continua ativo.

6. **Reexecução da carga**
   - Lotes, animais, estoque, nutrição, tarefas e finanças usam
     identificadores DEMO e verificações de existência.

## Mudança operacional

A V5 executa um preflight após o login. Se um módulo obrigatório estiver
quebrado, a carga para imediatamente antes de criar novos dados e informa
exatamente qual contrato precisa ser corrigido.
