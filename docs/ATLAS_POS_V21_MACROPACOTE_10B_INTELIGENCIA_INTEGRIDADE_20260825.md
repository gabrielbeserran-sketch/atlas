# Atlas Pós-V21 — Macropacote 10B: Inteligência e Integridade do Produto

Data técnica: 2026-08-25.

## Objetivo

Consolidar a inteligência operacional em uma fonte canônica e transformar a antiga auditoria funcional em um gate transversal reproduzível. O 10B não cria um novo motor de decisão: Dashboard, Central de Alertas e Central da Consultoria continuam consumindo os endpoints oficiais de inteligência operacional.

## Correções funcionais

1. O backend passa a publicar `position` nas prioridades de `top_actions`. Clientes antigos continuam recebendo `priority` por compatibilidade.
2. O modelo Flutter aceita `position` e mantém fallback para `priority`, eliminando a perda silenciosa da posição das recomendações.
3. Resumo e alertas publicam `contract_version=10B`.
4. O serviço Flutter rejeita resposta com `farm_id` diferente da fazenda solicitada e também rejeita resumo/alertas com versões contratuais divergentes.
5. Foi criada uma readiness pública sem dados operacionais para comprovar o contrato do 10B em produção.

## Auditoria transversal

O gate `tools/atlas_post_v21_macro10b_integrity_gate.py` executa conjuntamente:

- sintaxe Python da árvore crítica;
- auditoria global já existente (`atlas_full_project_audit.py`);
- prova de fonte única para inteligência operacional;
- matriz dos módulos essenciais da V1;
- inventário de telas, serviços, autoridade remota e cache local;
- contagem dos routers e rotas backend;
- geração de matriz CSV e relatório JSON do 10B.

Caches locais detectados não são automaticamente tratados como defeito: quando não há autoridade remota evidente no mesmo diretório eles ficam registrados como dívida explícita para o 10C/10D, evitando tanto falsa aprovação quanto falso bloqueio.

## Banco

Nenhuma migration nova. A baseline permanece `0049`.

## Critério de saída

O macropacote só pode ser publicado se contratos 9C–9G, 10A e 10B passarem, a auditoria global existente continuar verde, o staging estiver contido pelo manifesto e o checker remoto confirmar `contract_version=10B`.
